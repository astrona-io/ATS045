#!/usr/bin/env bash
# Check: no RoleBinding or ClusterRoleBinding gives the default ServiceAccount of
# forge any role that lets it read Secrets.
set -uo pipefail

can="$(kubectl auth can-i get secrets -n forge --as=system:serviceaccount:forge:default 2>/dev/null || true)"
if [ "$can" = "yes" ]; then
  echo "FAIL: the default ServiceAccount in forge can still get secrets"
  exit 1
fi

echo "PASS: the default ServiceAccount in forge cannot read secrets"
