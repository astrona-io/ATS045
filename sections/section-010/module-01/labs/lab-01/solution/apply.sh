#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pin_image() {
  local name="$1" repo="$2" digest
  digest="$(kubectl -n starfleet get pod -l "app=${name}" -o jsonpath='{.items[0].status.containerStatuses[0].imageID}' | sed 's/.*@//')"
  kubectl -n starfleet set image "deployment/${name}" "${name}=${repo}@${digest}"
}

pin_image scout ghcr.io/stefanprodan/podinfo
pin_image probe mccutchen/go-httpbin

kubectl -n starfleet create secret generic uplink-db --from-literal=password='orbit-secret-9' --dry-run=client -o yaml | kubectl apply -f -
kubectl -n starfleet patch deployment uplink --patch-file "$DIR/solution.yaml"

for name in scout probe uplink; do
  kubectl -n starfleet rollout status "deployment/${name}" --timeout=180s
done
echo "[solution] Applied."
