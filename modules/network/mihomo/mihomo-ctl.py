"""Small Mihomo controller and policy-routing CLI.

The runtime subscription URL is accepted only by ``init`` via a hidden
prompt.  This program never prints the runtime configuration.
"""

from __future__ import annotations

import argparse
import getpass
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


CONFIG_DIR = Path("/etc/mihomo")
CONFIG_PATH = CONFIG_DIR / "config.yaml"
STATE_DIR = Path("/var/lib/mihomo")
ROUTING_STATE_DIR = Path("/run/mihomo-routing")
ROUTING_STATE_FILE = ROUTING_STATE_DIR / "rules"
CONTROLLER = "http://127.0.0.1:9090"
TABLE = "2023"
TUN = "mihomo"
SUDO = "/run/wrappers/bin/sudo"
TEMPLATE_PATH = "@MIHOMO_TEMPLATE_PATH@"


class MihomoError(RuntimeError):
    """A user-facing command failure."""


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
            "Run: sudo mihomo-ctl init"
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


def init_runtime(template: str) -> None:
    as_root()
    if sys.argv[2:]:
        raise MihomoError(
            "Usage: mihomo-ctl init\n"
            "Enter the subscription URL at the prompt; "
            "do not pass it as an argument."
        )

    CONFIG_DIR.mkdir(mode=0o750, parents=True, exist_ok=True)
    os.chown(CONFIG_DIR, 0, grp.getgrnam("mihomo").gr_gid)
    os.chmod(CONFIG_DIR, 0o750)

    url = getpass.getpass("Subscription URL: ")
    print(file=sys.stderr)
    if not re.match(r"^https?://", url):
        raise MihomoError(
            "Subscription URL must start with http:// or https://"
        )
    if any(character.isspace() for character in url):
        raise MihomoError("Subscription URL must not contain whitespace")

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

    cleanup("tun")
    print(
        f"Runtime config created at {CONFIG_PATH}; "
        "restarting mihomo.service."
    )
    command("systemctl", "restart", "mihomo.service")


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
            check=False,
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
                r"lookup main suppress_prefixlength 0$", line
            ) is not None
        )

    delete_rules(4, rule_priorities(4, owned))
    command("ip", "-4", "route", "flush", "table", TABLE, check=False)
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
        command(
            "ip", f"-{family}", "route", "flush", "table", "2022",
            check=False,
        )


def cleanup(kind: str = "rules") -> None:
    as_root()
    if kind not in {"rules", "tun"}:
        raise MihomoError("Usage: mihomo-ctl cleanup {rules|tun}")
    if kind == "tun":
        active = command(
            "systemctl", "is-active", "--quiet", "mihomo.service", check=False
        ).returncode == 0
        if not active:
            command("ip", "link", "delete", "dev", "Mihomo", check=False)
            command("ip", "link", "delete", "dev", "mihomo", check=False)
    cleanup_foreign_rules()


