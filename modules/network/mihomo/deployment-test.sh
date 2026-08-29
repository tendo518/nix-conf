#!/usr/bin/env bash
set -Eeuo pipefail

# Phase B smoke/integration test for the host-local Mihomo deployment.
#
# The script deliberately never reads or prints /etc/mihomo/config.yaml.
# Optional route targets can be supplied through MIHOMO_TEST_*_IP variables.
# Disruptive crash/tailscaled-restart tests require MIHOMO_RUN_DISRUPTIVE_TESTS=1.

CONFIG_PATH=/etc/mihomo/config.yaml
REPORT_DIR="${MIHOMO_REPORT_DIR:-/tmp/mihomo-deployment-$(date +%Y%m%d-%H%M%S)}"
REPORT_PATH="$REPORT_DIR/mihomo-deployment-report.md"
STEP=0
PASS_COUNT=0
FAIL_COUNT=0
NOT_TESTED_COUNT=0

umask 077
mkdir -p "$REPORT_DIR"

cat > "$REPORT_PATH" <<EOF
# Mihomo deployment report

- Started: $(date --iso-8601=seconds)
- Host: $(hostname -s)
- Report directory: $REPORT_DIR

The runtime config contents are intentionally not recorded.

## Results
EOF

result() {
  local status="$1" label="$2" detail="${3:-}"
  printf -- '- **%s** — %s%s\n' "$status" "$label" "${detail:+: $detail}" >> "$REPORT_PATH"
  case "$status" in
    PASS) PASS_COUNT=$((PASS_COUNT + 1)) ;;
    FAIL) FAIL_COUNT=$((FAIL_COUNT + 1)) ;;
    "NOT TESTED") NOT_TESTED_COUNT=$((NOT_TESTED_COUNT + 1)) ;;
  esac
}

run_step() {
  local label="$1"
  shift
  STEP=$((STEP + 1))
  local slug log rc
  slug="$(printf '%s' "$label" | tr '[:upper:] /' '[:lower:]__')"
  log="$REPORT_DIR/$(printf '%02d' "$STEP")-$slug.log"

  printf '\n[%02d] %s\n' "$STEP" "$label"
  printf '\n## %02d. %s\n\n' "$STEP" "$label" >> "$REPORT_PATH"
  printf 'Command output is stored in `%s`.\n' "$log" >> "$REPORT_PATH"

  set +e
  "$@" 2>&1 | tee "$log"
  rc="${PIPESTATUS[0]}"
  set -e

  if [ "$rc" -eq 0 ]; then
    result PASS "$label"
    return 0
  fi
  result FAIL "$label" "exit $rc"
  return "$rc"
}

not_tested() {
  result "NOT TESTED" "$1" "${2:-requires manual test or an optional target}"
}

record_baseline() {
  local output="$1"
  ip rule
  ip route show table all
  ip -6 rule
  ip -6 route show table all
  resolvectl status
  tailscale status
  printf '\nDirect IPv4 egress: %s\n' "$output"
}

measure_direct_ip() {
  curl -4 --noproxy '*' --connect-timeout 5 --max-time 20 --fail --silent --show-error \
    https://myip.ipip.net || \
  curl -4 --noproxy '*' --connect-timeout 5 --max-time 20 --fail --silent --show-error \
    https://ip.3322.net
}

measure_proxy_ip() {
  curl -4 --http1.1 --noproxy '' --proxy http://127.0.0.1:7890 \
    --connect-timeout 5 --max-time 30 --fail --silent --show-error \
    https://myip.ipip.net || \
  curl -4 --http1.1 --noproxy '' --proxy http://127.0.0.1:7890 \
    --connect-timeout 5 --max-time 30 --fail --silent --show-error \
    https://ip.3322.net
}

measure_transparent_ip() {
  curl -4 --http1.1 --noproxy '*' --connect-timeout 5 --max-time 30 --fail --silent --show-error \
    https://myip.ipip.net || \
  curl -4 --http1.1 --noproxy '*' --connect-timeout 5 --max-time 30 --fail --silent --show-error \
    https://ip.3322.net
}

ip_only() {
  printf '%s\n' "$1" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n1
}

