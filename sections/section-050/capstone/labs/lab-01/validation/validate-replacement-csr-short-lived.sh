#!/usr/bin/env bash
# Check: CSR fleet-intern-2 is approved, was signed for the client signer, and carries CN=fleet-intern-2, O=interns and a lifetime of at most 7200 seconds.
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

if [ "$(kubectl get csr fleet-intern-2 -o jsonpath='{.spec.signerName}' 2>/dev/null)" != "kubernetes.io/kube-apiserver-client" ]; then
  echo "FAIL: CSR fleet-intern-2 does not exist or does not use the signer kubernetes.io/kube-apiserver-client"
  exit 1
fi
if [ "$(kubectl get csr fleet-intern-2 -o jsonpath='{.status.conditions[?(@.type=="Approved")].status}' 2>/dev/null)" != "True" ]; then
  echo "FAIL: CSR fleet-intern-2 is not approved"
  exit 1
fi
cert="$(csr_cert fleet-intern-2)"
if [ -z "$cert" ]; then
  echo "FAIL: CSR fleet-intern-2 has no issued certificate"
  exit 1
fi
subject="$(printf '%s\n' "$cert" | node_exec openssl x509 -noout -subject -nameopt RFC2253 2>/dev/null)"
case "$subject" in
  *CN=fleet-intern-2*) ;;
  *) echo "FAIL: the certificate subject is '$subject', expected CN=fleet-intern-2"; fail=1 ;;
esac
case "$subject" in
  *O=interns*) ;;
  *) echo "FAIL: the certificate subject is '$subject', expected O=interns"; fail=1 ;;
esac
if ! printf '%s\n' "$cert" | node_exec openssl x509 -noout -ext extendedKeyUsage 2>/dev/null | grep -q "TLS Web Client Authentication"; then
  echo "FAIL: the certificate does not have the client authentication key usage"
  fail=1
fi
if ! printf '%s\n' "$cert" | node_exec openssl x509 -noout -checkend 0 >/dev/null 2>&1; then
  echo "FAIL: the certificate has already expired"
  fail=1
fi
if printf '%s\n' "$cert" | node_exec openssl x509 -noout -checkend 7500 >/dev/null 2>&1; then
  echo "FAIL: the certificate is valid for longer than 7200 seconds. Set expirationSeconds in the CSR."
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: fleet-intern-2 has an approved client certificate that lasts at most two hours"
fi
exit "$fail"
