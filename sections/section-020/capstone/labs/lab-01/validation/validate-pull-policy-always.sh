#!/usr/bin/env bash
# Check: scout and drifter set imagePullPolicy Always, so every start proves
# access to the registry.
set -uo pipefail

for target in starfleet/scout outpost/drifter; do
  ns="${target%%/*}"; name="${target##*/}"
  policy="$(kubectl -n "$ns" get deploy "$name" -o jsonpath='{.spec.template.spec.containers[0].imagePullPolicy}' 2>/dev/null || true)"
  if [ "$policy" != "Always" ]; then
    echo "FAIL: ${name} has imagePullPolicy '${policy}', expected Always"
    exit 1
  fi
done

echo "PASS: both workloads use imagePullPolicy Always"
