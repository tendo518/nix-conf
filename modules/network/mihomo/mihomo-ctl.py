"""Mihomo core operations, with CLI and tray adapters in one file.

The core uses only the standard library: it returns data or raises MihomoError,
without prompting, rendering, escalating privileges, or starting an event loop.
create_cli() and run_tray() own those UI concerns and load their dependencies lazily.

Linux/systemd deployment settings are supplied as JSON:
    mihomo-ctl --settings /path/to/settings.json status
Priority: --settings > MIHOMO_CTL_SETTINGS > packaged default > Settings defaults.
Relative paths resolve against the settings file. Executables use PATH unless
overridden through commands. Subscription initialization requires template_path;
the template substitutes $URL and $MODE. Legacy cleanup rules are opt-in.
Other frontends can construct MihomoCore(Settings(...)) without loading a file.
"""

from collections.abc import Iterator, Mapping
from contextlib import ExitStack, closing
from dataclasses import dataclass, field, fields
import json
import math
import os
import pwd
import grp
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from types import MappingProxyType
from typing import Annotated

MODES = ("rule", "global", "direct", "script")

# Optional deployment default; the core never reads this value.
DEFAULT_SETTINGS_PATH = None


# Core results shared by the frontends.


class MihomoError(RuntimeError):
    """An operation failed; frontends decide how to present the failure."""


@dataclass(frozen=True)
class ProxySelection:
    selected: str
    nodes: tuple[str, ...]


@dataclass(frozen=True)
class MihomoStatus:
    daemon_active: bool
    routing_active: bool
    mode: str | None = None
    proxy: ProxySelection | None = None
    provider_count: int = 0
    error: str | None = None


@dataclass(frozen=True)
class DoctorReport:
    checks: tuple[tuple[str, bool], ...]
    notes: tuple[str, ...]

    @property
    def failures(self) -> int:
        return sum(not passed for _, passed in self.checks)


@dataclass(frozen=True)
class ProviderHealth:
    providers: tuple[str, ...]
    # Delay in milliseconds, alive, node name; sorted by delay.
    results: tuple[tuple[int, bool, str], ...]


@dataclass(frozen=True)
class RouteSection:
    title: str
    output: str
    available: bool


@dataclass(frozen=True)
class ConfigMetadata:
    path: Path
    owner: str | None = None
    group: str | None = None
    permissions: int | None = None


@dataclass(frozen=True)
class Connection:
    protocol: str
    source: str
    destination: str
    process: str
    rule: str
    proxy: str
    download: int | float | None
    upload: int | float | None


@dataclass(frozen=True)
class ConnectionSnapshot:
    connections: tuple[Connection, ...]
    count: int
    download_total: int | float | None
    upload_total: int | float | None


@dataclass(frozen=True)
class LogRecord:
    timestamp: float | None
    priority: str
    source: str
    message: str


@dataclass(frozen=True)
class Settings:
    """Deployment settings; relative file paths are resolved by load_settings()."""

    config_path: Path = Path("/etc/mihomo/config.yaml")
    state_dir: Path = Path("/var/lib/mihomo")
    routing_state_file: Path = Path("/run/mihomo-routing/rules")
    template_path: Path | None = None
    controller_url: str = "http://127.0.0.1:9090"
    request_timeout: float = 5.0
    proxy_group: str = "PROXY"
    default_provider: str = "subscription"
    service_unit: str = "mihomo.service"
    routing_unit: str = "mihomo-routing.service"
    service_user: str = "mihomo"
    service_group: str = "mihomo"
    routing_table: int = 2023
    tun_device: str = "mihomo"
    tun_wait_timeout: float = 30.0
    # Migration cleanup is opt-in: a generic installation owns no legacy rules.
    legacy_rule_patterns: tuple[str, ...] = ()
    legacy_route_tables: tuple[int, ...] = ()
    legacy_tun_devices: tuple[str, ...] = ()
    preceding_rule_pattern: str | None = None
    commands: Mapping[str, str] = field(default_factory=dict)

    def __post_init__(self) -> None:
        for name in ("config_path", "state_dir", "routing_state_file", "template_path"):
            value = getattr(self, name)
            if name == "template_path" and value is None:
                continue
            if not isinstance(value, Path) or not value.is_absolute():
                raise MihomoError(f"{name} must be an absolute path")
        for name in (
            "controller_url", "proxy_group", "default_provider", "service_unit",
            "routing_unit", "service_user", "service_group", "tun_device",
        ):
            value = getattr(self, name)
            if not isinstance(value, str) or not value.strip():
                raise MihomoError(f"{name} must be a non-empty string")
        try:
            url = urllib.parse.urlsplit(self.controller_url)
            port = url.port
        except ValueError as error:
            raise MihomoError(f"Invalid controller_url: {error}") from error
        if url.scheme not in {"http", "https"} or not url.netloc or url.query or url.fragment:
            raise MihomoError("controller_url must be an HTTP(S) base URL")
        if not url.hostname or port == 0:
            raise MihomoError("controller_url must include a valid host and port")
        object.__setattr__(self, "controller_url", self.controller_url.rstrip("/"))
        for name in ("request_timeout", "tun_wait_timeout"):
            value = getattr(self, name)
            if type(value) not in (int, float) or not math.isfinite(value) or value <= 0:
                raise MihomoError(f"{name} must be a positive finite number")
        for name in ("legacy_rule_patterns", "legacy_route_tables", "legacy_tun_devices"):
            if not isinstance(getattr(self, name), tuple):
                raise MihomoError(f"{name} must be a list")
        for table in (self.routing_table, *self.legacy_route_tables):
            if type(table) is not int or not 1 <= table <= 0xFFFFFFFF or table in (253, 254, 255):
                raise MihomoError("Routing tables must be positive non-reserved table IDs")
        if self.routing_table in self.legacy_route_tables:
            raise MihomoError("routing_table must not be a legacy route table")
        for device in self.legacy_tun_devices:
            if not isinstance(device, str) or not device:
                raise MihomoError("legacy_tun_devices must contain non-empty strings")
        patterns = self.legacy_rule_patterns
        if self.preceding_rule_pattern is not None:
            patterns = (*patterns, self.preceding_rule_pattern)
        for pattern in patterns:
            if not isinstance(pattern, str) or not pattern:
                raise MihomoError("Rule patterns must be non-empty strings")
            try:
                re.compile(pattern)
            except re.error as error:
                raise MihomoError(f"Invalid rule pattern: {pattern}: {error}") from error
        command_names = {"ip", "ss", "systemctl", "journalctl", "systemd-creds", "mihomo", "sudo", "pkexec"}
        if not isinstance(self.commands, Mapping) or self.commands.keys() - command_names:
            raise MihomoError(f"commands may only override: {', '.join(sorted(command_names))}")
        if any(not isinstance(value, str) or not value for value in self.commands.values()):
            raise MihomoError("commands must map tool names to executable names or paths")
        object.__setattr__(self, "commands", MappingProxyType(dict(self.commands)))

    @property
    def config_dir(self) -> Path:
        return self.config_path.parent

    @property
    def subscriptions_dir(self) -> Path:
        return self.state_dir / "subscriptions"

    @property
    def active_subscription_path(self) -> Path:
        return self.state_dir / "active-subscription"

    @property
    def mode_state_file(self) -> Path:
        return self.state_dir / "mode"

    def executable(self, name: str) -> str:
        return self.commands.get(name, name)


