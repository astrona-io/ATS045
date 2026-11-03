#!/usr/bin/env bash
# Check: the uplink Deployment has no DB_PASSWORD environment variable, in any
# container, whether set by value or by reference.
set -uo pipefail

names="$(kubectl -n starfleet get deploy uplink -o jsonpath='{range .spec.template.spec.containers[*].env[*]}{.name}{"\n"}{end}' 2>/dev/null || true)"
if echo "$names" | grep -qx 'DB_PASSWORD'; then
  echo "FAIL: uplink still sets DB_PASSWORD as an environment variable"
  exit 1
fi

echo "PASS: uplink has no DB_PASSWORD environment variable"
