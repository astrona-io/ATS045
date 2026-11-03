#!/usr/bin/env bash
# Check: the metrics port 9797 of scout answers plain text, the application port still does not, and the namespace stays strict for probe.
set -uo pipefail

fail=0

# http_code <namespace> <deployment> <container> <curl arguments...>
# Prints the HTTP status, or 000 when the connection failed.
http_code() {
  local namespace="$1" deployment="$2" container="$3"
  shift 3
  kubectl -n "$namespace" exec "deploy/$deployment" -c "$container" -- \
    curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$@" 2>/dev/null || true
}

# expect_code <description> <expected code> <namespace> <deployment> <container> <curl arguments...>
# Retries for about 30 seconds, because the sidecars need a few seconds to get a new policy.
expect_code() {
  local description="$1" expected="$2" got=""
  shift 2
  for _ in $(seq 1 10); do
    got="$(http_code "$@")"
    if [ "$got" = "$expected" ]; then
      return 0
    fi
    sleep 3
  done
  echo "FAIL: $description: expected $expected, got ${got:-no answer}"
  fail=1
}

# sidecar_identity <deployment>: prints the SPIFFE identity in the certificate of the sidecar.
sidecar_identity() {
  kubectl -n starfleet exec "deploy/$1" -c istio-proxy -- curl -s --max-time 5 localhost:15000/certs 2>/dev/null \
    | jq -r '[.certificates[].cert_chain[]?.subject_alt_names[]?.uri] | unique | first // empty' 2>/dev/null
}

expect_code "drifter (no sidecar) could not read /metrics on port 9797 of scout" 200 outpost drifter drifter http://scout.starfleet:9797/metrics
expect_code "drifter (no sidecar) reached the application port of scout in plain text" 000 outpost drifter drifter http://scout.starfleet/
expect_code "drifter (no sidecar) reached probe in plain text" 000 outpost drifter drifter http://probe.starfleet/get

if [ "$fail" -eq 0 ]; then
  echo "PASS: only the metrics port of scout accepts plain text"
fi
exit "$fail"