def load_settings(path: Path | None = None) -> Settings:
    """Read an explicit JSON settings file, overlaying portable defaults."""
    if path is None:
        return Settings()
    path = path.expanduser().resolve()
    try:
        data = json.loads(path.read_text())
    except (OSError, ValueError) as error:
        raise MihomoError(f"Could not read settings: {path}: {error}") from error
    if not isinstance(data, dict):
        raise MihomoError("Settings must be a JSON object")
    unknown = data.keys() - {item.name for item in fields(Settings)}
    if unknown:
        raise MihomoError(f"Unknown settings: {', '.join(sorted(unknown))}")
    for name in ("config_path", "state_dir", "routing_state_file", "template_path"):
        if name not in data or (name == "template_path" and data[name] is None):
            continue
        if not isinstance(data[name], str) or not data[name]:
            raise MihomoError(f"{name} must be a non-empty path")
        value = Path(data[name]).expanduser()
        data[name] = (path.parent / value).resolve() if not value.is_absolute() else value
    for name in ("legacy_rule_patterns", "legacy_route_tables", "legacy_tun_devices"):
        if name in data:
            if not isinstance(data[name], list):
                raise MihomoError(f"{name} must be a list")
            data[name] = tuple(data[name])
    if isinstance(data.get("commands"), dict):
        data["commands"] = {
            name: str((path.parent / value).resolve())
            if isinstance(value, str) and "/" in value and not Path(value).is_absolute()
            else value
            for name, value in data["commands"].items()
        }
    return Settings(**data)


def configured_arguments(args: list[str], settings_path: Path | None) -> list[str]:
    """Carry the selected settings file across sudo/polkit's environment reset."""
    args = list(args)
    while args:
        if args[0] == "--settings":
            args = args[2:]
        elif args[0].startswith("--settings="):
            args = args[1:]
        else:
            break
    return (["--settings", str(settings_path)] if settings_path else []) + args


def require_root() -> None:
    if os.geteuid() != 0:
        raise MihomoError("Root privileges are required for this operation")


def as_dict(value: object) -> dict:
    """Mihomo encodes empty Go maps as null; treat those as empty."""
    return value if isinstance(value, dict) else {}


def as_list(value: object) -> list:
    """Mihomo encodes empty Go slices as null; treat those as empty."""
    return value if isinstance(value, list) else []


def atomic_write_text(path: Path, text: str, *, mode: int, group: int = 0) -> None:
    """Replace a root-owned file only after its contents and permissions are set."""
    fd, temporary = tempfile.mkstemp(prefix=f"{path.name}.", dir=path.parent)
    temporary_path = Path(temporary)
    try:
        with os.fdopen(fd, "w") as output:
            output.write(text)
        os.chown(temporary_path, 0, group)
        os.chmod(temporary_path, mode)
        os.replace(temporary_path, path)
    finally:
        temporary_path.unlink(missing_ok=True)


def validate_subscription_url(url: str) -> None:
    if not re.match(r"^https?://", url):
        raise MihomoError("Subscription URL must start with http:// or https://")
    if any(character.isspace() for character in url):
        raise MihomoError("Subscription URL must not contain whitespace")


def validate_subscription_name(name: str) -> None:
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,63}", name):
        raise MihomoError(
            "Subscription name must use only letters, digits, dot, underscore, "
            "or hyphen (maximum 64 characters)"
        )


