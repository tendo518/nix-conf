"""Small Mihomo controller and policy-routing CLI.

The subscription URL is kept in a host-bound systemd credential. ``init``
only accepts it via a hidden prompt and never prints the runtime config.
"""

from __future__ import annotations

import json
import os
import pwd
import grp
import re
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Annotated

from rich.console import Console
from rich.panel import Panel
from rich.prompt import Prompt
from rich.table import Table
from rich.text import Text
import typer


CONFIG_DIR = Path("/etc/mihomo")
CONFIG_PATH = CONFIG_DIR / "config.yaml"
STATE_DIR = Path("/var/lib/mihomo")
SUBSCRIPTIONS_DIR = STATE_DIR / "subscriptions"
ACTIVE_SUBSCRIPTION_PATH = STATE_DIR / "active-subscription"
ROUTING_STATE_DIR = Path("/run/mihomo-routing")
ROUTING_STATE_FILE = ROUTING_STATE_DIR / "rules"
CONTROLLER = "http://127.0.0.1:9090"
TABLE = "2023"
TUN = "mihomo"
SUDO = "/run/wrappers/bin/sudo"
TEMPLATE_PATH = "@MIHOMO_TEMPLATE_PATH@"
SYSTEMD_CREDS = "@SYSTEMD_CREDS@"
console = Console()
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


class MihomoError(RuntimeError):
    """A user-facing command failure."""


def success(message: str) -> None:
    console.print(f"[bold green]✓[/] {message}")


def info(message: str) -> None:
    console.print(f"[cyan]•[/] {message}")


def warning(message: str) -> None:
    console.print(f"[yellow]![/] {message}")


def service_state(active: bool) -> Text:
    return Text("active" if active else "inactive", style="green" if active else "red")


def command(
    *args: str, check: bool = True, capture: bool = False
) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(
            list(args),
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


def command_output(*args: str, check: bool = True) -> str:
    return command(*args, check=check, capture=True).stdout


def as_root() -> None:
    if os.geteuid() != 0:
        if not os.path.exists(SUDO):
            raise MihomoError(
                f"Root privileges are required, but sudo was not found: {SUDO}"
            )
        os.execv(SUDO, [SUDO, sys.argv[0], *sys.argv[1:]])


def require_config() -> None:
    if not CONFIG_PATH.is_file() or CONFIG_PATH.stat().st_size == 0:
        raise MihomoError(
            f"Mihomo config is missing: {CONFIG_PATH}\n"
            "Run: sudo mihomo-ctl subscription init"
        )


def api(path: str, method: str = "GET", payload: dict | None = None) -> object:
    data = None
    headers = {}
    if payload is not None:
        data = json.dumps(payload).encode()
        headers["Content-Type"] = "application/json"
    request = urllib.request.Request(
        f"{CONTROLLER}{path}", data=data, headers=headers, method=method
    )
    try:
        with urllib.request.urlopen(request, timeout=5) as response:
            raw = response.read()
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


def controller_check() -> None:
    api("/version")


def proxy_provider_names() -> list[str]:
    data = api("/providers/proxies")
    providers = data.get("providers", {}) if isinstance(data, dict) else {}
    return sorted(providers)


def rule_provider_names() -> list[str]:
    data = api("/providers/rules")
    providers = data.get("providers", {}) if isinstance(data, dict) else {}
    return sorted(providers)


def selected_node(group: str = "PROXY") -> str:
    data = api(f"/proxies/{urllib.parse.quote(group, safe='')}")
    return (
        str(data.get("now", "(none)"))
        if isinstance(data, dict)
        else "(none)"
    )


def validate_subscription_url(url: str) -> None:
    if not re.match(r"^https?://", url):
        raise MihomoError("Subscription URL must start with http:// or https://")
    if any(character.isspace() for character in url):
        raise MihomoError("Subscription URL must not contain whitespace")


def credential_command(*args: str, input_text: str | None = None) -> str:
    try:
        result = subprocess.run(
            [SYSTEMD_CREDS, *args],
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


def validate_subscription_name(name: str) -> None:
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,63}", name):
        raise MihomoError(
            "Subscription name must use only letters, digits, dot, underscore, "
            "or hyphen (maximum 64 characters)"
        )


def subscription_credential(name: str) -> Path:
    validate_subscription_name(name)
    return SUBSCRIPTIONS_DIR / f"{name}.cred"


def credential_name(name: str) -> str:
    return f"mihomo-subscription-{name}"


def save_subscription(name: str, url: str) -> None:
    SUBSCRIPTIONS_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)
    credential_path = subscription_credential(name)
    fd, temporary = tempfile.mkstemp(
        prefix=f"{name}.", suffix=".cred", dir=SUBSCRIPTIONS_DIR
    )
    os.close(fd)
    temporary_path = Path(temporary)
    try:
        credential_command(
            "encrypt",
            "--with-key=host",
            f"--name={credential_name(name)}",
            "-",
            str(temporary_path),
            input_text=f"{url}\n",
        )
        os.chown(temporary_path, 0, 0)
        os.chmod(temporary_path, 0o600)
        os.replace(temporary_path, credential_path)
    finally:
        temporary_path.unlink(missing_ok=True)


