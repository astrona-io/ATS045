#!/usr/bin/env bash
# Check: the leaked certificate (CN=fleet-intern, O=fleet-ops) has no access left through any user or group binding.
set -uo pipefail

fail=0
NODE="astro-ats-045-capstone-050-control-plane"

# node_exec <command...>: runs a command inside the control plane node container.
node_exec() {
  local engine
  for engine in podman docker; do
    if command -v "$engine" >/dev/null 2>&1 && "$engine" inspect "$NODE" >/dev/null 2>&1; then
      "$engine" exec -i "$NODE" "$@"
      return $?
    fi
  done
  return 1
}

# csr_cert <csr name>: prints the issued certificate of a CSR in PEM form, or nothing.
csr_cert() {
  kubectl get csr "$1" -o jsonpath='{.status.certificate}' 2>/dev/null | base64 -d 2>/dev/null
}

# can <yes|no> <description> <kubectl auth can-i arguments...>
can() {
  local want="$1" description="$2" got
  shift 2
  got="$(kubectl auth can-i "$@" 2>/dev/null || true)"
  if [ "$got" != "$want" ]; then
    echo "FAIL: $description: expected $want, got ${got:-no answer}"
    fail=1
  fi
}

can no "fleet-intern get pods in starfleet" get pods -n starfleet --as fleet-intern --as-group fleet-ops
can no "fleet-intern get pods in kube-system" get pods -n kube-system --as fleet-intern --as-group fleet-ops
can no "fleet-intern get secrets in all namespaces" get secrets -A --as fleet-intern --as-group fleet-ops
can no "fleet-intern create deployments in starfleet" create deployments -n starfleet --as fleet-intern --as-group fleet-ops
can no "user fleet-intern alone get pods in starfleet" get pods -n starfleet --as fleet-intern
can no "group fleet-ops alone get pods in starfleet" get pods -n starfleet --as nobody --as-group fleet-ops

if [ "$fail" -eq 0 ]; then
  echo "PASS: the leaked certificate has no access"
fi
exit "$fail"