class MihomoCore:
    """Operations bound to one deployment, independent of environment and frontends."""

    def __init__(self, settings: Settings):
        self.settings = settings

    def command(
        self,
        *args: str, check: bool = True, capture: bool = True
    ) -> subprocess.CompletedProcess[str]:
        try:
            return subprocess.run(
                [self.settings.executable(args[0]), *args[1:]],
                check=check,
                text=True,
                capture_output=capture,
            )
        except FileNotFoundError as error:
            raise MihomoError(f"Command not found: {args[0]}") from error
        except subprocess.CalledProcessError as error:
            detail = (error.stderr or error.stdout or "").strip()
            suffix = f": {detail}" if detail else ""
            raise MihomoError(
                f"Command failed ({error.returncode}): {' '.join(args)}{suffix}"
            ) from error

    def command_output(self, *args: str, check: bool = True) -> str:
        return self.command(*args, check=check, capture=True).stdout

    def require_config(self) -> None:
        if not self.settings.config_path.is_file() or self.settings.config_path.stat().st_size == 0:
            raise MihomoError(
                f"Mihomo config is missing: {self.settings.config_path}\n"
                "Run: sudo mihomo-ctl subscription init"
            )

    def api(self, path: str, method: str = "GET", payload: dict | None = None) -> object:
        data = None
        headers = {}
        if payload is not None:
            data = json.dumps(payload).encode()
            headers["Content-Type"] = "application/json"
        request = urllib.request.Request(
            f"{self.settings.controller_url}{path}", data=data, headers=headers, method=method
        )
        try:
            with urllib.request.urlopen(request, timeout=self.settings.request_timeout) as response:
                raw = response.read()
        except TimeoutError as error:
            raise MihomoError(
                f"Mihomo controller request timed out: {method} {path}"
            ) from error
        except (urllib.error.URLError, urllib.error.HTTPError) as error:
            raise MihomoError(
                f"Mihomo controller request failed: {path}: {error}"
            ) from error
        if not raw.strip():
            return {}
        try:
            return json.loads(raw)
        except json.JSONDecodeError as error:
            raise MihomoError(
                f"Mihomo controller returned invalid JSON: {path}"
            ) from error

    def controller_check(self) -> None:
        self.api("/version")

    def credential_command(self, *args: str, input_text: str | None = None) -> str:
        try:
            result = subprocess.run(
                [self.settings.executable("systemd-creds"), *args],
                check=True,
                text=True,
                input=input_text,
                capture_output=True,
            )
        except subprocess.CalledProcessError as error:
            detail = (error.stderr or error.stdout or "").strip()
            suffix = f": {detail}" if detail else ""
            raise MihomoError(f"Could not access saved subscription{suffix}") from error
        return result.stdout

    def subscription_credential(self, name: str) -> Path:
        validate_subscription_name(name)
        return self.settings.subscriptions_dir / f"{name}.cred"

    def credential_name(self, name: str) -> str:
        return f"mihomo-subscription-{name}"

    def save_subscription(self, name: str, url: str) -> None:
        self.settings.subscriptions_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
        credential_path = self.subscription_credential(name)
        fd, temporary = tempfile.mkstemp(
            prefix=f"{name}.", suffix=".cred", dir=self.settings.subscriptions_dir
        )
        os.close(fd)
        temporary_path = Path(temporary)
        try:
            self.credential_command(
                "encrypt",
                "--with-key=host",
                f"--name={self.credential_name(name)}",
                "-",
                str(temporary_path),
                input_text=f"{url}\n",
            )
            os.chown(temporary_path, 0, 0)
            os.chmod(temporary_path, 0o600)
            os.replace(temporary_path, credential_path)
        finally:
            temporary_path.unlink(missing_ok=True)

    def load_subscription(self, name: str) -> str:
        credential_path = self.require_subscription(name)
        url = self.credential_command(
            "decrypt",
            f"--name={self.credential_name(name)}",
            str(credential_path),
            "-",
        ).strip()
        validate_subscription_url(url)
        return url

    def active_subscription(self) -> str | None:
        if not self.settings.active_subscription_path.is_file():
            return None
        name = self.settings.active_subscription_path.read_text().strip()
        validate_subscription_name(name)
        if not self.subscription_credential(name).is_file():
            raise MihomoError(f"Active subscription does not exist: {name}")
        return name

    def set_active_subscription(self, name: str) -> None:
        validate_subscription_name(name)
        self.settings.state_dir.mkdir(mode=0o750, parents=True, exist_ok=True)
        atomic_write_text(self.settings.active_subscription_path, f"{name}\n", mode=0o600)

    def saved_mode(self) -> str:
        if not self.settings.mode_state_file.is_file():
            return "rule"
        mode = self.settings.mode_state_file.read_text().strip()
        if mode not in MODES:
            raise MihomoError(f"Saved Mihomo mode is invalid: {self.settings.mode_state_file}")
        return mode

    def save_mode(self, mode: str) -> None:
        self.settings.state_dir.mkdir(mode=0o750, parents=True, exist_ok=True)
        # The mode is not a secret; let unprivileged `mihomo-ctl mode` read it.
        atomic_write_text(self.settings.mode_state_file, f"{mode}\n", mode=0o644)

    def subscription_names(self) -> list[str]:
        if not self.settings.subscriptions_dir.is_dir():
            return []
        return sorted(
            path.stem
            for path in self.settings.subscriptions_dir.glob("*.cred")
            if re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,63}", path.stem)
        )

    def write_config(self, template: str, url: str, mode: str) -> None:
        rendered = template.replace("$URL", url).replace("$MODE", mode)
        atomic_write_text(
            self.settings.config_path, rendered, mode=0o640, group=grp.getgrnam(self.settings.service_group).gr_gid
        )

    def template(self) -> str:
        if self.settings.template_path is None:
            raise MihomoError("Subscription initialization requires template_path in settings")
        try:
            return self.settings.template_path.read_text()
        except OSError as error:
            raise MihomoError(f"Could not read subscription template: {error}") from error

    def require_new_subscription(self, name: str) -> None:
        if self.subscription_credential(name).exists():
            raise MihomoError(f"Subscription already exists: {name}; use 'subscription edit'")

    def require_subscription(self, name: str) -> Path:
        path = self.subscription_credential(name)
        if not path.is_file():
            raise MihomoError(f"Subscription does not exist: {name}")
        return path

    def removable_subscription(self, name: str) -> Path:
        path = self.require_subscription(name)
        if self.active_subscription() == name:
            raise MihomoError(
                f"Cannot remove active subscription '{name}'; switch subscriptions first"
            )
        return path

    def _apply_subscription(self, config_template: str, name: str) -> None:
        require_root()
        url = self.load_subscription(name)
        self.set_active_subscription(name)
        self.write_config(config_template, url, self.saved_mode())
        self.cleanup_runtime("tun")
        self.restart_mihomo()

    def switch_subscription(self, name: str) -> None:
        require_root()
        self._apply_subscription(self.template(), name)

    def init_runtime(self, name: str, url: str | None = None) -> None:
        """Initialize the runtime directory and apply a saved or supplied subscription."""
        require_root()
        validate_subscription_name(name)
        if url is not None:
            validate_subscription_url(url)
        config_template = self.template()
        self.settings.config_dir.mkdir(mode=0o750, parents=True, exist_ok=True)
        os.chown(self.settings.config_dir, 0, grp.getgrnam(self.settings.service_group).gr_gid)
        os.chmod(self.settings.config_dir, 0o750)
        if url is not None:
            self.save_subscription(name, url)
        self._apply_subscription(config_template, name)

    def add_subscription(self, name: str, url: str) -> None:
        require_root()
        self.require_new_subscription(name)
        validate_subscription_url(url)
        self.save_subscription(name, url)

    def edit_subscription(self, name: str, url: str) -> bool:
        """Replace a URL; return whether the active runtime was also updated."""
        require_root()
        self.require_subscription(name)
        validate_subscription_url(url)
        config_template = self.template()
        self.save_subscription(name, url)
        applied = self.active_subscription() == name
        if applied:
            self._apply_subscription(config_template, name)
        return applied

    def remove_subscription(self, name: str) -> None:
        """Remove a non-active subscription; confirmation belongs to the frontend."""
        require_root()
        self.removable_subscription(name).unlink()

    def rule_priorities(self, family: int, predicate) -> list[int]:
        output = self.command_output("ip", f"-{family}", "-o", "rule", "show")
        priorities = []
        for line in output.splitlines():
            match = re.match(r"\s*(\d+):", line)
            if match and predicate(line):
                priorities.append(int(match.group(1)))
        return sorted(set(priorities), reverse=True)

    def delete_rules(self, family: int, priorities: list[int]) -> None:
        for priority in priorities:
            self.command(
                "ip", f"-{family}", "rule", "del", "priority", str(priority),
                check=False, capture=True,
            )

    def flush_route_table(self, family: int, table: str) -> None:
        """Flush a route table when present without exposing an absent-table error."""
        self.command(
            "ip", f"-{family}", "route", "flush", "table", table,
            check=False, capture=True,
        )

    def cleanup_owned_rules(self) -> None:
        def owned(line: str) -> bool:
            return (
                re.search(rf"lookup {self.settings.routing_table}$", line) is not None
                or re.search(r"uidrange \d+-\d+ lookup main$", line) is not None
                or re.search(
                    r"ipproto (udp|tcp) dport 53 lookup main$", line
                ) is not None
                or re.search(
                    r"to (224\.0\.0\.0/4|255\.255\.255\.255(/32)?|169\.254\.0\.0/16) lookup main$",
                    line,
                ) is not None
                or re.search(
                    r"lookup main suppress_prefixlength 0$", line
                ) is not None
            )

        self.delete_rules(4, self.rule_priorities(4, owned))
        self.flush_route_table(4, str(self.settings.routing_table))
        self.settings.routing_state_file.unlink(missing_ok=True)

    def cleanup_foreign_rules(self) -> None:
        def foreign(line: str) -> bool:
            return any(re.search(pattern, line, re.IGNORECASE)
                       for pattern in self.settings.legacy_rule_patterns)

        for family in (4, 6):
            if self.settings.legacy_rule_patterns:
                self.delete_rules(family, self.rule_priorities(family, foreign))
            for table in self.settings.legacy_route_tables:
                self.flush_route_table(family, str(table))

    def cleanup_runtime(self, kind: str = "rules") -> None:
        """Clean only the legacy resources explicitly assigned to this deployment."""
        require_root()
        if kind not in {"rules", "tun"}:
            raise MihomoError("Cleanup kind must be one of: rules, tun")
        if kind == "tun" and not self.service_active(self.settings.service_unit):
            devices = (*self.settings.legacy_tun_devices, self.settings.tun_device)
            for device in dict.fromkeys(devices):
                self.command("ip", "link", "delete", "dev", device, check=False)
        self.cleanup_foreign_rules()

    def wait_for_tun(self) -> None:
        deadline = time.monotonic() + self.settings.tun_wait_timeout
        while True:
            if self.command(
                "ip", "link", "show", "dev", self.settings.tun_device, check=False,
            ).returncode == 0:
                return
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise MihomoError(f"Mihomo TUN interface {self.settings.tun_device} did not appear")
            time.sleep(min(1, remaining))

    def service_active(self, unit: str) -> bool:
        return (
            self.command(
                "systemctl",
                "is-active",
                "--quiet",
                unit,
                check=False,
            ).returncode
            == 0
        )

    def reinstall_routing(self) -> None:
        """Rebuild the policy routes by stopping and starting the routing unit."""
        self.command("systemctl", "stop", self.settings.routing_unit)
        self.command("systemctl", "start", self.settings.routing_unit)

    def restart_mihomo(self) -> None:
        """Restart the daemon and put transparent routing back in place.

        Restarting the daemon makes systemd stop mihomo-routing through BindsTo, so
        the routing unit is stopped up front: a propagated stop that lands while a
        routing restart is in flight cancels that start (status=15/TERM).
        """
        routing_enabled = self.service_active(self.settings.routing_unit)
        if routing_enabled:
            self.command("systemctl", "stop", self.settings.routing_unit)
        self.command("systemctl", "restart", self.settings.service_unit)
        if routing_enabled:
            self.command("systemctl", "start", self.settings.routing_unit)

    def choose_base(self) -> int:
        output = self.command_output("ip", "-4", "rule", "show")
        main_priority = None
        priorities = []
        for line in output.splitlines():
            match = re.match(r"\s*(\d+):", line)
            if not match:
                continue
            priority = int(match.group(1))
            priorities.append(priority)
            if re.search(r"from all lookup main$", line):
                main_priority = priority
        if main_priority is None:
            raise MihomoError("Could not find the Linux main routing rule")

        candidate = main_priority - 1001
        while candidate >= 1:
            collisions = [
                priority
                for priority in priorities
                if candidate <= priority <= candidate + 1000
            ]
            if not collisions:
                return candidate
            candidate = min(collisions) - 1001
        raise MihomoError(
            f"No free 1000-priority range before main ({main_priority})"
        )

    def routing_start(self) -> None:
        """Install Mihomo policy routes (used by systemd)."""
        require_root()
        self.cleanup_owned_rules()
        self.cleanup_foreign_rules()
        self.wait_for_tun()
        uid = pwd.getpwnam(self.settings.service_user).pw_uid
        base = self.choose_base()
        self.settings.routing_state_file.parent.mkdir(mode=0o755, parents=True, exist_ok=True)
        try:
            self.command(
                "ip", "-4", "route", "replace", "table", str(self.settings.routing_table),
                "default", "dev", self.settings.tun_device,
            )
            rules = (
                (0, ("uidrange", f"{uid}-{uid}", "lookup", "main")),
                (100, ("ipproto", "udp", "dport", "53", "lookup", "main")),
                (101, ("ipproto", "tcp", "dport", "53", "lookup", "main")),
                # Multicast, broadcast and link-local traffic must stay on the LAN.
                (120, ("to", "224.0.0.0/4", "lookup", "main")),
                (121, ("to", "255.255.255.255", "lookup", "main")),
                (122, ("to", "169.254.0.0/16", "lookup", "main")),
                (200, ("lookup", "main", "suppress_prefixlength", "0")),
                (1000, ("lookup", str(self.settings.routing_table))),
            )
            for offset, rule in rules:
                self.command("ip", "-4", "rule", "add", "priority", str(base + offset), *rule)
            self.settings.routing_state_file.write_text(f"{base}\n")
        except Exception:
            self.cleanup_owned_rules()
            raise

    def routing_cleanup(self) -> None:
        """Remove Mihomo policy routes (used by systemd)."""
        require_root()
        self.cleanup_owned_rules()

    def enable_routing(self) -> None:
        require_root()
        self.require_config()
        self.command("systemctl", "start", self.settings.service_unit)
        # A plain start would not repair routes lost while the unit remains active.
        self.reinstall_routing()

    def disable_routing(self) -> None:
        require_root()
        self.command("systemctl", "stop", self.settings.routing_unit)

    def provider_names(self, kind: str) -> list[str]:
        data = self.api(f"/providers/{kind}")
        providers = as_dict(as_dict(data).get("providers"))
        return sorted(providers)

    def proxy_selection(self) -> ProxySelection:
        data = as_dict(self.api(f"/proxies/{urllib.parse.quote(self.settings.proxy_group, safe='')}"))
        return ProxySelection(
            selected=str(data.get("now", "(none)")),
            nodes=tuple(str(name) for name in as_list(data.get("all"))),
        )

    def select_node(self, name: str) -> None:
        self.api(f"/proxies/{urllib.parse.quote(self.settings.proxy_group, safe='')}", "PUT", {"name": name})

    def current_mode(self) -> str:
        return str(as_dict(self.api("/configs")).get("mode", "unknown"))

    def set_mode(self, value: str) -> None:
        # Check connectivity before persisting a mode that could not be applied.
        self.controller_check()
        if value not in MODES:
            raise MihomoError(f"Mode must be one of: {', '.join(MODES)}")
        require_root()
        self.save_mode(value)
        # PATCH avoids recreating the TUN device and losing the policy routes.
        self.api("/configs", "PATCH", {"mode": value})

    def update_providers(self, provider: str | None = None, update_all: bool = False) -> list[str]:
        require_root()
        name = self.active_subscription()
        if name is None:
            raise MihomoError(
                "No active subscription; run: sudo mihomo-ctl subscription init"
            )
        self.switch_subscription(name)
        self.controller_check()
        providers = self.provider_names("proxies") if update_all else [provider or self.settings.default_provider]
        for item in providers:
            self.api(f"/providers/proxies/{urllib.parse.quote(item, safe='')}", "PUT")
        return providers

    def update_rules(self) -> list[str]:
        self.controller_check()
        providers = self.provider_names("rules")
        for provider in providers:
            self.api(f"/providers/rules/{urllib.parse.quote(provider, safe='')}", "PUT")
        return providers

    def test_providers(self) -> ProviderHealth:
        """Run proxy-provider health checks."""
        self.controller_check()
        providers = self.provider_names("proxies")
        if not providers:
            raise MihomoError("No proxy providers configured")
        for provider in providers:
            self.api(
                f"/providers/proxies/{urllib.parse.quote(provider, safe='')}"
                "/healthcheck"
            )
        time.sleep(1)
        results = []
        for provider in providers:
            data = self.api(
                f"/providers/proxies/{urllib.parse.quote(provider, safe='')}"
            )
            for proxy in as_list(as_dict(data).get("proxies")):
                if not isinstance(proxy, dict):
                    continue
                history = proxy.get("history", [])
                delay = history[-1].get("delay", 999999) if history else 999999
                results.append(
                    (delay, proxy.get("alive", False), proxy.get("name", ""))
                )
        return ProviderHealth(tuple(providers), tuple(sorted(results)))

    def connection_snapshot(self) -> ConnectionSnapshot:
        """List active connections."""
        self.controller_check()
        data = self.api("/connections")
        if not isinstance(data, dict):
            raise MihomoError("Mihomo controller returned an invalid connection snapshot")
        connections = data.get("connections") or []
        if not isinstance(connections, list):
            raise MihomoError("Mihomo controller returned an invalid connection list")

        def byte_count(value: object) -> int | float | None:
            return value if isinstance(value, (int, float)) else None

        records = []
        for connection in connections:
            if not isinstance(connection, dict):
                continue
            metadata = as_dict(connection.get("metadata"))
            source = ":".join(
                str(part)
                for part in (metadata.get("sourceIP"), metadata.get("sourcePort"))
                if part not in (None, "")
            )
            destination_host = metadata.get("host") or metadata.get("destinationIP") or "—"
            destination_port = metadata.get("destinationPort")
            destination = f"{destination_host}:{destination_port}" if destination_port else str(destination_host)
            rule = " ".join(
                str(part)
                for part in (connection.get("rule"), connection.get("rulePayload"))
                if part
            ) or "—"
            chains = as_list(connection.get("chains"))
            process_path = metadata.get("processPath")
            records.append(Connection(
                protocol=str(metadata.get("network") or metadata.get("type") or "—"),
                source=source or "—",
                destination=destination,
                process=Path(str(process_path)).name if process_path else "—",
                rule=rule,
                proxy=str(chains[-1]) if chains else "—",
                download=byte_count(connection.get("download")),
                upload=byte_count(connection.get("upload")),
            ))
        return ConnectionSnapshot(
            tuple(records), len(connections),
            byte_count(data.get("downloadTotal")), byte_count(data.get("uploadTotal")),
        )

    def close_connections(self) -> None:
        """Close all active Mihomo connections."""
        self.controller_check()
        self.api("/connections", "DELETE")

    def get_status(self) -> MihomoStatus:
        daemon_active = self.service_active(self.settings.service_unit)
        routing_active = self.service_active(self.settings.routing_unit)
        try:
            self.controller_check()
            mode = self.current_mode()
            proxy = self.proxy_selection()
            count = len(self.provider_names("proxies"))
        except MihomoError as error:
            return MihomoStatus(daemon_active, routing_active, error=str(error))
        return MihomoStatus(daemon_active, routing_active, mode, proxy, count)

    def route_snapshot(self) -> list[RouteSection]:
        sections = (
            ("IPv4 policy rules", ("ip", "-4", "rule", "show")),
            (f"IPv4 Mihomo table ({str(self.settings.routing_table)})", ("ip", "-4", "route", "show", "table", str(self.settings.routing_table))),
            ("IPv4 all routes", ("ip", "-4", "route", "show", "table", "all")),
        )
        results = []
        for title, args in sections:
            result = self.command(*args, check=False, capture=True)
            output = (result.stdout or result.stderr).strip() or "(empty)"
            results.append(RouteSection(title, output, result.returncode == 0))
        return results

    def config_metadata(self) -> ConfigMetadata:
        require_root()
        if not self.settings.config_path.exists():
            return ConfigMetadata(self.settings.config_path)
        stat = self.settings.config_path.stat()
        return ConfigMetadata(
            self.settings.config_path,
            pwd.getpwuid(stat.st_uid).pw_name,
            grp.getgrgid(stat.st_gid).gr_name,
            stat.st_mode & 0o777,
        )

    def diagnose(self) -> DoctorReport:
        """Check Mihomo configuration, service, and routing health."""
        require_root()
        checks: list[tuple[str, bool]] = []
        notes: list[str] = []

        def check(label: str, passed: bool) -> None:
            checks.append((label, passed))

        check(
            "mihomo service active",
            self.service_active(self.settings.service_unit),
        )
        check(
            "routing service active",
            self.service_active(self.settings.routing_unit),
        )
        try:
            self.controller_check()
            controller_ok = True
        except MihomoError:
            controller_ok = False
        check("controller reachable", controller_ok)
        check(
            "TUN interface exists",
            self.command(
                "ip", "link", "show", "dev", self.settings.tun_device,
                check=False,
                capture=True,
            ).returncode == 0,
        )
        check(
            "config exists", self.settings.config_path.is_file(),
        )
        try:
            stat = self.settings.config_path.stat()
            owner = pwd.getpwuid(stat.st_uid).pw_name
            group = grp.getgrgid(stat.st_gid).gr_name
            check(
                f"config permissions are root:{self.settings.service_group} 0640",
                f"{owner} {group} {stat.st_mode & 0o777:o}" == f"root {self.settings.service_group} 640",
            )
        except FileNotFoundError:
            check(f"config permissions are root:{self.settings.service_group} 0640", False)

        if controller_ok:
            providers = as_dict(as_dict(self.api("/providers/proxies")).get("providers"))
            count = sum(
                len(as_list(as_dict(value).get("proxies")))
                for value in providers.values()
            )
            check(f"provider node count > 0 ({count})", count > 0)
            notes.append(f"Selected node: {self.proxy_selection().selected}")
        else:
            check("provider node count (controller unavailable)", False)

        rules = self.command_output("ip", "-4", "rule", "show")
        table_result = self.command(
            "ip", "-4", "route", "show", "table", str(self.settings.routing_table),
            check=False,
            capture=True,
        )
        table_routes = table_result.stdout
        table_exists = table_result.returncode == 0
        if not table_exists:
            notes.append(f"Mihomo routing table {str(self.settings.routing_table)} is unavailable")
        catchall = re.search(rf"^\s*\d+:.*lookup {self.settings.routing_table}$", rules, re.MULTILINE)
        check(
            f"table {self.settings.routing_table} contains Mihomo default route",
            bool(
                table_exists
                and catchall
                and re.search(rf"^default dev {re.escape(self.settings.tun_device)}(?:\s|$)", table_routes, re.MULTILINE)
            ),
        )
        if catchall:
            catchall_priority = int(catchall.group(0).split(":", 1)[0].strip())
            earlier = [
                int(match.group(1))
                for match in re.finditer(
                    r"^\s*(\d+):.*(?:uidrange|dport 53|suppress_prefixlength 0)",
                    rules,
                    re.MULTILINE,
                )
                if int(match.group(1)) < catchall_priority
            ]
            check(
                "policy rules are present before Mihomo catch-all", bool(earlier)
            )
            if self.settings.preceding_rule_pattern:
                preceding = [
                    int(match.group(1))
                    for match in re.finditer(
                        rf"^\s*(\d+):.*(?:{self.settings.preceding_rule_pattern})",
                        rules, re.MULTILINE,
                    )
                ]
                if preceding:
                    check("configured policy rules precede Mihomo catch-all",
                          max(preceding) < catchall_priority)
                else:
                    notes.append("No policy rules match preceding_rule_pattern")
        else:
            check("Mihomo catch-all policy rule exists", False)
        check(
            "DNS bypass rules exist",
            "ipproto udp dport 53 lookup main" in rules
            and "ipproto tcp dport 53 lookup main" in rules,
        )
        listeners = self.command_output("ss", "-lntup", check=False)
        process_name = re.escape(Path(self.settings.executable("mihomo")).name)
        check(
            "Mihomo is not listening on port 53",
            not re.search(rf"{process_name}.*:53|:53.*{process_name}", listeners),
        )

        return DoctorReport(tuple(checks), tuple(notes))

    def reload_config(self) -> DoctorReport:
        require_root()
        self.require_config()
        self.command("mihomo", "-t", "-d", str(self.settings.state_dir), "-f", str(self.settings.config_path))
        self.api("/configs?force=true", "PUT", {"path": str(self.settings.config_path), "payload": ""})
        if self.service_active(self.settings.routing_unit):
            self.reinstall_routing()
        return self.diagnose()

    def service_invocation_id(self) -> str:
        result = self.command_output(
            "systemctl", "show", "--property=InvocationID", "--value",
            self.settings.service_unit,
        ).strip()
        if not result:
            raise MihomoError(
                "Mihomo service is not running; no current invocation logs exist"
            )
        return result

    def log_records(self, args: list[str]) -> Iterator[LogRecord]:
        """Stream the current service invocation; closing the iterator stops journalctl."""
        invocation_id = self.service_invocation_id()
        process = subprocess.Popen(
            [
                self.settings.executable("journalctl"), f"--unit={self.settings.service_unit}", "--no-pager", *args,
                "--output=json", f"_SYSTEMD_INVOCATION_ID={invocation_id}",
            ],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        assert process.stdout is not None
        try:
            for line in process.stdout:
                if not line.strip():
                    continue
                record = json.loads(line)
                timestamp = record.get("__REALTIME_TIMESTAMP")
                seconds = (
                    int(timestamp) / 1_000_000
                    if isinstance(timestamp, str) and timestamp.isdigit()
                    else None
                )
                yield LogRecord(
                    timestamp=seconds,
                    priority=str(record.get("PRIORITY", "6")),
                    source=str(record.get("SYSLOG_IDENTIFIER", self.settings.service_unit.removesuffix(".service"))),
                    message=str(record.get("MESSAGE", "")),
                )
            stderr = process.stderr.read() if process.stderr is not None else ""
            if process.wait() and stderr.strip():
                raise MihomoError(f"Could not read Mihomo logs: {stderr.strip()}")
        finally:
            if process.poll() is None:
                process.terminate()
                process.wait()
            process.stdout.close()
            if process.stderr is not None:
                process.stderr.close()

    def route_to(self, address: str) -> str:
        return self.command_output("ip", "-4", "route", "get", address)


def create_cli(core: MihomoCore | None = None, console=None):
    from rich.console import Console
    from rich.panel import Panel
    from rich.prompt import Prompt
    from rich.table import Table
    from rich.text import Text
    import typer

    console = console or Console()
    app = typer.Typer(
        name="mihomo-ctl",
        help="Control Mihomo and its host-local subscriptions.",
        no_args_is_help=True,
    )
    subscription_app = typer.Typer(
        help="Manage encrypted Mihomo subscriptions.", no_args_is_help=True
    )
    proxy_app = typer.Typer(help="Manage Mihomo proxies.", no_args_is_help=True)
    routing_app = typer.Typer(help="Manage transparent routing.", no_args_is_help=True)
    app.add_typer(subscription_app, name="subscription")
    app.add_typer(proxy_app, name="proxy")
    app.add_typer(routing_app, name="routing")

    injected_core = core
    settings_path = None

    @app.callback()
    def configure(
        settings: Annotated[Path | None, typer.Option(
            "--settings", envvar="MIHOMO_CTL_SETTINGS",
            help="Deployment settings JSON (paths are relative to this file).",
        )] = None,
    ) -> None:
        nonlocal core, settings_path
        if settings is not None or injected_core is None:
            path = settings or (Path(DEFAULT_SETTINGS_PATH) if DEFAULT_SETTINGS_PATH else None)
            settings_path = path.expanduser().resolve() if path is not None else None
            core = MihomoCore(load_settings(settings_path))
        else:
            core = injected_core
            settings_path = None

    def success(message: str) -> None:
        console.print(f"[bold green]✓[/] {message}")

    def info(message: str) -> None:
        console.print(f"[cyan]•[/] {message}")

    def warning(message: str) -> None:
        console.print(f"[yellow]![/] {message}")

    def service_state(active: bool) -> Text:
        return Text("active" if active else "inactive", style="green" if active else "red")

    def as_root() -> None:
        if os.geteuid() != 0:
            if settings_path is None and core.settings != Settings():
                raise MihomoError("Privilege escalation requires a --settings file for custom settings")
            sudo = shutil.which(core.settings.executable("sudo"))
            if sudo is None:
                raise MihomoError("Root privileges are required, but the configured sudo was not found")
            args = configured_arguments(sys.argv[1:], settings_path)
            os.execv(sudo, [sudo, sys.executable, str(Path(sys.argv[0]).resolve()), *args])

    def format_bytes(value: object) -> str:
        if not isinstance(value, (int, float)):
            return "—"
        units = ("B", "KiB", "MiB", "GiB", "TiB")
        amount = float(value)
        for unit in units:
            if amount < 1024 or unit == units[-1]:
                return f"{amount:.1f} {unit}" if unit != "B" else f"{amount:.0f} B"
            amount /= 1024
        return "—"

    def print_doctor(report: DoctorReport) -> None:
        table = Table(title="Mihomo doctor", header_style="bold cyan")
        table.add_column("Result", justify="center", no_wrap=True)
        table.add_column("Check")
        for label, passed in report.checks:
            result = Text("PASS", style="bold green") if passed else Text(
                "FAIL", style="bold red"
            )
            table.add_row(result, label)
        console.print(table)
        for note in report.notes:
            info(note)

        for variable in (
            "MIHOMO_TEST_TS_IP", "MIHOMO_TEST_SUBNET_IP",
            "MIHOMO_TEST_LAN_IP", "MIHOMO_TEST_CAMPUS_IP",
        ):
            value = os.environ.get(variable)
            if value:
                info(f"Route check {variable}={value}:")
                console.print(Text(core.route_to(value)))

        if report.failures:
            raise MihomoError(f"{report.failures} Mihomo doctor check(s) failed")

    @subscription_app.command("init")
    def init_command() -> None:
        """Create the runtime config from the active encrypted subscription."""
        as_root()
        name = core.active_subscription()
        url = None
        if name is None:
            name = typer.prompt("Subscription name", default="default")
            validate_subscription_name(name)
            url = typer.prompt("Subscription URL", hide_input=True)
        elif typer.confirm(f"Replace saved subscription URL for '{name}'?", default=False):
            url = typer.prompt("Subscription URL", hide_input=True)
        else:
            info(f"Keeping saved subscription '{name}'")
        core.init_runtime(name, url)
        success(f"Runtime config created at {core.settings.config_path}; {core.settings.service_unit} restarted.")

    @subscription_app.command("add")
    def add_command(name: Annotated[str, typer.Argument()]) -> None:
        """Create a named encrypted subscription."""
        as_root()
        core.require_new_subscription(name)
        url = typer.prompt("Subscription URL", hide_input=True)
        core.add_subscription(name, url)
        success(f"Saved encrypted subscription '{name}'")

    @subscription_app.command("edit")
    def edit_command(name: Annotated[str, typer.Argument()]) -> None:
        """Replace NAME's URL; apply it immediately when it is active."""
        as_root()
        core.require_subscription(name)
        url = typer.prompt("Subscription URL", hide_input=True)
        if core.edit_subscription(name, url):
            success(f"Updated and applied subscription '{name}'")
        else:
            success(f"Updated encrypted subscription '{name}'")

    @subscription_app.command("remove")
    def remove_command(name: Annotated[str, typer.Argument()]) -> None:
        """Remove a non-active encrypted subscription after confirmation."""
        as_root()
        core.removable_subscription(name)
        if not typer.confirm(f"Remove saved subscription '{name}'?", default=False):
            info("Subscription unchanged")
            return
        core.remove_subscription(name)
        success(f"Removed encrypted subscription '{name}'")

    @subscription_app.command("switch")
    def switch_command(name: Annotated[str, typer.Argument()]) -> None:
        """Activate NAME and restart Mihomo with it."""
        as_root()
        core.switch_subscription(name)
        success(f"Switched to subscription '{name}'")

    @subscription_app.command("list")
    def list_subscriptions() -> None:
        """List saved subscription names without exposing URLs."""
        as_root()
        active = core.active_subscription()
        names = core.subscription_names()
        if not names:
            warning("No saved subscriptions; run: sudo mihomo-ctl subscription add <name>")
            return
        table = Table(title="Mihomo subscriptions", header_style="bold cyan")
        table.add_column("Name")
        table.add_column("Active", justify="center")
        for name in names:
            table.add_row(name, Text("●", style="bold green") if name == active else Text())
        console.print(table)

    @proxy_app.command("node")
    def node_command(name: Annotated[str | None, typer.Argument()] = None) -> None:
        """Show proxy nodes or select NAME."""
        selection = core.proxy_selection()
        old = selection.selected
        nodes = selection.nodes
        if name is None:
            if not nodes:
                raise MihomoError(f"No nodes are available in {core.settings.proxy_group}")
            table = Table(title=f"{core.settings.proxy_group} nodes", header_style="bold cyan")
            table.add_column("#", justify="right", style="cyan", no_wrap=True)
            table.add_column("Node", min_width=24)
            table.add_column("Selected", justify="center")
            for index, item in enumerate(nodes, 1):
                selected = Text("●", style="bold green") if item == old else Text()
                table.add_row(str(index), Text(str(item)), selected)
            console.print(table)
            answer = Prompt.ask(
                "Select node ([dim]q to cancel[/])",
                choices=[*(str(index) for index in range(1, len(nodes) + 1)), "q"],
                default="q",
                show_choices=False,
            )
            if answer == "q":
                info("Node selection cancelled")
                return
            name = str(nodes[int(answer) - 1])
        core.select_node(name)
        console.print(
            Text.assemble(
                (old, "dim"),
                (" → ", "cyan"),
                (name, "bold green"),
            )
        )

    @subscription_app.command("update")
    def update_command(
        provider: Annotated[str | None, typer.Argument()] = None,
        update_all: Annotated[bool, typer.Option("--all")] = False,
    ) -> None:
        """Rebuild from the active subscription and refresh proxy providers."""
        as_root()
        for item in core.update_providers(provider, update_all):
            info(f"Updated provider: {item}")
        success("Proxy provider update complete")

    @proxy_app.command("update-rules")
    def update_rules_command() -> None:
        """Refresh all rule providers."""
        providers = core.update_rules()
        if not providers:
            warning("No rule providers configured")
            return
        for provider in providers:
            info(f"Updated rule provider: {provider}")
        success("Rule provider update complete")

    @proxy_app.command("test")
    def test_command() -> None:
        """Run proxy-provider health checks."""
        report = core.test_providers()
        for provider in report.providers:
            info(f"Health check complete: {provider}")
        table = Table(title="Proxy health", header_style="bold cyan")
        table.add_column("Delay", justify="right")
        table.add_column("Status", justify="center")
        table.add_column("Node", min_width=24)
        for delay, alive, name in report.results:
            delay_text = "—" if delay >= 999999 else f"{delay} ms"
            status = Text("UP", style="bold green") if alive else Text(
                "DOWN", style="bold red"
            )
            table.add_row(delay_text, status, Text(str(name)))
        console.print(table)

    @app.command("status")
    def status_command() -> None:
        """Show Mihomo and routing status."""
        status = core.get_status()
        table = Table.grid(padding=(0, 2))
        table.add_column(style="bold")
        table.add_column()
        table.add_row(core.settings.service_unit, service_state(status.daemon_active))
        table.add_row(core.settings.routing_unit, service_state(status.routing_active))
        if status.error:
            table.add_row("controller", Text("unreachable", style="red"))
        else:
            table.add_row("controller", Text("reachable", style="green"))
            table.add_row("mode", Text(status.mode, style="cyan"))
            table.add_row("selected", Text(status.proxy.selected, style="bold green"))
            table.add_row("providers", str(status.provider_count))
        console.print(Panel(table, title="Mihomo status", border_style="cyan"))

    @routing_app.command("routes")
    def routes_command() -> None:
        """Show policy-routing tables and rules."""
        for section in core.route_snapshot():
            console.print(Panel(
                Text(section.output), title=section.title,
                border_style="cyan" if section.available else "yellow",
            ))

    @proxy_app.command("connections")
    def connections_command() -> None:
        """List active connections."""
        data = core.connection_snapshot()
        table = Table(title="Mihomo connections", header_style="bold cyan")
        table.add_column("Protocol", no_wrap=True)
        table.add_column("Source", no_wrap=True)
        table.add_column("Destination", min_width=24, max_width=36, overflow="ellipsis")
        table.add_column("Process", max_width=20, overflow="ellipsis")
        table.add_column("Rule", min_width=14, max_width=24, overflow="ellipsis")
        table.add_column("Proxy", min_width=14, max_width=24, overflow="ellipsis")
        table.add_column("Down", justify="right")
        table.add_column("Up", justify="right")
        for connection in data.connections:
            table.add_row(
                connection.protocol,
                connection.source,
                connection.destination,
                connection.process,
                connection.rule,
                connection.proxy,
                format_bytes(connection.download),
                format_bytes(connection.upload),
            )
        console.print(table)
        info(
            f"{data.count} active; total down {format_bytes(data.download_total)}, "
            f"up {format_bytes(data.upload_total)}"
        )

    @proxy_app.command("close-connections")
    def close_connections_command() -> None:
        """Close all active Mihomo connections."""
        core.close_connections()
        success("Closed all Mihomo connections")

    @app.command("doctor")
    def doctor_command() -> None:
        """Check Mihomo configuration, service, and routing health."""
        as_root()
        print_doctor(core.diagnose())

    @app.command("mode")
    def mode_command(value: Annotated[str | None, typer.Argument()] = None) -> None:
        """Show or set the Mihomo mode (rule, global, direct, script)."""
        if value is None:
            current = core.current_mode()
            saved = core.saved_mode()
            console.print(current)
            if current != saved:
                warning(
                    f"Runtime mode {current} differs from the saved mode {saved}; "
                    f"run: sudo mihomo-ctl mode {saved}"
                )
            return
        as_root()
        core.set_mode(value)
        success(f"Mihomo mode: {value}")
        if value == "global":
            info(f"Proxy group {core.settings.proxy_group} selection: {core.proxy_selection().selected}")

    @app.command(
        "log", context_settings={"allow_extra_args": True, "ignore_unknown_options": True}
    )
    def log_command(ctx: typer.Context) -> None:
        """Show the current Mihomo service invocation; pass options to journalctl."""
        try:
            with closing(core.log_records(ctx.args)) as records:
                for record in records:
                    if record.timestamp is not None:
                        time_text = time.strftime("%H:%M:%S", time.localtime(record.timestamp))
                    else:
                        time_text = "—"
                    level, style = {
                        "0": ("EMERG", "bold red"),
                        "1": ("ALERT", "bold red"),
                        "2": ("CRIT", "bold red"),
                        "3": ("ERROR", "red"),
                        "4": ("WARN", "yellow"),
                        "5": ("NOTICE", "cyan"),
                        "6": ("INFO", "green"),
                        "7": ("DEBUG", "dim"),
                    }.get(record.priority, ("LOG", "white"))
                    console.print(
                        Text.assemble(
                            (f"{time_text} ", "dim"),
                            (f"{level:<6} ", style),
                            (f"{record.source}: ", "cyan"),
                            record.message,
                        )
                    )
        except KeyboardInterrupt:
            pass

    @routing_app.command("enable")
    def enable_command() -> None:
        """Enable transparent routing."""
        as_root()
        core.enable_routing()
        success("Mihomo transparent routing enabled")

    @routing_app.command("disable")
    def disable_command() -> None:
        """Disable transparent routing while keeping Mihomo running."""
        as_root()
        core.disable_routing()
        success(f"Mihomo transparent routing disabled; {core.settings.service_unit} remains running.")

    @app.command("reload")
    def reload_command() -> None:
        """Validate and reload the current runtime configuration."""
        as_root()
        info("Validating and reloading Mihomo configuration")
        print_doctor(core.reload_config())

    @app.command("config")
    def config_command() -> None:
        """Show runtime-config metadata without exposing its contents."""
        as_root()
        metadata = core.config_metadata()
        table = Table.grid(padding=(0, 2))
        table.add_column(style="bold")
        table.add_column()
        table.add_row("Runtime config", str(metadata.path))
        if metadata.permissions is not None:
            table.add_row("Owner", metadata.owner)
            table.add_row("Group", metadata.group)
            table.add_row("Mode", f"{metadata.permissions:04o}")
        else:
            table.add_row("Status", Text("not created", style="yellow"))
        console.print(Panel(table, title="Mihomo runtime config", border_style="cyan"))
        info("Contents are not printed because this file contains the subscription URL")

    @routing_app.command("start")
    def start_command() -> None:
        """Install Mihomo policy routes (used by systemd)."""
        as_root()
        core.routing_start()

    @routing_app.command("cleanup")
    def cleanup_command() -> None:
        """Remove Mihomo policy routes (used by systemd)."""
        as_root()
        core.routing_cleanup()

    @routing_app.command("purge")
    def purge_command(kind: Annotated[str, typer.Argument()] = "rules") -> None:
        """Remove stale legacy policy rules or a stale TUN device."""
        as_root()
        core.cleanup_runtime(kind)

    @app.command("tray")
    def tray_command() -> None:
        """Run the desktop tray (requires a graphical session)."""
        run_tray(core, settings_path)

    return app


def run_tray(core: MihomoCore, settings_path: Path | None = None) -> None:
    """Run the desktop tray (requires a graphical session)."""
    if not (os.environ.get("WAYLAND_DISPLAY") or os.environ.get("DISPLAY")):
        raise MihomoError("The tray requires a graphical desktop session")
    if os.geteuid() == 0:
        raise MihomoError("Run the tray as your desktop user, without sudo")

    # Keep GUI dependencies out of CLI startup and headless installations.
    from concurrent.futures import ThreadPoolExecutor
    try:
        from PyQt6.QtCore import QLockFile, QProcess, QProcessEnvironment, QTimer
        from PyQt6.QtGui import QActionGroup, QIcon
        from PyQt6.QtWidgets import (
            QApplication, QMenu, QStyle, QSystemTrayIcon,
        )
    except ImportError as error:
        raise MihomoError("Tray support is not installed on this host") from error

    application = QApplication(["mihomo-tray"])
    application.setQuitOnLastWindowClosed(False)
    lock = QLockFile(str(Path(os.environ["XDG_RUNTIME_DIR"]) / "mihomo-tray.lock"))
    lock.setStaleLockTime(0)
    if not lock.tryLock(0):
        raise MihomoError("Mihomo tray is already running")
    icon = QIcon.fromTheme(
        "network-workgroup",
        application.style().standardIcon(QStyle.StandardPixmap.SP_ComputerIcon),
    )
    indicator = QSystemTrayIcon(icon, application)
    indicator.setToolTip("Mihomo")
    menu = QMenu()
    status_action = menu.addAction("Mihomo: checking…")
    status_action.setEnabled(False)
    mode_menu = menu.addMenu("Mode")
    mode_group = QActionGroup(mode_menu)
    node_menu = menu.addMenu("Proxy node")
    routing_action = menu.addAction("Transparent routing")
    routing_action.setCheckable(True)
    menu.addSeparator()
    process = QProcess(application)
    process.setProcessChannelMode(QProcess.ProcessChannelMode.MergedChannels)
    process.setStandardInputFile(QProcess.nullDevice())
    process_environment = QProcessEnvironment.systemEnvironment()
    process_environment.insert("NO_COLOR", "1")
    process_environment.insert("TERM", "dumb")
    process.setProcessEnvironment(process_environment)
    next_refresh = 0.0

    pending_action = None
    pending_status = None
    process_pending = False
    process_error_text = None
    process_output = bytearray()

    def busy() -> bool:
        return pending_action is not None or process_pending

    def run_privileged(*args: str) -> None:
        nonlocal process_pending, process_error_text
        # Privileged mutations use the CLI as a process boundary for polkit.
        if busy():
            return
        if settings_path is None and core.settings != Settings():
            indicator.showMessage("Mihomo", "Privilege escalation requires a settings file for custom settings")
            return
        menu.setEnabled(False)
        process_pending = True
        process_error_text = None
        process_output.clear()
        executable = str(Path(sys.argv[0]).resolve())
        process.start(
            core.settings.executable("pkexec"),
            ["--disable-internal-agent", sys.executable, executable,
             *configured_arguments(list(args), settings_path)],
        )

    def run_operation(operation, *args) -> None:
        nonlocal pending_action
        if busy():
            return
        menu.setEnabled(False)
        pending_action = executor.submit(operation, *args)

    def action_complete() -> None:
        nonlocal next_refresh, pending_status
        menu.setEnabled(True)
        # Discard a snapshot taken before the mutation finished.
        pending_status = None
        next_refresh = 0

    def read_process_output() -> None:
        process_output.extend(bytes(process.readAllStandardOutput()))
        del process_output[:-6000]

    def process_complete(error: str | None = None) -> None:
        nonlocal process_pending
        if not process_pending:
            return
        process_pending = False
        read_process_output()
        if error:
            output = process_output.decode(errors="replace").strip()[-1500:]
            indicator.showMessage(
                "Mihomo: operation failed", output or error,
                QSystemTrayIcon.MessageIcon.Warning,
            )
        action_complete()

    def finished(code: int, status: object) -> None:
        # exitCode is only meaningful for NormalExit. Crashes also emit
        # errorOccurred; finish and report the operation exactly once here.
        error = process_error_text
        if status == QProcess.ExitStatus.CrashExit:
            error = error or process.errorString()
        elif code != 0:
            error = error or f"Exit code {code}"
        process_complete(error)

    def process_error(error: object) -> None:
        nonlocal process_error_text
        process_error_text = process.errorString()
        # FailedToStart has no finished signal. Other errors can occur while
        # the child is still running, so keep the menu locked until it exits.
        if error == QProcess.ProcessError.FailedToStart:
            process_complete(process_error_text)

    process.readyReadStandardOutput.connect(read_process_output)
    process.finished.connect(finished)
    process.errorOccurred.connect(process_error)
    for value in MODES:
        action = mode_menu.addAction(value)
        action.setCheckable(True)
        mode_group.addAction(action)
        action.triggered.connect(
            lambda _checked=False, value=value: run_privileged("mode", value)
        )
    routing_action.triggered.connect(
        lambda checked: run_privileged("routing", "enable" if checked else "disable")
    )
    menu.addAction("Reload configuration").triggered.connect(
        lambda: run_privileged("reload")
    )
    menu.addAction("Close connections").triggered.connect(
        lambda: run_operation(core.close_connections)
    )
    menu.addSeparator()
    menu.addAction("Quit tray").triggered.connect(application.quit)

    def update_menu(state: MihomoStatus) -> None:
        mode = state.mode
        proxy = state.proxy
        status_action.setText(f"Mihomo: {mode}" if mode else "Mihomo: unavailable")
        selected = proxy.selected if proxy is not None else "(none)"
        indicator.setToolTip(state.error or f"Mihomo: {mode} · {selected}")
        routing_action.setChecked(state.routing_active)
        mode_menu.setEnabled(mode is not None)
        for action in mode_group.actions():
            action.setChecked(action.text() == mode)
        node_menu.clear()
        node_group = QActionGroup(node_menu)
        for name in proxy.nodes if proxy is not None else ():
            action = node_menu.addAction(name.replace("&", "&&"))
            action.setCheckable(True)
            action.setChecked(name == selected)
            node_group.addAction(action)
            action.triggered.connect(
                lambda _checked=False, name=name: run_operation(core.select_node, name)
            )
        node_menu.setEnabled(bool(node_group.actions()))
        # Parent ownership keeps the group alive until the next menu update.
        for group in node_menu.findChildren(QActionGroup):
            if group is not node_group:
                group.deleteLater()

    with ExitStack() as cleanup:
        # Ctrl-C must terminate even if a worker is blocked. KeyboardInterrupt
        # raised inside a Qt callback does not unwind QApplication.exec().
        previous_sigint = signal.signal(signal.SIGINT, signal.SIG_DFL)
        cleanup.callback(signal.signal, signal.SIGINT, previous_sigint)
        executor = cleanup.enter_context(ThreadPoolExecutor(max_workers=1))

        def refresh() -> None:
            nonlocal pending_action, pending_status, next_refresh
            if pending_action is not None and pending_action.done():
                try:
                    pending_action.result()
                except MihomoError as error:
                    indicator.showMessage(
                        "Mihomo: operation failed", str(error),
                        QSystemTrayIcon.MessageIcon.Warning,
                    )
                pending_action = None
                action_complete()
            if busy() or menu.isVisible():
                return
            if pending_status is not None and pending_status.done():
                try:
                    update_menu(pending_status.result())
                except MihomoError as error:
                    status_action.setText(f"Mihomo: {error}")
                pending_status = None
            if pending_status is None and time.monotonic() >= next_refresh:
                pending_status = executor.submit(core.get_status)
                next_refresh = time.monotonic() + 10

        timer = QTimer(application)
        timer.timeout.connect(refresh)
        timer.start(250)
        indicator.setContextMenu(menu)
        indicator.show()
        refresh()
        try:
            application.exec()
        finally:
            timer.stop()


def main() -> int:
    from rich.console import Console

    console = Console()
    try:
        create_cli(console=console)(prog_name="mihomo-ctl")
    except MihomoError as error:
        console.print(f"[bold red]mihomo-ctl:[/] {error}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