def load_subscription(name: str) -> str:
    credential_path = subscription_credential(name)
    if not credential_path.is_file():
        raise MihomoError(f"Subscription does not exist: {name}")
    url = credential_command(
        "decrypt",
        f"--name={credential_name(name)}",
        str(credential_path),
        "-",
    ).strip()
    validate_subscription_url(url)
    return url


def active_subscription() -> str | None:
    if not ACTIVE_SUBSCRIPTION_PATH.is_file():
        return None
    name = ACTIVE_SUBSCRIPTION_PATH.read_text().strip()
    validate_subscription_name(name)
    if not subscription_credential(name).is_file():
        raise MihomoError(f"Active subscription does not exist: {name}")
    return name


def set_active_subscription(name: str) -> None:
    subscription_credential(name)
    STATE_DIR.mkdir(mode=0o750, parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix="active-subscription.", dir=STATE_DIR)
    temporary_path = Path(temporary)
    try:
        with os.fdopen(fd, "w") as output:
            output.write(f"{name}\n")
        os.chown(temporary_path, 0, 0)
        os.chmod(temporary_path, 0o600)
        os.replace(temporary_path, ACTIVE_SUBSCRIPTION_PATH)
    finally:
        temporary_path.unlink(missing_ok=True)


def subscription_names() -> list[str]:
    if not SUBSCRIPTIONS_DIR.is_dir():
        return []
    return sorted(
        path.stem
        for path in SUBSCRIPTIONS_DIR.glob("*.cred")
        if re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,63}", path.stem)
    )


def write_config(template: str, url: str) -> None:
    rendered = template.replace("$URL", url)
    fd, temporary = tempfile.mkstemp(prefix="config.yaml.", dir=CONFIG_DIR)
    temporary_path = Path(temporary)
    try:
        with os.fdopen(fd, "w") as output:
            output.write(rendered)
        os.chown(temporary_path, 0, grp.getgrnam("mihomo").gr_gid)
        os.chmod(temporary_path, 0o640)
        os.replace(temporary_path, CONFIG_PATH)
    finally:
        temporary_path.unlink(missing_ok=True)


def apply_subscription(template: str, name: str) -> None:
    url = load_subscription(name)
    set_active_subscription(name)
    write_config(template, url)
    routing_active = (
        command(
            "systemctl",
            "is-active",
            "--quiet",
            "mihomo-routing.service",
            check=False,
        ).returncode
        == 0
    )
    cleanup_runtime("tun")
    command("systemctl", "restart", "mihomo.service")
    if routing_active:
        command("systemctl", "restart", "mihomo-routing.service")


def init_runtime(template: str) -> None:
    as_root()
    CONFIG_DIR.mkdir(mode=0o750, parents=True, exist_ok=True)
    os.chown(CONFIG_DIR, 0, grp.getgrnam("mihomo").gr_gid)
    os.chmod(CONFIG_DIR, 0o750)

    name = active_subscription()
    if name is None:
        name = typer.prompt("Subscription name", default="default")
        validate_subscription_name(name)
        url = typer.prompt("Subscription URL", hide_input=True)
        validate_subscription_url(url)
        save_subscription(name, url)
    else:
        if typer.confirm(f"Replace saved subscription URL for '{name}'?", default=False):
            url = typer.prompt("Subscription URL", hide_input=True)
            validate_subscription_url(url)
            save_subscription(name, url)
        else:
            info(f"Keeping saved subscription '{name}'")

    apply_subscription(template, name)
    success(
        f"Runtime config created at {CONFIG_PATH}; "
        "mihomo.service restarted."
    )


