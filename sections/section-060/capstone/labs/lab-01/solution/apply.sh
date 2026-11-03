#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kubectl apply -f "$DIR/solution.yaml"
echo "[solution] Applied. Waiting until the network plug-in enforces the policies."
for _ in $(seq 1 30); do
  code="$(kubectl -n outpost exec deploy/drifter -- curl -s -o /dev/null -w '%{http_code}' --max-time 4 http://scout.starfleet/ 2>/dev/null || true)"
  if [ "$code" = "000" ]; then
    echo "[solution] Policies are enforced."
    exit 0
  fi
  sleep 2
done
echo "[solution] Policies were not enforced in time." >&2
exit 1
