#!/usr/bin/env bash
# Check: shuttle cannot reach beacon in outpost, by name or by pod address.
set -uo pipefail

fail=0

# http_code <namespace> <deployment> <curl arguments...>
# Prints the HTTP status, or 000 when no answer arrives within four seconds.
http_code() {
  local namespace="$1" deployment="$2"
  shift 2
  kubectl -n "$namespace" exec "deploy/$deployment" -- \
    curl -s -o /dev/null -w '%{http_code}' --max-time 4 "$@" 2>/dev/null || true
}

# expect_code <description> <expected code> <namespace> <deployment> <curl arguments...>
# Retries for about a minute, because the network plug-in needs a few seconds to apply a policy.
expect_code() {
  local description="$1" expected="$2" got=""
  shift 2
  for _ in $(seq 1 12); do
    got="$(http_code "$@")"
    if [ "$got" = "$expected" ]; then
      return 0
    fi
    sleep 3
  done
  echo "FAIL: $description: expected $expected, got ${got:-no answer}"
  fail=1
}

beacon_ip="$(kubectl -n outpost get pod -l app=beacon -o jsonpath='{.items[0].status.podIP}' 2>/dev/null)"
expect_code "shuttle reached beacon by name" 000 starfleet shuttle http://beacon.outpost/get
expect_code "shuttle reached beacon by address" 000 starfleet shuttle "http://$beacon_ip:8080/get"

if [ "$fail" -eq 0 ]; then
  echo "PASS: shuttle cannot reach beacon"
fi
exit "$fail"
