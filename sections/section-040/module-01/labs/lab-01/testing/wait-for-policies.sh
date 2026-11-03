#!/usr/bin/env bash
# Runs under `astrona test` after the reference solution: waits until the
# sidecars of scout have the new policies, so the graders do not race istiod.
set -uo pipefail

for i in $(seq 1 30); do
  code="$(kubectl -n outpost exec deploy/drifter -c drifter -- curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://scout.starfleet:9797/metrics 2>/dev/null || true)"
  plain="$(kubectl -n outpost exec deploy/drifter -c drifter -- curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://scout.starfleet/ 2>/dev/null || true)"
  if [ "$code" = "200" ] && [ "$plain" = "000" ]; then
    echo "[testing] policies are active."
    exit 0
  fi
  sleep 2
done
echo "[testing] policies were not active in time." >&2
exit 1