def add_subscription(name: str) -> None:
    as_root()
    credential_path = subscription_credential(name)
    if credential_path.exists():
        raise MihomoError(f"Subscription already exists: {name}; use 'subscription edit'")
    url = typer.prompt("Subscription URL", hide_input=True)
    validate_subscription_url(url)
    save_subscription(name, url)
    success(f"Saved encrypted subscription '{name}'")


def edit_subscription(template: str, name: str) -> None:
    as_root()
    if not subscription_credential(name).is_file():
        raise MihomoError(f"Subscription does not exist: {name}")
    url = typer.prompt("Subscription URL", hide_input=True)
    validate_subscription_url(url)
    save_subscription(name, url)
    if active_subscription() == name:
        apply_subscription(template, name)
        success(f"Updated and applied subscription '{name}'")
    else:
        success(f"Updated encrypted subscription '{name}'")


def remove_subscription(name: str) -> None:
    as_root()
    credential_path = subscription_credential(name)
    if not credential_path.is_file():
        raise MihomoError(f"Subscription does not exist: {name}")
    if active_subscription() == name:
        raise MihomoError(
            f"Cannot remove active subscription '{name}'; switch subscriptions first"
        )
    if not typer.confirm(f"Remove saved subscription '{name}'?", default=False):
        info("Subscription unchanged")
        return
    credential_path.unlink()
    success(f"Removed encrypted subscription '{name}'")


def switch_subscription(template: str, name: str) -> None:
    as_root()
    apply_subscription(template, name)
    success(f"Switched to subscription '{name}'")


def list_subscriptions() -> None:
    as_root()
    active = active_subscription()
    names = subscription_names()
    if not names:
        warning("No saved subscriptions; run: sudo mihomo-ctl subscription add <name>")
        return
    table = Table(title="Mihomo subscriptions", header_style="bold cyan")
    table.add_column("Name")
    table.add_column("Active", justify="center")
    for name in names:
        table.add_row(name, Text("●", style="bold green") if name == active else Text())
    console.print(table)


def rule_priorities(family: int, predicate) -> list[int]:
    output = command_output("ip", f"-{family}", "-o", "rule", "show")
    priorities = []
    for line in output.splitlines():
        match = re.match(r"\s*(\d+):", line)
        if match and predicate(line):
            priorities.append(int(match.group(1)))
    return sorted(set(priorities), reverse=True)


def delete_rules(family: int, priorities: list[int]) -> None:
    for priority in priorities:
        command(
            "ip", f"-{family}", "rule", "del", "priority", str(priority),
            check=False, capture=True,
        )


def flush_route_table(family: int, table: str) -> None:
    """Flush a route table when present without exposing an absent-table error."""
    command(
        "ip", f"-{family}", "route", "flush", "table", table,
        check=False, capture=True,
    )