def wait_for_tun() -> None:
    for _ in range(30):
        if command(
            "ip", "link", "show", "dev", TUN, check=False
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


def node(name: str | None) -> None:
    controller_check()
    old = selected_node()
    data = api("/proxies/PROXY")
    nodes = data.get("all", []) if isinstance(data, dict) else []
    if name is None:
        if not nodes:
            raise MihomoError("No nodes are available in PROXY")
        for index, item in enumerate(nodes, 1):
            print(f"{index:3}: {item}")
        answer = input("Select node (Enter to cancel): ").strip()
        if not answer:
            return
        if not answer.isdigit() or not 1 <= int(answer) <= len(nodes):
            raise MihomoError("Invalid node selection")
        name = str(nodes[int(answer) - 1])
    api("/proxies/PROXY", "PUT", {"name": name})
    print(f"{old} -> {name}")


def update(provider: str | None, update_all: bool) -> None:
    controller_check()
    providers = (
        proxy_provider_names() if update_all else [provider or "subscription"]
    )
    for item in providers:
        print(f"Updating provider: {item}")
        api(f"/providers/proxies/{urllib.parse.quote(item, safe='')}", "PUT")


def update_rules() -> None:
    controller_check()
    providers = rule_provider_names()
    if not providers:
        print("No rule providers configured.")
        return
    for provider in providers:
        print(f"Updating rule provider: {provider}")
        api(f"/providers/rules/{urllib.parse.quote(provider, safe='')}", "PUT")


def test_providers() -> None:
    controller_check()
    providers = proxy_provider_names()
    if not providers:
        raise MihomoError("No proxy providers configured")
    for provider in providers:
        print(f"Running health check: {provider}", file=sys.stderr)
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
    for delay, alive, name in sorted(results):
        print(f"{delay:<8} {str(alive).lower():<6} {name}")


def status() -> None:
    daemon = command_output(
        "systemctl", "is-active", "mihomo.service", check=False
    ).strip()
    routing = command_output(
        "systemctl", "is-active", "mihomo-routing.service", check=False
    ).strip()
    print(f"mihomo.service: {daemon}")
    print(f"mihomo-routing.service: {routing}")
    try:
        controller_check()
        config = api("/configs")
        mode = (
            config.get("mode", "unknown")
            if isinstance(config, dict)
            else "unknown"
        )
        print(f"controller: reachable ({CONTROLLER})")
        print(f"mode: {mode}")
        print(f"selected: {selected_node()}")
        print(f"providers: {len(proxy_provider_names())}")
    except MihomoError:
        print(f"controller: unreachable ({CONTROLLER})")


def routes() -> None:
    print("IPv4 policy rules:")
    print(command_output("ip", "-4", "rule", "show"), end="")
    print("\nIPv4 Mihomo table (2023):")
    print(command_output("ip", "-4", "route", "show", "table", TABLE), end="")
    print("\nIPv4 all routes:")
    print(command_output("ip", "-4", "route", "show", "table", "all"), end="")


def doctor() -> None:
    as_root()
    failures = 0

    def check(label: str, passed: bool) -> None:
        nonlocal failures
        print(f"{'PASS' if passed else 'FAIL':5} {label}")
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
        command("ip", "link", "show", "dev", TUN, check=False).returncode == 0,
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
        print(f"INFO  selected node: {selected_node()}")
    else:
        check("provider node count (controller unavailable)", False)

    rules = command_output("ip", "-4", "rule", "show")
    table_routes = command_output("ip", "-4", "route", "show", "table", TABLE)
    catchall = re.search(r"^\s*\d+:.*lookup 2023$", rules, re.MULTILINE)
    check(
        "table 2023 contains Mihomo default route",
        bool(
            catchall
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
            print("INFO  no recognizable Tailscale policy rules found")
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
        print(
            config.get("mode", "unknown")
            if isinstance(config, dict)
            else "unknown"
        )
        return
    if mode not in {"rule", "global", "direct", "script"}:
        raise MihomoError("Mode must be one of: rule, global, direct, script")
    api("/configs", "PUT", {"mode": mode})
    print(f"Mihomo mode: {mode}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="mihomo-ctl")
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("init")
    node_parser = subparsers.add_parser("node")
    node_parser.add_argument("name", nargs="?")
    update_parser = subparsers.add_parser("update")
    update_parser.add_argument("provider", nargs="?")
    update_parser.add_argument("--all", action="store_true")
    subparsers.add_parser("update-rules")
    subparsers.add_parser("test")
    for name in (
        "status", "routes", "connections", "close", "on", "off", "reload",
        "config", "doctor",
    ):
        subparsers.add_parser(name)
    log_parser = subparsers.add_parser("log")
    log_parser.add_argument("args", nargs=argparse.REMAINDER)
    mode_parser = subparsers.add_parser("mode")
    mode_parser.add_argument(
        "mode", nargs="?", choices=("rule", "global", "direct", "script")
    )
    routing_parser = subparsers.add_parser("routing")
    routing_parser.add_argument("action", choices=("start", "cleanup"))
    cleanup_parser = subparsers.add_parser("cleanup")
    cleanup_parser.add_argument(
        "kind", choices=("rules", "tun"), nargs="?", default="rules"
    )
    return parser


def main() -> int:
    args = build_parser().parse_args()
    if args.command == "init":
        template_path = Path(
            os.environ.get("MIHOMO_TEMPLATE_PATH", TEMPLATE_PATH)
        )
        init_runtime(template_path.read_text())
    elif args.command == "node":
        node(args.name)
    elif args.command == "update":
        update(args.provider, args.all)
    elif args.command == "update-rules":
        update_rules()
    elif args.command == "test":
        test_providers()
    elif args.command == "status":
        status()
    elif args.command == "routes":
        routes()
    elif args.command == "connections":
        controller_check()
        print(json.dumps(api("/connections"), indent=2, ensure_ascii=False))
    elif args.command == "close":
        controller_check()
        api("/connections", "DELETE")
        print("Mihomo connections closed.")
    elif args.command == "on":
        as_root()
        require_config()
        command("systemctl", "start", "mihomo.service")
        command("systemctl", "start", "mihomo-routing.service")
        print("Mihomo transparent routing enabled.")
    elif args.command == "off":
        as_root()
        command("systemctl", "stop", "mihomo-routing.service")
        print(
            "Mihomo transparent routing disabled; "
            "mihomo.service remains running."
        )
    elif args.command == "reload":
        as_root()
        require_config()
        print("Validating Mihomo configuration...")
        command("mihomo", "-t", "-d", str(STATE_DIR), "-f", str(CONFIG_PATH))
        print("Reloading Mihomo through the local controller...")
        api(
            "/configs?force=true",
            "PUT",
            {"path": str(CONFIG_PATH), "payload": ""},
        )
        command("systemctl", "restart", "mihomo-routing.service")
        doctor()
    elif args.command == "log":
        os.execvp(
            "journalctl", ["journalctl", "-u", "mihomo.service", *args.args]
        )
    elif args.command == "config":
        as_root()
        print(f"Runtime config: {CONFIG_PATH}")
        if CONFIG_PATH.exists():
            stat = CONFIG_PATH.stat()
            print(
                f"{pwd.getpwuid(stat.st_uid).pw_name} "
                f"{grp.getgrgid(stat.st_gid).gr_name} "
                f"{stat.st_mode & 0o777:o} {CONFIG_PATH}"
            )
        else:
            print("(not created)")
        print(
            "Contents intentionally not printed because this file contains "
            "the subscription URL."
        )
    elif args.command == "doctor":
        doctor()
    elif args.command == "mode":
        set_mode(args.mode)
    elif args.command == "routing":
        routing_start() if args.action == "start" else routing_cleanup()
    elif args.command == "cleanup":
        cleanup(args.kind)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except MihomoError as error:
        print(f"mihomo-ctl: {error}", file=sys.stderr)
        raise SystemExit(1)
