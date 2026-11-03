#!/usr/bin/env bash
# Check: every pod in starfleet has an istio-proxy container, so the checks cannot pass by removing the mesh.
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

pods="$(kubectl -n starfleet get pods -o json | jq -r '.items[] | select(.status.phase == "Running") | .metadata.name + " " + ([.spec.containers[].name] | join(","))')"
if [ -z "$pods" ]; then
  echo "FAIL: no running pods in starfleet"
  exit 1
fi
while read -r name containers; do
  case ",$containers," in
    *,istio-proxy,*) ;;
    *) echo "FAIL: pod $name has no istio-proxy sidecar"; fail=1 ;;
  esac
done <<EOF
$pods
EOF

if [ "$fail" -eq 0 ]; then
  echo "PASS: every running pod in starfleet has a sidecar"
fi
exit "$fail"
