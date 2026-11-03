#!/usr/bin/env bash
# Check: the metrics port 9797 of scout answers the collector in ops and no other client.
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

scout_ip="$(kubectl -n starfleet get pod -l app=scout -o jsonpath='{.items[0].status.podIP}' 2>/dev/null)"
expect_code "collector could not read the metrics port of scout" 200 ops collector "http://$scout_ip:9797/metrics"
expect_code "shuttle read the metrics port of scout" 000 starfleet shuttle "http://$scout_ip:9797/metrics"
expect_code "drifter read the metrics port of scout" 000 outpost drifter "http://$scout_ip:9797/metrics"
expect_code "collector reached the application port of scout" 000 ops collector "http://$scout_ip:9898/"

if [ "$fail" -eq 0 ]; then
  echo "PASS: only the collector reads the metrics port"
fi
exit "$fail"
