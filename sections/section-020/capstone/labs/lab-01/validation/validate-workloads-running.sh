#!/usr/bin/env bash
# Check: behaviour. scout and drifter are available after the rotation.
set -uo pipefail

for target in starfleet/scout outpost/drifter; do
  ns="${target%%/*}"; name="${target##*/}"
  ready="$(kubectl -n "$ns" get deploy "$name" -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true)"
  if [ "${ready:-0}" -lt 1 ]; then
    echo "FAIL: deployment ${name} in ${ns} has no available replica"
    exit 1
  fi
done

echo "PASS: scout and drifter are running"
