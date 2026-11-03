#!/usr/bin/env bash
# Check: shuttle reaches only scout: name resolution works, scout answers, and probe and beacon do not.
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

expect_code "shuttle could not reach scout by name (DNS must stay allowed)" 200 starfleet shuttle http://scout.starfleet/
expect_code "shuttle reached probe" 000 starfleet shuttle http://probe.starfleet/get
expect_code "shuttle reached beacon" 000 starfleet shuttle http://beacon.outpost/get

if [ "$fail" -eq 0 ]; then
  echo "PASS: shuttle can only reach scout"
fi
exit "$fail"
