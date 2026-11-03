#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

digest="$(kubectl -n forge get pod -l app=build-runner -o jsonpath='{.items[0].status.containerStatuses[0].imageID}' | sed 's/.*@//')"
kubectl -n forge delete rolebinding default-admin
sed "s/DIGEST_PLACEHOLDER/${digest}/" "$DIR/solution.yaml" | kubectl apply -f -
kubectl -n forge rollout status deployment/build-runner --timeout=180s
echo "[solution] Applied."
