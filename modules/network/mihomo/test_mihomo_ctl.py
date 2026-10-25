"""Run with a Python environment containing rich and typer."""

import contextlib
import json
import importlib.util
import io
import os
from pathlib import Path
import runpy
import select
import signal
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from unittest.mock import MagicMock, call, patch
import urllib.error

from rich.console import Console
from typer.main import get_command
from typer.testing import CliRunner


SCRIPT = Path(__file__).with_name("mihomo-ctl.py")
spec = importlib.util.spec_from_file_location("mihomo_ctl", SCRIPT)
ctl = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = ctl
spec.loader.exec_module(ctl)


class SettingsTests(unittest.TestCase):
    def setUp(self):
        self.root = Path(self.enterContext(tempfile.TemporaryDirectory()))
        self.path = self.root / "settings.json"

    def write(self, **values):
        self.path.write_text(json.dumps(values))
        return ctl.load_settings(self.path)

    def test_relative_paths_and_derived_paths(self):
        settings = self.write(
            config_path="config/runtime.yaml", state_dir="state",
            template_path="template.yaml", commands={"ip": "bin/ip", "mihomo": "engine"},
        )
        self.assertEqual(settings.config_path, self.root / "config/runtime.yaml")
        self.assertEqual(settings.subscriptions_dir, self.root / "state/subscriptions")
        self.assertEqual(settings.template_path, self.root / "template.yaml")
        self.assertEqual(settings.executable("ip"), str(self.root / "bin/ip"))
        self.assertEqual(settings.executable("mihomo"), "engine")
        self.assertEqual(settings.executable("systemctl"), "systemctl")

    def test_invalid_settings_fail_before_operations(self):
        for values in (
            {"unknown": True}, {"request_timeout": 0}, {"request_timeout": True},
            {"controller_url": "http://[broken"}, {"controller_url": "file:///tmp/api"},
            {"controller_url": "http://localhost:bad"}, {"config_path": 3},
            {"commands": {"systemctl": []}}, {"commands": {"unknown": "tool"}},
            {"routing_table": 254}, {"routing_table": 2022, "legacy_route_tables": [2022]},
            {"legacy_rule_patterns": ["["]}, {"legacy_route_tables": "2022"},
        ):
            with self.subTest(values=values), self.assertRaises(ctl.MihomoError):
                self.write(**values)

    def test_core_instances_use_independent_controller_and_commands(self):
        first = ctl.MihomoCore(self.write(
            controller_url="http://localhost:9999/api/", proxy_group="A/B 节点",
            request_timeout=2, commands={"systemctl": "/custom/systemctl"},
            service_unit="custom.service", routing_unit="custom-routing.service",
        ))
        second = ctl.MihomoCore(ctl.Settings())
        response = MagicMock()
        response.__enter__.return_value.read.return_value = b"{}"
        with patch.object(ctl.urllib.request, "urlopen", return_value=response) as request:
            first.select_node("node")
            second.select_node("node")
        self.assertEqual(request.call_args_list[0].args[0].full_url,
                         "http://localhost:9999/api/proxies/A%2FB%20%E8%8A%82%E7%82%B9")
        self.assertEqual(request.call_args_list[0].kwargs, {"timeout": 2})
        self.assertEqual(request.call_args_list[1].args[0].full_url,
                         "http://127.0.0.1:9090/proxies/PROXY")
        with (
            patch.object(first, "service_active", return_value=False),
            patch.object(ctl.subprocess, "run") as run,
        ):
            first.restart_mihomo()
        self.assertEqual(run.call_args.args[0], ["/custom/systemctl", "restart", "custom.service"])

    def test_legacy_cleanup_is_explicit(self):
        core = ctl.MihomoCore(ctl.Settings())
        with patch.object(core, "command") as command:
            core.cleanup_foreign_rules()
        command.assert_not_called()
        core = ctl.MihomoCore(self.write(
            legacy_rule_patterns=["lookup 1234$"], legacy_route_tables=[1234],
        ))
        with (
            patch.object(core, "command_output", return_value="100: from all lookup 1234\n"),
            patch.object(core, "command") as command,
        ):
            core.cleanup_foreign_rules()
        self.assertEqual(command.call_count, 4)
        self.assertEqual(command.call_args_list[-1].args,
                         ("ip", "-6", "route", "flush", "table", "1234"))

    def test_cli_settings_precedence_and_repeated_invocations(self):
        self.write(service_unit="explicit.service")
        environment = self.root / "env.json"
        environment.write_text(json.dumps({"service_unit": "env.service"}))
        default = self.root / "default.json"
        default.write_text(json.dumps({"service_unit": "default.service"}))
        services = []

        def get_status(core):
            services.append(core.settings.service_unit)
            return ctl.MihomoStatus(False, False, error="offline")

        app = ctl.create_cli()
        with (
            patch.object(ctl, "DEFAULT_SETTINGS_PATH", str(default)),
            patch.object(ctl.MihomoCore, "get_status", get_status),
            patch.dict(os.environ, {"MIHOMO_CTL_SETTINGS": str(environment)}),
        ):
            runner = CliRunner()
            for args, env in (
                (["--settings", str(self.path), "status"], {}),
                (["status"], {}),
                (["status"], {"MIHOMO_CTL_SETTINGS": ""}),
            ):
                result = runner.invoke(app, args, env=env)
                self.assertEqual(result.exit_code, 0, result.exception)
        self.assertEqual(services, ["explicit.service", "env.service", "default.service"])

    def test_cli_forwards_environment_settings_when_escalating(self):
        self.write(commands={"sudo": "/custom/sudo"})
        with (
            patch.dict(os.environ, {"MIHOMO_CTL_SETTINGS": str(self.path)}),
            patch.object(ctl.os, "geteuid", return_value=1000),
            patch.object(ctl.shutil, "which", return_value="/custom/sudo"),
            patch.object(ctl.os, "execv", side_effect=SystemExit(0)) as execute,
            patch.object(sys, "argv", ["/bin/mihomo-ctl", "routing", "disable"]),
        ):
            result = CliRunner().invoke(ctl.create_cli(), ["routing", "disable"])
        self.assertEqual(result.exit_code, 0, result.exception)
        execute.assert_called_once_with("/custom/sudo", [
            "/custom/sudo", sys.executable, str(Path("/bin/mihomo-ctl").resolve()),
            "--settings", str(self.path), "routing", "disable",
        ])
        for option in (["--settings", "relative.json"], ["--settings=relative.json"]):
            self.assertEqual(
                ctl.configured_arguments(option + ["mode", "rule"], self.path),
                ["--settings", str(self.path), "mode", "rule"],
            )

    def test_subscription_template_is_explicit(self):
        with self.assertRaisesRegex(ctl.MihomoError, "template_path"):
            ctl.MihomoCore(ctl.Settings()).template()
        (self.root / "template.yaml").write_text("mode: $MODE\nurl: $URL\n")
        self.assertEqual(ctl.MihomoCore(self.write(template_path="template.yaml")).template(),
                         "mode: $MODE\nurl: $URL\n")


