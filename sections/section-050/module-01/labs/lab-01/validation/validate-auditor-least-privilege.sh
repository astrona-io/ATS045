#!/usr/bin/env bash
# Check: scout-auditor can list and get pods in starfleet and nothing else.
set -uo pipefail

fail=0
NODE="astro-ats-045-lab-050-01-control-plane"

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

can yes "scout-auditor list pods in starfleet" list pods -n starfleet --as scout-auditor --as-group auditors
can yes "scout-auditor get pods in starfleet" get pods -n starfleet --as scout-auditor --as-group auditors
can no "scout-auditor delete pods in starfleet" delete pods -n starfleet --as scout-auditor --as-group auditors
can no "scout-auditor get secrets in starfleet" get secrets -n starfleet --as scout-auditor --as-group auditors
can no "scout-auditor list pods in outpost" list pods -n outpost --as scout-auditor --as-group auditors

if [ "$fail" -eq 0 ]; then
  echo "PASS: scout-auditor can read pods in starfleet and nothing else"
fi
exit "$fail"
