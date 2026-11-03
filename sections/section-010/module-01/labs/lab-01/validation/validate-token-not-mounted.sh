#!/usr/bin/env bash
# Check: uplink does not receive a ServiceAccount token. The pod-level field is
# false and the running pod has no token directory.
set -uo pipefail

flag="$(kubectl -n starfleet get deploy uplink -o jsonpath='{.spec.template.spec.automountServiceAccountToken}' 2>/dev/null || true)"
if [ "$flag" != "false" ]; then
  echo "FAIL: automountServiceAccountToken on the uplink pod template is '${flag}', expected 'false'"
  exit 1
fi

if kubectl -n starfleet exec deploy/uplink -- ls /var/run/secrets/kubernetes.io/serviceaccount >/dev/null 2>&1; then
  echo "FAIL: the running uplink pod still has a token directory (an old pod may still be running)"
  exit 1
fi

echo "PASS: uplink has no ServiceAccount token"
