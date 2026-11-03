#!/usr/bin/env bash
# Check: behaviour. Every workload is available and shuttle reaches scout.
set -uo pipefail

for name in scout probe shuttle uplink; do
  ready="$(kubectl -n starfleet get deploy "$name" -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true)"
  if [ "${ready:-0}" -lt 1 ]; then
    echo "FAIL: deployment ${name} has no available replica"
    exit 1
  fi
done

code="$(kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -m 5 -w '%{http_code}' http://scout.starfleet.svc.cluster.local/healthz 2>/dev/null || true)"
if [ "$code" != "200" ]; then
  echo "FAIL: shuttle got HTTP '${code}' from scout, expected 200"
  exit 1
fi

echo "PASS: all workloads are available and shuttle reaches scout"
