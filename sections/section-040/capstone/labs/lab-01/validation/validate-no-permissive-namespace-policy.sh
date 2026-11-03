#!/usr/bin/env bash
# Check: no namespace-wide PeerAuthentication in starfleet uses PERMISSIVE or
# DISABLE, and a namespace-wide policy exists.
set -uo pipefail

modes="$(kubectl -n starfleet get peerauthentication -o json 2>/dev/null | jq -r '.items[] | select(.spec.selector == null) | .spec.mtls.mode // "UNSET"')"
if [ -z "$modes" ]; then
  echo "FAIL: there is no namespace-wide PeerAuthentication in starfleet"
  exit 1
fi
for mode in $modes; do
  if [ "$mode" != "STRICT" ]; then
    echo "FAIL: a namespace-wide PeerAuthentication uses mode $mode, expected STRICT"
    exit 1
  fi
done

echo "PASS: the namespace-wide policy is STRICT"
