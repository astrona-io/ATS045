#!/usr/bin/env bash
# Check: no NetworkPolicy in starfleet allows every source or every destination, and a default-deny policy still exists.
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

policies="$(kubectl -n starfleet get networkpolicy -o json 2>/dev/null)"
deny="$(printf '%s' "$policies" | jq '[.items[] | select((.spec.podSelector // {}) == {}) | select((.spec.policyTypes // []) | index("Ingress")) | select((.spec.ingress // []) | length == 0)] | length')"
if [ "${deny:-0}" -lt 1 ]; then
  echo "FAIL: there is no default-deny ingress policy that selects all pods in starfleet"
  fail=1
fi
open="$(printf '%s' "$policies" | jq -r '.items[] | . as $p | ((.spec.ingress // [])[] | select((.from // []) | length == 0 or any(.[]?; (.ipBlock.cidr // "") == "0.0.0.0/0" or ((.namespaceSelector // null) == {} and (.podSelector // null) == null)))) | $p.metadata.name' | sort -u)"
if [ -n "$open" ]; then
  echo "FAIL: these policies allow every source: $open"
  fail=1
fi
openeg="$(printf '%s' "$policies" | jq -r '.items[] | . as $p | ((.spec.egress // [])[] | select(((.to // []) | length == 0) and ((.ports // []) | length == 0) or any((.to // [])[]?; (.ipBlock.cidr // "") == "0.0.0.0/0"))) | $p.metadata.name' | sort -u)"
if [ -n "$openeg" ]; then
  echo "FAIL: these policies allow every destination: $openeg"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: the policies keep the default deny and allow no wildcard source or destination"
fi
exit "$fail"