check_route() {
  local label="$1" address="$2" expectation="$3" output
  output="$(ip -4 route get "$address" 2>&1)" || {
    printf '%s\n' "$output"
    return 1
  }
  printf '%s\n' "$output"
  case "$expectation" in
    tailscale) printf '%s\n' "$output" | grep -Eq 'dev tailscale0' ;;
    lan) ! printf '%s\n' "$output" | grep -Eq 'dev (mihomo|tailscale0)' ;;
    mihomo) printf '%s\n' "$output" | grep -Eq 'dev mihomo' ;;
    *) echo "Unknown route expectation: $expectation" >&2; return 2 ;;
  esac
}

check_no_stale_routing() {
  local rules routes
  rules="$(ip -4 rule show)"
  routes="$(ip -4 route show table 2023)"
  printf 'Rules:\n%s\n\nTable 2023:\n%s\n' "$rules" "$routes"
  ! printf '%s\n' "$rules" | grep -Eq 'lookup 2023$'
  [ -z "$routes" ]
}

crash_safety_test() {
  sudo systemctl kill --kill-who=main --signal=KILL mihomo.service
  sleep 4

  local daemon routing rules routes
  daemon="$(systemctl is-active mihomo.service || true)"
  routing="$(systemctl is-active mihomo-routing.service || true)"
  rules="$(ip -4 rule show)"
  routes="$(ip -4 route show table 2023)"
  printf 'mihomo.service: %s\nmihomo-routing.service: %s\n\n%s\n\n%s\n' \
    "$daemon" "$routing" "$rules" "$routes"

  if [ "$daemon" = active ] && [ "$routing" = active ] &&
     printf '%s\n' "$rules" | grep -Eq 'lookup 2023$' &&
     printf '%s\n' "$routes" | grep -Eq '^default dev mihomo'; then
    return 0
  fi

  if [ "$routing" != active ] && ! printf '%s\n' "$rules" | grep -Eq 'lookup 2023$' &&
     [ -z "$routes" ]; then
    return 0
  fi
  return 1
}

tailscaled_restart_test() {
  sudo systemctl restart tailscaled
  sleep 5
  tailscale status
  ip rule
  mihomo-ctl doctor
  tailscale ping "${MIHOMO_TEST_TAILSCALE_HOST:?Set MIHOMO_TEST_TAILSCALE_HOST for this test}"
}

printf 'Mihomo Phase B test report: %s\n' "$REPORT_PATH"

if ! direct_ip="$(measure_direct_ip)"; then
  result FAIL "direct IPv4 egress before Mihomo"
  echo "Cannot establish baseline direct connectivity; stopping before Mihomo startup." >&2
  exit 1
fi
printf 'Direct IPv4 egress: %s\n' "$direct_ip"
run_step "record baseline" record_baseline "$direct_ip" || true

if ! systemctl is-active --quiet mihomo.service; then
  result FAIL "mihomo daemon running" "inactive; run: sudo mihomo-ctl on"
  echo "mihomo.service is not running. This script does not start Mihomo itself;" >&2
  echo "If the runtime config is missing, first run: sudo mihomo-ctl init" >&2
  echo "Then start the daemon with: sudo mihomo-ctl on" >&2
  exit 1
fi
runtime_stack="$(sudo grep -m1 -E '^[[:space:]]*stack:' "$CONFIG_PATH" 2>/dev/null | awk '{ print $2 }')"
if [ "$runtime_stack" != "mixed" ]; then
  result FAIL "runtime stack is system" "found '${runtime_stack:-missing}'; run: sudo mihomo-ctl init"
  echo "Runtime config stack is '${runtime_stack:-missing}', expected 'system'." >&2
  echo "Re-generate the config outside this script: sudo mihomo-ctl init" >&2
  exit 1
fi
run_step "Mihomo daemon is active" systemctl is-active --quiet mihomo.service || true

if ! proxy_ip="$(measure_proxy_ip)"; then
  result FAIL "explicit proxy egress"
  echo "Explicit proxy test failed; transparent routing was not enabled." >&2
  exit 1
fi
printf 'Explicit proxy IPv4 egress: %s\n' "$proxy_ip"
if [ "$(ip_only "$proxy_ip")" != "$(ip_only "$direct_ip")" ]; then
  result PASS "explicit proxy egress differs from direct egress" "$direct_ip -> $proxy_ip"
else
  result FAIL "explicit proxy egress differs from direct egress" "$proxy_ip"
  echo "Proxy egress is unchanged; transparent routing was not enabled." >&2
  exit 1
fi

run_step "update subscription provider" mihomo-ctl update || true
run_step "provider health check" mihomo-ctl test || true
run_step "Mihomo status before transparent routing" mihomo-ctl status || true