class ControllerTimeoutTests(unittest.TestCase):
    def setUp(self):
        self.core = ctl.MihomoCore(ctl.Settings())

    def test_connection_timeout(self):
        with patch.object(ctl.urllib.request, "urlopen", side_effect=TimeoutError):
            with self.assertRaisesRegex(ctl.MihomoError, "timed out.*GET /configs"):
                self.core.api("/configs")

    def test_response_read_timeout(self):
        response = MagicMock()
        response.__enter__.return_value.read.side_effect = TimeoutError
        with patch.object(ctl.urllib.request, "urlopen", return_value=response):
            with self.assertRaisesRegex(ctl.MihomoError, "timed out.*PUT /configs"):
                self.core.api("/configs", "PUT", {"payload": "private-config"})
        response.__exit__.assert_called_once()

    def test_wrapped_timeout(self):
        error = urllib.error.URLError(TimeoutError("timed out"))
        with patch.object(ctl.urllib.request, "urlopen", side_effect=error):
            with self.assertRaises(ctl.MihomoError):
                self.core.api("/configs")

    def test_cli_reports_timeout_without_traceback(self):
        output = io.StringIO()
        with (
            patch.object(ctl.urllib.request, "urlopen", side_effect=TimeoutError),
            patch("sys.argv", [str(SCRIPT), "proxy", "close-connections"]),
            contextlib.redirect_stdout(output),
            contextlib.redirect_stderr(output),
        ):
            with self.assertRaises(SystemExit) as result:
                runpy.run_path(str(SCRIPT), run_name="__main__")
        self.assertEqual(result.exception.code, 1)
        self.assertIn("timed out", output.getvalue())
        self.assertIn("/version", output.getvalue())
        self.assertNotIn("Traceback", output.getvalue())

    def test_status_handles_timeout(self):
        output = io.StringIO()
        with (
            patch.object(ctl.urllib.request, "urlopen", side_effect=TimeoutError),
            patch.object(self.core, "service_active", return_value=True),
        ):
            status = self.core.get_status()
            result = CliRunner().invoke(
                ctl.create_cli(self.core, Console(file=output, color_system=None)), ["status"]
            )
        self.assertIsNone(status.mode)
        self.assertIsNone(status.proxy)
        self.assertIn("timed out", status.error)
        self.assertEqual(result.exit_code, 0)
        self.assertIn("unreachable", output.getvalue())


