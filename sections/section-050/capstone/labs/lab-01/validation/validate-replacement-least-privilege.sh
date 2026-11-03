#!/usr/bin/env bash
# Check: fleet-intern-2 can read pods in starfleet and nothing else, and has no admin binding.
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

can yes "fleet-intern-2 list pods in starfleet" list pods -n starfleet --as fleet-intern-2 --as-group interns
can yes "fleet-intern-2 get pods in starfleet" get pods -n starfleet --as fleet-intern-2 --as-group interns
can no "fleet-intern-2 get secrets in starfleet" get secrets -n starfleet --as fleet-intern-2 --as-group interns
can no "fleet-intern-2 delete pods in starfleet" delete pods -n starfleet --as fleet-intern-2 --as-group interns
can no "fleet-intern-2 list pods in outpost" list pods -n outpost --as fleet-intern-2 --as-group interns
can no "fleet-intern-2 get pods in kube-system" get pods -n kube-system --as fleet-intern-2 --as-group interns

if [ "$fail" -eq 0 ]; then
  echo "PASS: fleet-intern-2 can read pods in starfleet and nothing else"
fi
exit "$fail"
