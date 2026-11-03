#!/usr/bin/env bash
# Check: the ConfigMap mesh-identities in starfleet holds the SPIFFE identity found in the certificate of the sidecar, for the keys scout, probe.
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

expected_scout="$(sidecar_identity scout)"
expected_probe="$(sidecar_identity probe)"
if [ -z "$expected_scout" ] || [ -z "$expected_probe" ]; then
  echo "FAIL: the grader could not read the certificates of the sidecars"
  exit 1
fi
got_scout="$(kubectl -n starfleet get configmap mesh-identities -o jsonpath='{.data.scout}' 2>/dev/null)"
if [ "$got_scout" != "$expected_scout" ]; then
  echo "FAIL: key scout of the ConfigMap mesh-identities is '$got_scout', expected the identity in the certificate of scout"
  fail=1
fi
got_probe="$(kubectl -n starfleet get configmap mesh-identities -o jsonpath='{.data.probe}' 2>/dev/null)"
if [ "$got_probe" != "$expected_probe" ]; then
  echo "FAIL: key probe of the ConfigMap mesh-identities is '$got_probe', expected the identity in the certificate of probe"
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  echo "PASS: mesh-identities holds the real certificate identities"
fi
exit "$fail"