run_step "DNS/listener baseline after daemon start" bash -c 'resolvectl status; ss -lnup; ss -lntp' || true
if ss -lnup 2>/dev/null | grep -E 'mihomo[^[:space:]]*:53|:53[^[:space:]]*.*mihomo' >/dev/null ||
   ss -lntp 2>/dev/null | grep -E 'mihomo[^[:space:]]*:53|:53[^[:space:]]*.*mihomo' >/dev/null; then
  result FAIL "Mihomo is not listening on port 53"
else
  result PASS "Mihomo is not listening on port 53"
fi

if ! run_step "enable transparent routing" mihomo-ctl on; then
  mihomo-ctl off || true
  echo "Transparent routing failed to start; it was turned off again." >&2
  exit 1
fi
run_step "capture policy rules after enable" bash -c 'ip -4 rule show; ip -4 route show table 2023' || true
run_step "Mihomo doctor after enabling routing" mihomo-ctl doctor || true

transparent_log="$REPORT_DIR/transparent-egress.log"
pcap="$REPORT_DIR/transparent-tun.pcap"
dumpcap -i mihomo -f 'tcp' -a duration:20 -w "$pcap" > "$REPORT_DIR/dumpcap.log" 2>&1 &
dumpcap_pid=$!
sleep 1
set +e
transparent_ip="$(measure_transparent_ip 2>"$transparent_log")"
transparent_rc=$?
set -e
if kill -0 "$dumpcap_pid" 2>/dev/null; then
  kill "$dumpcap_pid" 2>/dev/null || true
fi
wait "$dumpcap_pid" 2>/dev/null || true
printf 'Transparent IPv4 egress (rc=%s): %s\n' "$transparent_rc" "$transparent_ip"
printf 'Transparent IPv4 egress (rc=%s): %s\n' "$transparent_rc" "$transparent_ip" >> "$REPORT_PATH"
cat "$transparent_log" >> "$REPORT_PATH"
printf -- '- TUN packet capture at `%s` (see `dumpcap.log`).\n' "$pcap" >> "$REPORT_PATH"
if [ "$transparent_rc" -eq 0 ]; then
  if [ "$(ip_only "$transparent_ip")" = "$(ip_only "$proxy_ip")" ]; then
    result PASS "transparent egress matches explicit proxy egress" "$transparent_ip"
  else
    result FAIL "transparent egress matches explicit proxy egress" "$proxy_ip -> $transparent_ip"
  fi
else
  result FAIL "transparent IPv4 egress" "curl exit $transparent_rc"
  trans_ip="$(getent ahostsv4 myip.ipip.net 2>/dev/null | awk 'NR == 1 { print $1 }')"
  if [ -n "$trans_ip" ]; then
    ip -4 route get "$trans_ip" > "$REPORT_DIR/transparent-route.log" 2>&1 || true
    printf -- '- Route lookup for target `%s` captured in `transparent-route.log`.\n' "$trans_ip" >> "$REPORT_PATH"
  fi
  iptables_log="$REPORT_DIR/iptables-save.log"
  sudo iptables-save > "$iptables_log" 2>&1 || true
  sudo nft list ruleset > "$REPORT_DIR/nftables.log" 2>&1 || true
  sudo grep -n -E '^[[:space:]]*(stack|tun):' "$CONFIG_PATH" > "$REPORT_DIR/runtime-tun-config.log" 2>&1 || true
  printf -- '- Captured iptables-save at `%s` and nftables at `%s`.\n' "$iptables_log" "$REPORT_DIR/nftables.log" >> "$REPORT_PATH"
fi

if [ -n "${MIHOMO_TEST_TS_IP:-}" ]; then
  run_step "Tailscale peer route" check_route "Tailscale peer" "$MIHOMO_TEST_TS_IP" tailscale || true
else
  not_tested "Tailscale peer route" "set MIHOMO_TEST_TS_IP"
fi
if [ -n "${MIHOMO_TEST_SUBNET_IP:-}" ]; then
  run_step "accepted Tailscale subnet route" check_route "Tailscale subnet" "$MIHOMO_TEST_SUBNET_IP" tailscale || true
else
  not_tested "accepted Tailscale subnet route" "set MIHOMO_TEST_SUBNET_IP"