class CoreOperationTests(unittest.TestCase):
    def setUp(self):
        self.enterContext(patch.object(ctl.os, "geteuid", return_value=0))
        directory = self.enterContext(tempfile.TemporaryDirectory())
        self.root = Path(directory)
        self.core = ctl.MihomoCore(ctl.Settings(
            state_dir=self.root,
            config_path=self.root / "config.yaml",
        ))
        self.core.settings.subscriptions_dir.mkdir()

    def test_add_subscription_takes_explicit_input(self):
        with patch.object(self.core, "save_subscription") as save:
            self.core.add_subscription("new", "https://example.com/sub")
        save.assert_called_once_with("new", "https://example.com/sub")

    def test_add_rejects_duplicates_and_invalid_urls(self):
        (self.core.settings.subscriptions_dir / "existing.cred").touch()
        with patch.object(self.core, "save_subscription") as save:
            for name, url in (("existing", "https://example.com"), ("new", "bad")):
                with self.subTest(name=name), self.assertRaises(ctl.MihomoError):
                    self.core.add_subscription(name, url)
        save.assert_not_called()

    def test_edit_applies_only_the_active_subscription(self):
        (self.core.settings.subscriptions_dir / "demo.cred").touch()
        for active in ("demo", "other"):
            with (
                self.subTest(active=active),
                patch.object(self.core, "active_subscription", return_value=active),
                patch.object(self.core, "save_subscription") as save,
                patch.object(self.core, "template", return_value="template"),
                patch.object(self.core, "_apply_subscription") as apply,
            ):
                self.assertEqual(
                    self.core.edit_subscription("demo", "https://example.com/sub"),
                    active == "demo",
                )
                save.assert_called_once_with("demo", "https://example.com/sub")
                self.assertEqual(
                    apply.call_args_list, [call("template", "demo")] if active == "demo" else [],
                )

    def test_template_failure_does_not_replace_saved_subscription(self):
        (self.core.settings.subscriptions_dir / "demo.cred").touch()
        with (
            patch.object(self.core, "template", side_effect=FileNotFoundError),
            patch.object(self.core, "save_subscription") as save,
        ):
            with self.assertRaises(FileNotFoundError):
                self.core.edit_subscription("demo", "https://example.com/sub")
            with self.assertRaises(FileNotFoundError):
                self.core.init_runtime("demo", "https://example.com/sub")
        save.assert_not_called()

    def test_remove_protects_active_subscription(self):
        path = self.core.settings.subscriptions_dir / "demo.cred"
        path.touch()
        with patch.object(self.core, "active_subscription", return_value="demo"):
            with self.assertRaises(ctl.MihomoError):
                self.core.remove_subscription("demo")
        self.assertTrue(path.exists())
        with patch.object(self.core, "active_subscription", return_value="other"):
            self.core.remove_subscription("demo")
        self.assertFalse(path.exists())

    def test_core_requires_privileges_without_launching_sudo(self):
        with (
            patch.object(ctl.os, "geteuid", return_value=1000),
            patch.object(ctl.os, "execv") as elevate,
            patch.object(self.core, "save_subscription") as save,
        ):
            with self.assertRaisesRegex(ctl.MihomoError, "Root privileges"):
                self.core.add_subscription("demo", "https://example.com/sub")
        elevate.assert_not_called()
        save.assert_not_called()

    def test_mode_timeout_does_not_persist_a_change(self):
        with (
            patch.object(ctl.urllib.request, "urlopen", side_effect=TimeoutError),
            patch.object(self.core, "save_mode") as save,
        ):
            with self.assertRaises(ctl.MihomoError):
                self.core.set_mode("global")
        save.assert_not_called()

    def test_mode_patches_instead_of_rebuilding_tun(self):
        events = MagicMock()
        with (
            patch.object(self.core, "api", events.api),
            patch.object(self.core, "save_mode", events.save),
        ):
            self.core.set_mode("global")
        self.assertEqual(events.mock_calls, [
            call.api("/version"), call.save("global"),
            call.api("/configs", "PATCH", {"mode": "global"}),
        ])

    def test_restart_preserves_routing_enablement_and_order(self):
        for enabled in (False, True):
            with (
                self.subTest(enabled=enabled),
                patch.object(self.core, "service_active", return_value=enabled),
                patch.object(self.core, "command") as command,
            ):
                self.core.restart_mihomo()
            expected = [call("systemctl", "restart", "mihomo.service")]
            if enabled:
                expected.insert(0, call("systemctl", "stop", "mihomo-routing.service"))
                expected.append(call("systemctl", "start", "mihomo-routing.service"))
            self.assertEqual(command.call_args_list, expected)

    def test_reload_validates_then_restores_routes_and_returns_report(self):
        events = MagicMock()
        report = ctl.DoctorReport((("example", True),), ())
        events.active.return_value = True
        events.diagnose.return_value = report
        with (
            patch.object(self.core, "require_config", events.config),
            patch.object(self.core, "command", events.command),
            patch.object(self.core, "api", events.api),
            patch.object(self.core, "service_active", events.active),
            patch.object(self.core, "reinstall_routing", events.routes),
            patch.object(self.core, "diagnose", events.diagnose),
        ):
            self.assertIs(self.core.reload_config(), report)
        self.assertEqual(events.mock_calls, [
            call.config(),
            call.command("mihomo", "-t", "-d", str(self.core.settings.state_dir), "-f", str(self.core.settings.config_path)),
            call.api("/configs?force=true", "PUT", {"path": str(self.core.settings.config_path), "payload": ""}),
            call.active("mihomo-routing.service"), call.routes(), call.diagnose(),
        ])

    def test_diagnosis_returns_failures_without_printing_or_exiting(self):
        command_result = subprocess.CompletedProcess([], 1, "", "unavailable")
        with (
            patch.object(self.core, "service_active", return_value=False),
            patch.object(self.core, "api", side_effect=ctl.MihomoError("offline")),
            patch.object(self.core, "command", return_value=command_result),
            patch("builtins.print") as output,
        ):
            report = self.core.diagnose()
        self.assertGreater(report.failures, 0)
        self.assertIn(("controller reachable", False), report.checks)
        output.assert_not_called()

    def test_proxy_selection_normalizes_null_nodes(self):
        with patch.object(self.core, "api", return_value={"now": "demo", "all": None}):
            self.assertEqual(self.core.proxy_selection(), ctl.ProxySelection("demo", ()))

    def test_connection_snapshot_normalizes_controller_data(self):
        data = {
            "connections": [None, {
                "metadata": {
                    "network": "tcp", "sourceIP": "127.0.0.1", "sourcePort": 1234,
                    "host": "example.com", "destinationPort": 443,
                    "processPath": "/bin/curl",
                },
                "rule": "Domain", "rulePayload": "example.com", "chains": ["node", "PROXY"],
                "download": 1024, "upload": "invalid",
            }],
            "downloadTotal": 2048, "uploadTotal": None,
        }
        with patch.object(self.core, "api", return_value=data):
            snapshot = self.core.connection_snapshot()
        self.assertEqual(snapshot.count, 2)
        self.assertEqual(snapshot.download_total, 2048)
        self.assertIsNone(snapshot.upload_total)
        self.assertEqual(snapshot.connections, (ctl.Connection(
            "tcp", "127.0.0.1:1234", "example.com:443", "curl",
            "Domain example.com", "PROXY", 1024, None,
        ),))

    def test_closing_log_stream_stops_the_child(self):
        process = MagicMock()
        process.stdout = io.StringIO('{"MESSAGE": "hello"}\n')
        process.stderr = io.StringIO("")
        process.poll.return_value = None
        with (
            patch.object(self.core, "service_invocation_id", return_value="invocation"),
            patch.object(ctl.subprocess, "Popen", return_value=process),
        ):
            records = self.core.log_records(["--follow"])
            self.assertEqual(next(records), ctl.LogRecord(None, "6", "mihomo", "hello"))
            records.close()
        process.terminate.assert_called_once()
        process.wait.assert_called_once()
        self.assertTrue(process.stdout.closed)
        self.assertTrue(process.stderr.closed)


