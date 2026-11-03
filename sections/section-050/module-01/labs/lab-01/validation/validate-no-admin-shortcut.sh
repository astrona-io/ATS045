#!/usr/bin/env bash
# Check: scout still runs and no admin shortcut was added for the new access.
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

ready="$(kubectl -n starfleet get deploy scout -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
if [ "${ready:-0}" -lt 1 ]; then
  echo "FAIL: deployment scout in starfleet is not ready"
  fail=1
fi
admins="$(kubectl get clusterrolebinding,rolebinding -A -o json 2>/dev/null | jq -r '.items[] | select(.roleRef.name == "cluster-admin" or .roleRef.name == "admin") | select(any(.subjects[]?; (.kind == "User" and .name == "scout-auditor") or (.kind == "Group" and .name == "auditors"))) | .metadata.name')"
if [ -n "$admins" ]; then
  echo "FAIL: scout-auditor has an admin binding: $admins"
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  echo "PASS: the workload runs and the access is not admin"
fi
exit "$fail"