fi
if [ -n "${MIHOMO_TEST_CAMPUS_IP:-}" ]; then
  run_step "campus subnet route" check_route "Campus subnet" "$MIHOMO_TEST_CAMPUS_IP" tailscale || true
else
  not_tested "campus subnet route" "set MIHOMO_TEST_CAMPUS_IP"
fi
if [ -n "${MIHOMO_TEST_LAN_IP:-}" ]; then
  run_step "LAN route bypasses Mihomo/Tailscale" check_route "LAN" "$MIHOMO_TEST_LAN_IP" lan || true
else
  not_tested "LAN route" "set MIHOMO_TEST_LAN_IP"
fi
run_step "public route enters Mihomo table" check_route "Public Internet" 1.1.1.1 mihomo || true

if run_step "transparent routing DNS/listener check" bash -c 'resolvectl status; ss -lnup; ss -lntp'; then
  if ss -lnup 2>/dev/null | grep -E 'mihomo[^[:space:]]*:53|:53[^[:space:]]*.*mihomo' >/dev/null ||
     ss -lntp 2>/dev/null | grep -E 'mihomo[^[:space:]]*:53|:53[^[:space:]]*.*mihomo' >/dev/null; then
    result FAIL "Mihomo remains absent from port 53 after routing enable"
  else
    result PASS "Mihomo remains absent from port 53 after routing enable"
  fi
fi

run_step "disable transparent routing and remove policy rules" mihomo-ctl off || true
if run_step "no stale Mihomo policy rule after off" check_no_stale_routing; then
  result PASS "mihomo-ctl off leaves no table 2023 blackhole"
else
  result FAIL "mihomo-ctl off leaves no table 2023 blackhole"
fi
if direct_after_off="$(measure_direct_ip)"; then
  printf 'Direct IPv4 egress after mihomo-ctl off: %s\n' "$direct_after_off"
  if [ "$(ip_only "$direct_after_off")" = "$(ip_only "$direct_ip")" ]; then
    result PASS "direct egress restored after mihomo-ctl off" "$direct_after_off"
  else
    result FAIL "direct egress restored after mihomo-ctl off" "$direct_ip -> $direct_after_off"
  fi
else
  result FAIL "direct egress after mihomo-ctl off"
fi

run_step "restore transparent routing" mihomo-ctl on || true
run_step "final Mihomo doctor" mihomo-ctl doctor || true

if [ -n "${MIHOMO_TEST_NODE:-}" ]; then
  run_step "switch selected node" mihomo-ctl node "$MIHOMO_TEST_NODE" || true
  run_step "close connections after node switch" mihomo-ctl close || true
else
  not_tested "node switching" "set MIHOMO_TEST_NODE or run mihomo-ctl node interactively"
fi

not_tested "CN direct / foreign proxy split" "CN rule providers are not in the initial config"
not_tested "Wi-Fi/network switch" "requires manually changing network"
not_tested "suspend/resume" "requires manually suspending the machine"
not_tested "IPv6" "requires a stable IPv6 test network"

if [ "${MIHOMO_RUN_DISRUPTIVE_TESTS:-0}" = 1 ]; then
  run_step "Mihomo crash safety" crash_safety_test || true
  run_step "restore routing after crash test" mihomo-ctl on || true
  if [ -n "${MIHOMO_TEST_TAILSCALE_HOST:-}" ]; then
    run_step "tailscaled restart regression" tailscaled_restart_test || true
  else
    not_tested "tailscaled restart regression" "set MIHOMO_TEST_TAILSCALE_HOST"
  fi
else
  not_tested "Mihomo crash safety" "set MIHOMO_RUN_DISRUPTIVE_TESTS=1"
  not_tested "tailscaled restart regression" "set MIHOMO_RUN_DISRUPTIVE_TESTS=1 and MIHOMO_TEST_TAILSCALE_HOST"
fi

cat >> "$REPORT_PATH" <<EOF

## Summary

- PASS: $PASS_COUNT
- FAIL: $FAIL_COUNT
- NOT TESTED: $NOT_TESTED_COUNT
- Final routing state: requested ON; verify with `mihomo-ctl doctor`.
- Report path: $REPORT_PATH
EOF

printf '\nPASS=%d FAIL=%d NOT_TESTED=%d\nReport: %s\n' \
  "$PASS_COUNT" "$FAIL_COUNT" "$NOT_TESTED_COUNT" "$REPORT_PATH"

if [ "$FAIL_COUNT" -ne 0 ]; then
  exit 1
fi