class FrontendBoundaryTests(unittest.TestCase):
    def setUp(self):
        self.core = ctl.MihomoCore(ctl.Settings())

    def test_import_does_not_load_ui_dependencies_or_change_path(self):
        script = """
import os, runpy, sys
before = os.environ['PATH']
runpy.run_path(sys.argv[1])
assert os.environ['PATH'] == before
assert not {'rich', 'typer', 'PyQt6'} & sys.modules.keys()
"""
        subprocess.run([sys.executable, "-I", "-B", "-c", script, str(SCRIPT)], check=True)

    def test_cli_command_contract(self):
        root = get_command(ctl.create_cli())
        self.assertEqual(set(root.commands), {
            "subscription", "proxy", "routing", "status", "doctor", "mode",
            "log", "reload", "config", "tray",
        })
        for group, names in {
            "subscription": {"init", "add", "edit", "remove", "switch", "list", "update"},
            "proxy": {"node", "update-rules", "test", "connections", "close-connections"},
            "routing": {"routes", "enable", "disable", "start", "cleanup", "purge"},
        }.items():
            self.assertEqual(set(root.commands[group].commands), names)
            for name in names:
                result = CliRunner().invoke(ctl.create_cli(), [group, name, "--help"])
                self.assertEqual(result.exit_code, 0, result.exception)

    def test_cli_collects_hidden_subscription_input(self):
        output = io.StringIO()
        with (
            patch.object(ctl.os, "geteuid", return_value=0),
            patch.object(self.core, "require_new_subscription"),
            patch.object(self.core, "add_subscription") as add,
        ):
            result = CliRunner().invoke(
                ctl.create_cli(self.core, Console(file=output)), ["subscription", "add", "demo"],
                input="https://example.com/private\n",
            )
        self.assertEqual(result.exit_code, 0, result.exception)
        add.assert_called_once_with("demo", "https://example.com/private")
        self.assertNotIn("https://example.com/private", result.output + output.getvalue())

    def test_cli_node_cancel_does_not_mutate_controller(self):
        with (
            patch.object(self.core, "proxy_selection", return_value=ctl.ProxySelection("demo", ("demo",))),
            patch.object(self.core, "select_node") as select,
        ):
            result = CliRunner().invoke(ctl.create_cli(self.core), ["proxy", "node"], input="q\n")
        self.assertEqual(result.exit_code, 0, result.exception)
        select.assert_not_called()


