#!/usr/bin/env bash
# Check: scout and probe are referenced by digest, and the pods are running.
set -uo pipefail

for name in scout probe; do
  image="$(kubectl -n starfleet get deploy "$name" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)"
  if ! echo "$image" | grep -Eq '@sha256:[0-9a-f]{64}$'; then
    echo "FAIL: deployment ${name} uses '${image}', expected a repository@sha256:<digest> reference"
    exit 1
  fi
  ready="$(kubectl -n starfleet get deploy "$name" -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true)"
  if [ "${ready:-0}" -lt 1 ]; then
    echo "FAIL: deployment ${name} has no available replica"
    exit 1
  fi
done

echo "PASS: scout and probe use digest references and are available"
