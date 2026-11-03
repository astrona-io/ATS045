#!/usr/bin/env bash
# Check: CSR scout-auditor is approved, was signed for the client signer, and carries CN=scout-auditor, O=auditors and a lifetime of at most 86400 seconds.
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

if [ "$(kubectl get csr scout-auditor -o jsonpath='{.spec.signerName}' 2>/dev/null)" != "kubernetes.io/kube-apiserver-client" ]; then
  echo "FAIL: CSR scout-auditor does not exist or does not use the signer kubernetes.io/kube-apiserver-client"
  exit 1
fi
if [ "$(kubectl get csr scout-auditor -o jsonpath='{.status.conditions[?(@.type=="Approved")].status}' 2>/dev/null)" != "True" ]; then
  echo "FAIL: CSR scout-auditor is not approved"
  exit 1
fi
cert="$(csr_cert scout-auditor)"
if [ -z "$cert" ]; then
  echo "FAIL: CSR scout-auditor has no issued certificate"
  exit 1
fi
subject="$(printf '%s\n' "$cert" | node_exec openssl x509 -noout -subject -nameopt RFC2253 2>/dev/null)"
case "$subject" in
  *CN=scout-auditor*) ;;
  *) echo "FAIL: the certificate subject is '$subject', expected CN=scout-auditor"; fail=1 ;;
esac
case "$subject" in
  *O=auditors*) ;;
  *) echo "FAIL: the certificate subject is '$subject', expected O=auditors"; fail=1 ;;
esac
if ! printf '%s\n' "$cert" | node_exec openssl x509 -noout -ext extendedKeyUsage 2>/dev/null | grep -q "TLS Web Client Authentication"; then
  echo "FAIL: the certificate does not have the client authentication key usage"
  fail=1
fi
if ! printf '%s\n' "$cert" | node_exec openssl x509 -noout -checkend 0 >/dev/null 2>&1; then
  echo "FAIL: the certificate has already expired"
  fail=1
fi
if printf '%s\n' "$cert" | node_exec openssl x509 -noout -checkend 86700 >/dev/null 2>&1; then
  echo "FAIL: the certificate is valid for longer than 86400 seconds. Set expirationSeconds in the CSR."
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: scout-auditor has an approved client certificate that lasts at most one day"
fi
exit "$fail"
