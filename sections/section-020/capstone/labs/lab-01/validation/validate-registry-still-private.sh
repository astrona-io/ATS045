#!/usr/bin/env bash
# Check: the registry still requires credentials. The wrong fix is to turn
# authentication off.
set -uo pipefail

code="$(kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -m 5 -w '%{http_code}' http://registry.registry.svc.cluster.local:5000/v2/ 2>/dev/null || true)"
if [ "$code" != "401" ]; then
  echo "FAIL: an unauthenticated call to the registry returned '${code}', expected 401"
  exit 1
fi

echo "PASS: the registry still refuses unauthenticated calls"