@unittest.skipUnless(importlib.util.find_spec("PyQt6"), "requires optional PyQt6")
class TrayBoundaryTests(unittest.TestCase):
    def test_real_qprocess_failures_recovery_and_noninteractive_input(self):
        from PyQt6 import QtCore, QtWidgets

        messages, indicators, processes = [], [], []

        class Tray(QtWidgets.QSystemTrayIcon):
            def __init__(self, *args):
                super().__init__(*args)
                indicators.append(self)

            def show(self):
                pass

            def showMessage(self, *args):
                messages.append(args)

        class Process(QtCore.QProcess):
            def __init__(self, *args):
                super().__init__(*args)
                processes.append(self)

        with tempfile.TemporaryDirectory() as runtime:
            root = Path(runtime)
            program = root / "fake pkexec"
            plan = root / "plan.json"
            recorded = root / "recorded.json"
            release = root / "release"
            settings = root / "settings with spaces.json"
            helper = (
                f"#!{sys.executable}\n"
                "import json, os, signal, sys, time\n"
                "from pathlib import Path\n"
                f"plan = json.loads(Path({str(plan)!r}).read_text())\n"
                "if plan.get('read_stdin'):\n"
                "    assert sys.stdin.read() == ''\n"
                f"Path({str(recorded)!r}).write_text(json.dumps(sys.argv[1:]))\n"
                "print(plan.get('stdout', ''), flush=True)\n"
                "print(plan.get('stderr', ''), file=sys.stderr, flush=True)\n"
                "if plan.get('hold'):\n"
                f"    while not Path({str(release)!r}).exists(): time.sleep(0.01)\n"
                "if plan.get('crash'):\n"
                "    os.kill(os.getpid(), signal.SIGTERM)\n"
                "sys.exit(plan.get('code', 0))\n"
            )
            core = ctl.MihomoCore(ctl.Settings(commands={"pkexec": str(program)}))

            with patch.dict(os.environ, {
                "QT_QPA_PLATFORM": "offscreen", "DISPLAY": ":test",
                "XDG_RUNTIME_DIR": runtime,
            }):
                application = QtWidgets.QApplication.instance() or QtWidgets.QApplication([])

                def wait_for(predicate):
                    deadline = time.monotonic() + 3
                    while not predicate() and time.monotonic() < deadline:
                        application.processEvents()
                        time.sleep(0.01)
                    self.assertTrue(predicate(), "QProcess did not finish or restore the menu")

                def exercise():
                    menu = indicators[0].contextMenu()
                    reload_action = next(a for a in menu.actions() if a.text() == "Reload configuration")
                    process = processes[0]
                    reads = []
                    process.readyReadStandardOutput.connect(lambda: reads.append(process.bytesAvailable()))
                    scenarios = [
                        ("missing", {}, True),
                        ("nonzero", {"code": 7, "stderr": "failure detail"}, True),
                        ("crash", {"crash": True}, True),
                        ("cancelled", {"code": 126}, True),
                        ("io-error", {"hold": True, "stdout": "x" * 100000}, True),
                        ("success", {"read_stdin": True}, False),
                    ]
                    try:
                        for name, command, failed in scenarios:
                            with self.subTest(name=name):
                                messages.clear()
                                reads.clear()
                                recorded.unlink(missing_ok=True)
                                if name != "missing":
                                    program.write_text(helper)
                                    program.chmod(0o755)
                                plan.write_text(json.dumps(command))
                                reload_action.trigger()
                                self.assertFalse(menu.isEnabled())
                                if name == "io-error":
                                    wait_for(lambda: recorded.exists() and bool(reads))
                                    process.errorOccurred.emit(process.ProcessError.ReadError)
                                    self.assertFalse(menu.isEnabled())
                                    self.assertEqual(max(reads), 0, "child output was not drained")
                                    release.touch()
                                wait_for(lambda: menu.isEnabled() and process.state() == process.ProcessState.NotRunning)
                                # Drain both errorOccurred and finished; a crash must report once.
                                application.processEvents()
                                self.assertEqual(len(messages), int(failed), messages)
                                if name == "nonzero":
                                    self.assertIn("failure detail", messages[0][1])
                                if name == "io-error":
                                    self.assertLessEqual(len(messages[0][1]), 1500)
                                if name == "success":
                                    self.assertEqual(json.loads(recorded.read_text()), [
                                        "--disable-internal-agent", sys.executable,
                                        str(Path(sys.argv[0]).resolve()),
                                        "--settings", str(settings), "reload",
                                    ])
                    finally:
                        if process.state() != process.ProcessState.NotRunning:
                            process.kill()
                            process.waitForFinished(1000)
                    return 0

                with (
                    patch.object(ctl.os, "geteuid", return_value=1000),
                    patch.object(core, "get_status", return_value=ctl.MihomoStatus(False, False, error="offline")),
                    patch.object(QtWidgets, "QApplication", return_value=application),
                    patch.object(QtWidgets, "QSystemTrayIcon", Tray),
                    patch.object(QtCore, "QProcess", Process),
                    patch.object(application, "exec", side_effect=exercise),
                ):
                    ctl.run_tray(core, settings)

    def test_ctrl_c_terminates_idle_and_blocked_tray(self):
        script = r'''
import importlib.util, os, sys, threading
from pathlib import Path
from PyQt6.QtCore import QTimer
from PyQt6.QtWidgets import QApplication, QSystemTrayIcon
spec = importlib.util.spec_from_file_location("ctl", sys.argv[1])
ctl = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = ctl
spec.loader.exec_module(ctl)
ctl.os.geteuid = lambda: 1000
core = ctl.MihomoCore(ctl.Settings())
child_pid_file = Path(os.environ['XDG_RUNTIME_DIR']) / 'child-pid'
if sys.argv[2] == 'child':
    helper = child_pid_file.with_name('fake-pkexec')
    helper.write_text(
        f'#!{sys.executable}\n'
        'import os, signal, time\n'
        'from pathlib import Path\n'
        'signal.signal(signal.SIGINT, signal.SIG_DFL)\n'
        f'Path({str(child_pid_file)!r}).write_text(str(os.getpid()))\n'
        'time.sleep(60)\n'
    )
    helper.chmod(0o755)
    core = ctl.MihomoCore(ctl.Settings(commands={'pkexec': str(helper)}))
started = threading.Event()
blocked = sys.argv[2] == "blocked"
launched = False
def status():
    started.set()
    if blocked:
        threading.Event().wait()
    return ctl.MihomoStatus(False, False, error="offline")
core.get_status = status
def ready():
    global launched
    if sys.argv[2] == 'child':
        if not launched:
            menu = QApplication.instance().findChild(QSystemTrayIcon).contextMenu()
            next(a for a in menu.actions() if a.text() == 'Reload configuration').trigger()
            launched = True
        if not child_pid_file.exists():
            QTimer.singleShot(10, ready)
            return
    if started.is_set():
        print("READY", flush=True)
    else:
        QTimer.singleShot(10, ready)
QTimer.singleShot(0, ready)
ctl.run_tray(core, child_pid_file.with_name('settings.json'))
'''
        with tempfile.TemporaryDirectory() as runtime:
            env = dict(os.environ, QT_QPA_PLATFORM="offscreen", DISPLAY=":test",
                       XDG_RUNTIME_DIR=runtime)
            for state in ("idle", "blocked", "child"):
                with self.subTest(state=state):
                    process = subprocess.Popen(
                        [sys.executable, "-B", "-c", script, str(SCRIPT), state],
                        env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                        text=True, start_new_session=True,
                    )
                    try:
                        self.assertTrue(select.select([process.stdout], [], [], 5)[0],
                                        "tray did not start")
                        self.assertEqual(process.stdout.readline().strip(), "READY")
                        os.killpg(process.pid, signal.SIGINT)
                        _, errors = process.communicate(timeout=2)
                        self.assertEqual(process.returncode, -signal.SIGINT, errors)
                        self.assertNotIn("Traceback", errors)
                        if state == "child":
                            child = int((Path(runtime) / "child-pid").read_text())
                            stat = Path(f"/proc/{child}/stat")
                            deadline = time.monotonic() + 2
                            while stat.exists() and stat.read_text().split()[2] != "Z" and time.monotonic() < deadline:
                                time.sleep(0.01)
                            self.assertTrue(not stat.exists() or stat.read_text().split()[2] == "Z",
                                            "QProcess child survived Ctrl-C to the process group")
                    finally:
                        try:
                            os.killpg(process.pid, signal.SIGKILL)
                        except ProcessLookupError:
                            pass
                        process.communicate()

    def test_core_actions_privileged_bridge_and_timeout_recovery(self):
        from PyQt6 import QtCore, QtWidgets

        self.core = ctl.MihomoCore(ctl.Settings(commands={"pkexec": "/custom/pkexec"}))
        settings_path = Path("/custom/settings.json")
        messages = []
        processes = []
        indicators = []

        class Tray(QtWidgets.QSystemTrayIcon):
            def __init__(self, *args):
                super().__init__(*args)
                indicators.append(self)

            def show(self):
                pass

            def showMessage(self, *args):
                messages.append(args)

        class Process(QtCore.QProcess):
            def start(self, program, arguments):
                processes.append((program, arguments))
                QtCore.QTimer.singleShot(
                    0, lambda: self.finished.emit(0, self.ExitStatus.NormalExit)
                )

        selected = "other"
        offline = False
        action_threads = []

        def status():
            if offline:
                return ctl.MihomoStatus(True, True, error="request timed out")
            return ctl.MihomoStatus(
                True, True, "rule", ctl.ProxySelection(selected, ("a&b", "other")), 1,
            )

        def select(name):
            nonlocal selected
            action_threads.append(threading.get_ident())
            selected = name

        with (
            tempfile.TemporaryDirectory() as runtime,
            patch.dict(os.environ, {
                "QT_QPA_PLATFORM": "offscreen", "DISPLAY": ":test",
                "XDG_RUNTIME_DIR": runtime,
            }),
        ):
            application = QtWidgets.QApplication.instance() or QtWidgets.QApplication([])

            def wait_for(predicate):
                deadline = time.monotonic() + 3
                while not predicate() and time.monotonic() < deadline:
                    application.processEvents()
                    time.sleep(0.01)
                self.assertTrue(predicate(), "tray did not update")

            def exercise():
                nonlocal offline
                indicator = indicators[0]
                menu = indicator.contextMenu()
                actions = {action.text(): action for action in menu.actions()}
                nodes = actions["Proxy node"].menu()
                modes = actions["Mode"].menu()
                wait_for(lambda: len(nodes.actions()) == 2)
                nodes.actions()[0].trigger()
                self.assertFalse(menu.isEnabled())
                wait_for(lambda: menu.isEnabled() and "a&b" in indicator.toolTip())
                self.assertEqual(selected, "a&b")
                self.assertNotEqual(action_threads[0], threading.get_ident())
                self.assertEqual(processes, [])

                actions["Close connections"].trigger()
                wait_for(lambda: menu.isEnabled() and bool(messages))
                self.assertIn("timed out", messages[0][1])
                self.assertEqual(processes, [])

                global_mode = next(a for a in modes.actions() if a.text() == "global")
                global_mode.trigger()
                wait_for(menu.isEnabled)
                self.assertEqual(processes[-1][0], "/custom/pkexec")
                self.assertEqual(processes[-1][1][:2], ["--disable-internal-agent", sys.executable])
                self.assertEqual(processes[-1][1][3:5], ["--settings", str(settings_path)])
                self.assertEqual(processes[-1][1][5:], ["mode", "global"])

                actions["Transparent routing"].trigger()
                wait_for(menu.isEnabled)
                self.assertEqual(processes[-1][1][5:], ["routing", "disable"])

                offline = True
                actions["Reload configuration"].trigger()
                wait_for(lambda: menu.isEnabled() and not modes.isEnabled())
                self.assertEqual(processes[-1][1][5:], ["reload"])
                self.assertIn("timed out", indicator.toolTip())
                self.assertEqual(nodes.actions(), [])

                offline = False
                actions["Reload configuration"].trigger()
                wait_for(lambda: menu.isEnabled() and modes.isEnabled())
                self.assertEqual(len(nodes.actions()), 2)
                return 0

            with (
                patch.object(ctl.os, "geteuid", return_value=1000),
                patch.object(self.core, "get_status", side_effect=status),
                patch.object(self.core, "select_node", side_effect=select),
                patch.object(self.core, "close_connections", side_effect=ctl.MihomoError("request timed out")),
                patch.object(QtWidgets, "QApplication", return_value=application),
                patch.object(QtWidgets, "QSystemTrayIcon", Tray),
                patch.object(QtCore, "QProcess", Process),
                patch.object(application, "exec", side_effect=exercise),
            ):
                previous_sigint = signal.getsignal(signal.SIGINT)
                ctl.run_tray(self.core, settings_path)
                self.assertEqual(signal.getsignal(signal.SIGINT), previous_sigint)


if __name__ == "__main__":
    unittest.main()
