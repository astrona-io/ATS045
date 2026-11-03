#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE="astro-ats-045-lab-050-01-control-plane"

node_exec() {
  if command -v podman >/dev/null 2>&1 && podman inspect "$NODE" >/dev/null 2>&1; then
    podman exec -i "$NODE" "$@"
  else
    docker exec -i "$NODE" "$@"
  fi
}

# issue_cert <csr name> <subject> <expiration seconds>: creates a key and a CSR on the node, submits and approves it.
issue_cert() {
  local csr_name="$1" subject="$2" seconds="$3" request
  request="$(node_exec openssl req -new -newkey rsa:2048 -nodes -keyout "/tmp/$csr_name.key" -subj "$subject" 2>/dev/null | base64 | tr -d '\n')"
  kubectl apply -f - <<YAML
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: $csr_name
spec:
  request: $request
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: $seconds
  usages: ["client auth"]
YAML
  kubectl certificate approve "$csr_name"
  for _ in $(seq 1 30); do
    if [ -n "$(kubectl get csr "$csr_name" -o jsonpath='{.status.certificate}')" ]; then
      return 0
    fi
    sleep 1
  done
  echo "certificate for $csr_name was not issued" >&2
  return 1
}

issue_cert scout-auditor "/CN=scout-auditor/O=auditors" 86400
kubectl apply -f "$DIR/solution.yaml"
kubectl -n starfleet create configmap pki-evidence \
  --from-literal=ca-fingerprint="$(node_exec openssl x509 -in /etc/kubernetes/pki/ca.crt -noout -fingerprint -sha256 | sed 's/^.*=//')" \
  --from-literal=apiserver-notafter="$(node_exec openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -enddate | sed 's/^notAfter=//')"

echo "[solution] Applied."
