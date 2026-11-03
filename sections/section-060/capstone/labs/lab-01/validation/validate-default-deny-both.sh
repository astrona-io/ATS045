#!/usr/bin/env bash
# Check: every pod in starfleet is isolated in both directions: drifter cannot reach scout or probe, and a deny policy for Ingress and Egress exists.
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

expect_code "drifter reached scout" 000 outpost drifter http://scout.starfleet/
expect_code "drifter reached probe" 000 outpost drifter http://probe.starfleet/get
policies="$(kubectl -n starfleet get networkpolicy -o json 2>/dev/null)"
both="$(printf '%s' "$policies" | jq '[.items[] | select((.spec.podSelector // {}) == {}) | select((.spec.policyTypes // []) | (index("Ingress") != null and index("Egress") != null)) | select(((.spec.ingress // []) | length == 0) and ((.spec.egress // []) | length == 0))] | length')"
if [ "${both:-0}" -lt 1 ]; then
  echo "FAIL: no policy selects all pods in starfleet for both Ingress and Egress with no rules"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: starfleet is isolated in both directions"
fi
exit "$fail"