def cleanup_owned_rules() -> None:
    def owned(line: str) -> bool:
        return (
            re.search(r"lookup 2023$", line) is not None
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

    delete_rules(4, rule_priorities(4, owned))
    flush_route_table(4, TABLE)
    ROUTING_STATE_FILE.unlink(missing_ok=True)


def cleanup_foreign_rules() -> None:
    def foreign(line: str) -> bool:
        return (
            re.search(r"iif mihomo", line, re.IGNORECASE) is not None
            or "lookup 2022" in line
            or "198.18.0.0/30" in line
        )

    for family in (4, 6):
        delete_rules(family, rule_priorities(family, foreign))
        flush_route_table(family, "2022")


def cleanup_runtime(kind: str = "rules") -> None:
    as_root()
    if kind not in {"rules", "tun"}:
        raise MihomoError("Usage: mihomo-ctl routing purge {rules|tun}")
    if kind == "tun":
        active = command(
            "systemctl", "is-active", "--quiet", "mihomo.service", check=False
        ).returncode == 0
        if not active:
            command(
                "ip", "link", "delete", "dev", "Mihomo",
                check=False, capture=True,
            )
            command(
                "ip", "link", "delete", "dev", "mihomo",
                check=False, capture=True,
            )
    cleanup_foreign_rules()


def wait_for_tun() -> None:
    for _ in range(30):
        if command(
            "ip", "link", "show", "dev", TUN, check=False, capture=True
        ).returncode == 0:
            return
        time.sleep(1)
    raise MihomoError(f"Mihomo TUN interface {TUN} did not appear")


def choose_base() -> int:
    output = command_output("ip", "-4", "rule", "show")
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


def routing_start() -> None:
    as_root()
    cleanup_owned_rules()
    cleanup_foreign_rules()
    wait_for_tun()
    uid = pwd.getpwnam("mihomo").pw_uid
    base = choose_base()
    ROUTING_STATE_DIR.mkdir(mode=0o755, parents=True, exist_ok=True)
    try:
        command(
            "ip", "-4", "route", "replace", "table", TABLE,
            "default", "dev", TUN,
        )
        command(
            "ip", "-4", "rule", "add", "priority", str(base),
            "uidrange", f"{uid}-{uid}", "lookup", "main",
        )
        command(
            "ip", "-4", "rule", "add", "priority", str(base + 100),
            "ipproto", "udp", "dport", "53", "lookup", "main",
        )
        command(
            "ip", "-4", "rule", "add", "priority", str(base + 101),
            "ipproto", "tcp", "dport", "53", "lookup", "main",
        )
        # Never route these address families through the TUN: multicast
        # (mDNS/SSDP/UPnP), the limited broadcast (DHCP, LAN broadcasts) and
        # link-local traffic are LAN-only and must stay on a real interface.
        command(
            "ip", "-4", "rule", "add", "priority", str(base + 120),
            "to", "224.0.0.0/4", "lookup", "main",
        )
        command(
            "ip", "-4", "rule", "add", "priority", str(base + 121),
            "to", "255.255.255.255", "lookup", "main",
        )
        command(
            "ip", "-4", "rule", "add", "priority", str(base + 122),
            "to", "169.254.0.0/16", "lookup", "main",
        )
        command(
            "ip", "-4", "rule", "add", "priority", str(base + 200),
            "lookup", "main", "suppress_prefixlength", "0",
        )
        command(
            "ip", "-4", "rule", "add", "priority", str(base + 1000),
            "lookup", TABLE,
        )
        ROUTING_STATE_FILE.write_text(f"{base}\n")
    except Exception:
        cleanup_owned_rules()
        raise


def routing_cleanup() -> None:
    as_root()
    cleanup_owned_rules()


def select_node(name: str | None) -> None:
    controller_check()
    old = selected_node()
    data = api("/proxies/PROXY")
    nodes = data.get("all", []) if isinstance(data, dict) else []
    if name is None:
        if not nodes:
            raise MihomoError("No nodes are available in PROXY")
        table = Table(title="PROXY nodes", header_style="bold cyan")
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
    api("/proxies/PROXY", "PUT", {"name": name})
    console.print(
        Text.assemble(
            (old, "dim"),
            (" → ", "cyan"),
            (name, "bold green"),
        )
    )


def update_providers(template: str, provider: str | None, update_all: bool) -> None:
    as_root()
    name = active_subscription()
    if name is None:
        raise MihomoError(
            "No active subscription; run: sudo mihomo-ctl subscription init"
        )
    apply_subscription(template, name)
    controller_check()
    providers = (
        proxy_provider_names() if update_all else [provider or "subscription"]
    )
    for item in providers:
        info(f"Updating provider: {item}")
        api(f"/providers/proxies/{urllib.parse.quote(item, safe='')}", "PUT")
    success("Proxy provider update complete")


def update_rules() -> None:
    controller_check()
    providers = rule_provider_names()
    if not providers:
        warning("No rule providers configured")
        return
    for provider in providers:
        info(f"Updating rule provider: {provider}")
        api(f"/providers/rules/{urllib.parse.quote(provider, safe='')}", "PUT")
    success("Rule provider update complete")


def test_providers() -> None:
    controller_check()
    providers = proxy_provider_names()
    if not providers:
        raise MihomoError("No proxy providers configured")
    for provider in providers:
        info(f"Running health check: {provider}")
        api(
            f"/providers/proxies/{urllib.parse.quote(provider, safe='')}"
            "/healthcheck"
        )
    time.sleep(1)
    results = []
    for provider in providers:
        data = api(
            f"/providers/proxies/{urllib.parse.quote(provider, safe='')}"
        )
        for proxy in data.get("proxies", []) if isinstance(data, dict) else []:
            history = proxy.get("history", [])
            delay = history[-1].get("delay", 999999) if history else 999999
            results.append(
                (delay, proxy.get("alive", False), proxy.get("name", ""))
            )
    table = Table(title="Proxy health", header_style="bold cyan")
    table.add_column("Delay", justify="right")
    table.add_column("Status", justify="center")
    table.add_column("Node", min_width=24)
    for delay, alive, name in sorted(results):
        delay_text = "—" if delay >= 999999 else f"{delay} ms"
        status = Text("UP", style="bold green") if alive else Text(
            "DOWN", style="bold red"
        )
        table.add_row(delay_text, status, Text(str(name)))
    console.print(table)


def show_status() -> None:
    daemon_active = command(
        "systemctl", "is-active", "--quiet", "mihomo.service", check=False
    ).returncode == 0
    routing_active = command(
        "systemctl", "is-active", "--quiet", "mihomo-routing.service",
        check=False,
    ).returncode == 0
    table = Table.grid(padding=(0, 2))
    table.add_column(style="bold")
    table.add_column()
    table.add_row("mihomo.service", service_state(daemon_active))
    table.add_row("mihomo-routing.service", service_state(routing_active))
    try:
        controller_check()
        config = api("/configs")
        mode = (
            config.get("mode", "unknown")
            if isinstance(config, dict)
            else "unknown"
        )
        table.add_row("controller", Text("reachable", style="green"))
        table.add_row("mode", Text(str(mode), style="cyan"))
        table.add_row("selected", Text(selected_node(), style="bold green"))
        table.add_row("providers", str(len(proxy_provider_names())))
    except MihomoError:
        table.add_row("controller", Text("unreachable", style="red"))
    console.print(Panel(table, title="Mihomo status", border_style="cyan"))


def show_routes() -> None:
    sections = (
        ("IPv4 policy rules", ("ip", "-4", "rule", "show")),
        (f"IPv4 Mihomo table ({TABLE})", ("ip", "-4", "route", "show", "table", TABLE)),
        ("IPv4 all routes", ("ip", "-4", "route", "show", "table", "all")),
    )
    for title, args in sections:
        result = command(*args, check=False, capture=True)
        output = (result.stdout or result.stderr).strip() or "(empty)"
        console.print(
            Panel(
                Text(output),
                title=title,
                border_style="cyan" if result.returncode == 0 else "yellow",
            )
        )


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


def show_connections() -> None:
    controller_check()
    data = api("/connections")
    if not isinstance(data, dict):
        raise MihomoError("Mihomo controller returned an invalid connection snapshot")
    connections = data.get("connections", [])
    if not isinstance(connections, list):
        raise MihomoError("Mihomo controller returned an invalid connection list")
    table = Table(title="Mihomo connections", header_style="bold cyan")
    table.add_column("Protocol", no_wrap=True)
    table.add_column("Source", no_wrap=True)
    table.add_column("Destination", min_width=24, max_width=36, overflow="ellipsis")
    table.add_column("Process", max_width=20, overflow="ellipsis")
    table.add_column("Rule", min_width=14, max_width=24, overflow="ellipsis")
    table.add_column("Proxy", min_width=14, max_width=24, overflow="ellipsis")
    table.add_column("Down", justify="right")
    table.add_column("Up", justify="right")
    for connection in connections:
        if not isinstance(connection, dict):
            continue
        metadata = connection.get("metadata", {})
        metadata = metadata if isinstance(metadata, dict) else {}
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
        chains = connection.get("chains", [])
        proxy = str(chains[-1]) if isinstance(chains, list) and chains else "—"
        process_path = metadata.get("processPath")
        process = Path(str(process_path)).name if process_path else "—"
        table.add_row(
            str(metadata.get("network") or metadata.get("type") or "—"),
            source or "—",
            destination,
            process,
            rule,
            proxy,
            format_bytes(connection.get("download")),
            format_bytes(connection.get("upload")),
        )
    console.print(table)
    info(
        f"{len(connections)} active; total down {format_bytes(data.get('downloadTotal'))}, "
        f"up {format_bytes(data.get('uploadTotal'))}"
    )


def close_connections() -> None:
    controller_check()
    api("/connections", "DELETE")
    success("Closed all Mihomo connections")


def run_doctor() -> None:
    as_root()
    failures = 0
    checks: list[tuple[str, bool]] = []
    notes: list[str] = []

    def check(label: str, passed: bool) -> None:
        nonlocal failures
        checks.append((label, passed))
        if not passed:
            failures += 1

    check(
        "mihomo service active",
        command(
            "systemctl", "is-active", "--quiet", "mihomo.service", check=False
        ).returncode == 0,
    )
    check(
        "routing service active",
        command(
            "systemctl", "is-active", "--quiet", "mihomo-routing.service",
            check=False,
        ).returncode == 0,
    )
    try:
        controller_check()
        controller_ok = True
    except MihomoError:
        controller_ok = False
    check("controller reachable", controller_ok)
    check(
        "TUN interface exists",
        command(
            "ip", "link", "show", "dev", TUN,
            check=False,
            capture=True,
        ).returncode == 0,
    )
    check(
        "config exists outside /nix/store",
        CONFIG_PATH.is_file()
        and not str(CONFIG_PATH).startswith("/nix/store/"),
    )
    try:
        stat = CONFIG_PATH.stat()
        owner = pwd.getpwuid(stat.st_uid).pw_name
        group = grp.getgrgid(stat.st_gid).gr_name
        check(
            "config permissions are root:mihomo 0640",
            f"{owner} {group} {stat.st_mode & 0o777:o}" == "root mihomo 640",
        )
    except FileNotFoundError:
        check("config permissions are root:mihomo 0640", False)

    if controller_ok:
        providers = api("/providers/proxies")
        count = sum(
            len(value.get("proxies", []))
            for value in providers.get("providers", {}).values()
        )
        check(f"provider node count > 0 ({count})", count > 0)
        notes.append(f"Selected node: {selected_node()}")
    else:
        check("provider node count (controller unavailable)", False)

    rules = command_output("ip", "-4", "rule", "show")
    table_result = command(
        "ip", "-4", "route", "show", "table", TABLE,
        check=False,
        capture=True,
    )
    table_routes = table_result.stdout
    table_exists = table_result.returncode == 0
    if not table_exists:
        notes.append(f"Mihomo routing table {TABLE} is unavailable")
    catchall = re.search(r"^\s*\d+:.*lookup 2023$", rules, re.MULTILINE)
    check(
        "table 2023 contains Mihomo default route",
        bool(
            table_exists
            and catchall
            and re.search(r"^default dev mihomo", table_routes, re.MULTILINE)
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
        tailscale = [
            int(match.group(1))
            for match in re.finditer(
                r"^\s*(\d+):.*(?:fwmark 0x80000|lookup 52)",
                rules,
                re.MULTILINE,
            )
        ]
        if tailscale:
            check(
                "recognized Tailscale rules precede Mihomo catch-all",
                max(tailscale) < catchall_priority,
            )
        else:
            notes.append("No recognizable Tailscale policy rules found")
    else:
        check("Mihomo catch-all policy rule exists", False)
    check(
        "DNS bypass rules exist",
        "ipproto udp dport 53 lookup main" in rules
        and "ipproto tcp dport 53 lookup main" in rules,
    )
    listeners = command_output("ss", "-lntup", check=False)
    check(
        "Mihomo is not listening on port 53",
        not re.search(r"mihomo.*:53|:53.*mihomo", listeners),
    )

    table = Table(title="Mihomo doctor", header_style="bold cyan")
    table.add_column("Result", justify="center", no_wrap=True)
    table.add_column("Check")
    for label, passed in checks:
        result = Text("PASS", style="bold green") if passed else Text(
            "FAIL", style="bold red"
        )
        table.add_row(result, label)
    console.print(table)
    for note in notes:
        info(note)

    for variable in (
        "MIHOMO_TEST_TS_IP",
        "MIHOMO_TEST_SUBNET_IP",
        "MIHOMO_TEST_LAN_IP",
        "MIHOMO_TEST_CAMPUS_IP",
    ):
        value = os.environ.get(variable)
        if value:
            print(f"Route check {variable}={value}:")
            command("ip", "-4", "route", "get", value)
    if failures:
        raise MihomoError(f"{failures} Mihomo doctor check(s) failed")


def set_mode(mode: str | None) -> None:
    controller_check()
    if mode is None:
        config = api("/configs")
        console.print(
            config.get("mode", "unknown")
            if isinstance(config, dict)
            else "unknown"
        )
        return
    if mode not in {"rule", "global", "direct", "script"}:
        raise MihomoError("Mode must be one of: rule, global, direct, script")
    api("/configs", "PUT", {"mode": mode})
    success(f"Mihomo mode: {mode}")


def service_invocation_id() -> str:
    result = command_output(
        "systemctl", "show", "--property=InvocationID", "--value",
        "mihomo.service",
    ).strip()
    if not result:
        raise MihomoError(
            "Mihomo service is not running; no current invocation logs exist"
        )
    return result


def show_log(ctx: typer.Context) -> None:
    invocation_id = service_invocation_id()
    process = subprocess.Popen(
        [
            "journalctl",
            "--unit=mihomo.service",
            "--no-pager",
            *ctx.args,
            "--output=json",
            f"_SYSTEMD_INVOCATION_ID={invocation_id}",
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
            if isinstance(timestamp, str) and timestamp.isdigit():
                seconds = int(timestamp) / 1_000_000
                time_text = time.strftime("%H:%M:%S", time.localtime(seconds))
            else:
                time_text = "—"
            priority = str(record.get("PRIORITY", "6"))
            level, style = {
                "0": ("EMERG", "bold red"),
                "1": ("ALERT", "bold red"),
                "2": ("CRIT", "bold red"),
                "3": ("ERROR", "red"),
                "4": ("WARN", "yellow"),
                "5": ("NOTICE", "cyan"),
                "6": ("INFO", "green"),
                "7": ("DEBUG", "dim"),
            }.get(priority, ("LOG", "white"))
            source = str(record.get("SYSLOG_IDENTIFIER", "mihomo"))
            message = str(record.get("MESSAGE", ""))
            console.print(
                Text.assemble(
                    (f"{time_text} ", "dim"),
                    (f"{level:<6} ", style),
                    (f"{source}: ", "cyan"),
                    message,
                )
            )
    except KeyboardInterrupt:
        process.terminate()
    stderr = process.stderr.read() if process.stderr is not None else ""
    if process.wait() and stderr.strip():
        raise MihomoError(f"Could not read Mihomo logs: {stderr.strip()}")


def template() -> str:
    return Path(os.environ.get("MIHOMO_TEMPLATE_PATH", TEMPLATE_PATH)).read_text()


@subscription_app.command()
def init() -> None:
    """Create the runtime config from the active encrypted subscription."""
    init_runtime(template())


@proxy_app.command()
def node(name: Annotated[str | None, typer.Argument()] = None) -> None:
    """Show proxy nodes or select NAME."""
    select_node(name)


@subscription_app.command()
def update(
    provider: Annotated[str | None, typer.Argument()] = None,
    update_all: Annotated[bool, typer.Option("--all")] = False,
) -> None:
    """Rebuild from the active subscription and refresh proxy providers."""
    update_providers(template(), provider, update_all)


@proxy_app.command("update-rules")
def update_rules_command() -> None:
    """Refresh all rule providers."""
    update_rules()


@proxy_app.command("test")
def test_command() -> None:
    """Run proxy-provider health checks."""
    test_providers()


@app.command()
def status() -> None:
    """Show Mihomo and routing status."""
    show_status()


@routing_app.command()
def routes() -> None:
    """Show policy-routing tables and rules."""
    show_routes()


@proxy_app.command()
def connections() -> None:
    """List active connections."""
    show_connections()


@proxy_app.command("close-connections")
def close_connections_command() -> None:
    """Close all active Mihomo connections."""
    close_connections()


@routing_app.command("enable")
def routing_enable() -> None:
    """Enable transparent routing."""
    as_root()
    require_config()
    command("systemctl", "start", "mihomo.service")
    command("systemctl", "start", "mihomo-routing.service")
    success("Mihomo transparent routing enabled")


@routing_app.command("disable")
def routing_disable() -> None:
    """Disable transparent routing while keeping Mihomo running."""
    as_root()
    command("systemctl", "stop", "mihomo-routing.service")
    success("Mihomo transparent routing disabled; mihomo.service remains running.")


@app.command()
def reload() -> None:
    """Validate and reload the current runtime configuration."""
    as_root()
    require_config()
    info("Validating Mihomo configuration")
    command("mihomo", "-t", "-d", str(STATE_DIR), "-f", str(CONFIG_PATH))
    info("Reloading Mihomo through the local controller")
    api("/configs?force=true", "PUT", {"path": str(CONFIG_PATH), "payload": ""})
    command("systemctl", "restart", "mihomo-routing.service")
    run_doctor()


@app.command(
    context_settings={"allow_extra_args": True, "ignore_unknown_options": True}
)
def log(ctx: typer.Context) -> None:
    """Show the current Mihomo service invocation; pass options to journalctl."""
    show_log(ctx)


@app.command()
def config() -> None:
    """Show runtime-config metadata without exposing its contents."""
    as_root()
    table = Table.grid(padding=(0, 2))
    table.add_column(style="bold")
    table.add_column()
    table.add_row("Runtime config", str(CONFIG_PATH))
    if CONFIG_PATH.exists():
        stat = CONFIG_PATH.stat()
        table.add_row("Owner", pwd.getpwuid(stat.st_uid).pw_name)
        table.add_row("Group", grp.getgrgid(stat.st_gid).gr_name)
        table.add_row("Mode", f"{stat.st_mode & 0o777:04o}")
    else:
        table.add_row("Status", Text("not created", style="yellow"))
    console.print(Panel(table, title="Mihomo runtime config", border_style="cyan"))
    info("Contents are not printed because this file contains the subscription URL")


@app.command()
def doctor() -> None:
    """Check Mihomo configuration, service, and routing health."""
    run_doctor()


@proxy_app.command()
def mode(value: Annotated[str | None, typer.Argument()] = None) -> None:
    """Show or set the Mihomo mode."""
    set_mode(value)


@routing_app.command("start")
def routing_start_command() -> None:
    """Install Mihomo policy routes (used by systemd)."""
    routing_start()


@routing_app.command("cleanup")
def routing_cleanup_command() -> None:
    """Remove Mihomo policy routes (used by systemd)."""
    routing_cleanup()


@routing_app.command("purge")
def routing_purge_command(kind: Annotated[str, typer.Argument()] = "rules") -> None:
    """Remove stale legacy policy rules or a stale TUN device."""
    cleanup_runtime(kind)


@subscription_app.command("add")
def subscription_add(name: Annotated[str, typer.Argument()]) -> None:
    """Create or replace a named encrypted subscription."""
    add_subscription(name)


@subscription_app.command("switch")
def subscription_switch(name: Annotated[str, typer.Argument()]) -> None:
    """Activate NAME and restart Mihomo with it."""
    switch_subscription(template(), name)


@subscription_app.command("edit")
def subscription_edit(name: Annotated[str, typer.Argument()]) -> None:
    """Replace NAME's URL; apply it immediately when it is active."""
    edit_subscription(template(), name)


@subscription_app.command("remove")
def subscription_remove(name: Annotated[str, typer.Argument()]) -> None:
    """Remove a non-active encrypted subscription after confirmation."""
    remove_subscription(name)


@subscription_app.command("list")
def subscription_list() -> None:
    """List saved subscription names without exposing URLs."""
    list_subscriptions()


if __name__ == "__main__":
    try:
        app(prog_name="mihomo-ctl")
    except MihomoError as error:
        console.print(f"[bold red]mihomo-ctl:[/] {error}")
        raise SystemExit(1)
