#!/usr/bin/env bash
# Check: behaviour. scout and probe are available, so the pull worked.
set -uo pipefail

for name in scout probe; do
  ready="$(kubectl -n starfleet get deploy "$name" -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true)"
  if [ "${ready:-0}" -lt 1 ]; then
    echo "FAIL: deployment ${name} has no available replica (pods created before the fix need a restart)"
    exit 1
  fi
done

echo "PASS: scout and probe are running"
