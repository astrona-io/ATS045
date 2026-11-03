#!/usr/bin/env bash
# Check: the workloads still run and were not changed to get around the policy.
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

for entry in starfleet/scout starfleet/probe starfleet/shuttle outpost/drifter outpost/beacon ops/collector ; do
  ns="${entry%/*}"
  name="${entry#*/}"
  ready="$(kubectl -n "$ns" get deploy "$name" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
  if [ "${ready:-0}" -lt 1 ]; then
    echo "FAIL: deployment $name in $ns is not ready"
    fail=1
  fi
  hn="$(kubectl -n "$ns" get deploy "$name" -o jsonpath='{.spec.template.spec.hostNetwork}' 2>/dev/null)"
  if [ "$hn" = "true" ]; then
    echo "FAIL: deployment $name uses the host network, which policy does not cover"
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "PASS: the workloads run unchanged"
fi
exit "$fail"
