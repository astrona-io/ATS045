#!/usr/bin/env bash
# Check: the Deployment templates do not repeat the pull Secret. The credential
# comes from the ServiceAccount.
set -uo pipefail

for name in scout probe; do
  direct="$(kubectl -n starfleet get deploy "$name" -o jsonpath='{.spec.template.spec.imagePullSecrets}' 2>/dev/null || true)"
  if [ -n "$direct" ]; then
    echo "FAIL: deployment ${name} sets imagePullSecrets in its template. Use the ServiceAccount instead"
    exit 1
  fi
done

echo "PASS: the Deployments rely on the ServiceAccount for the pull Secret"
