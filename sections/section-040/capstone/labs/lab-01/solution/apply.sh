#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kubectl apply -f "$DIR/solution.yaml"

identity() {
  kubectl -n starfleet exec "deploy/$1" -c istio-proxy -- curl -s localhost:15000/certs \
    | jq -r '[.certificates[].cert_chain[]?.subject_alt_names[]?.uri] | unique | first'
}
kubectl -n starfleet create configmap mesh-identities --from-literal=scout="$(identity scout)" --from-literal=probe="$(identity probe)"
echo "[solution] Applied."
