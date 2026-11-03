#!/usr/bin/env bash
# Check: the ConfigMap pki-evidence in starfleet holds the values read from the certificates on the control plane node, for the keys ca-fingerprint, apiserver-notafter, apiserver-chain.
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

ca="$(node_exec openssl x509 -in /etc/kubernetes/pki/ca.crt -noout -fingerprint -sha256 2>/dev/null | sed 's/^.*=//')"
notafter="$(node_exec openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -enddate 2>/dev/null | sed 's/^notAfter=//')"
chain="$(node_exec openssl verify -CAfile /etc/kubernetes/pki/ca.crt /etc/kubernetes/pki/apiserver.crt 2>/dev/null | sed 's/^.*: //')"
if [ -z "$ca" ] || [ -z "$notafter" ]; then
  echo "FAIL: the grader could not read the certificates on the node"
  exit 1
fi
got="$(kubectl -n starfleet get configmap pki-evidence -o jsonpath='{.data.ca-fingerprint}' 2>/dev/null)"
if [ "$got" != "$ca" ]; then
  echo "FAIL: key ca-fingerprint of the ConfigMap pki-evidence is '$got', expected '$ca'"
  fail=1
fi
got="$(kubectl -n starfleet get configmap pki-evidence -o jsonpath='{.data.apiserver-notafter}' 2>/dev/null)"
if [ "$got" != "$notafter" ]; then
  echo "FAIL: key apiserver-notafter of the ConfigMap pki-evidence is '$got', expected '$notafter'"
  fail=1
fi
got="$(kubectl -n starfleet get configmap pki-evidence -o jsonpath='{.data.apiserver-chain}' 2>/dev/null)"
if [ "$got" != "$chain" ]; then
  echo "FAIL: key apiserver-chain of the ConfigMap pki-evidence is '$got', expected '$chain'"
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  echo "PASS: pki-evidence matches the certificates on the node"
fi
exit "$fail"
