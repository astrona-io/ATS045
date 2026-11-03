#!/usr/bin/env bash
# Check: the ServiceAccounts scout and probe reference registry-pull.
set -uo pipefail

for account in scout probe; do
  names="$(kubectl -n starfleet get serviceaccount "$account" -o jsonpath='{.imagePullSecrets[*].name}' 2>/dev/null || true)"
  if ! echo "$names" | grep -qw 'registry-pull'; then
    echo "FAIL: ServiceAccount ${account} does not list registry-pull in imagePullSecrets"
    exit 1
  fi
done

echo "PASS: scout and probe ServiceAccounts carry the pull Secret"
