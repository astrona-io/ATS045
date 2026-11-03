#!/usr/bin/env bash
# Check: behaviour. The hardened Deployment is available and answers requests.
set -uo pipefail

ready="$(kubectl -n forge get deploy build-runner -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true)"
if [ "${ready:-0}" -lt 1 ]; then
  echo "FAIL: build-runner has no available replica"
  exit 1
fi
kubectl -n forge delete pod check-client --ignore-not-found >/dev/null 2>&1
code="$(kubectl -n forge run check-client --rm -i --restart=Never --image=curlimages/curl:8.22.0 --command -- curl -s -o /dev/null -m 5 -w '%{http_code}' "http://$(kubectl -n forge get pod -l app=build-runner -o jsonpath='{.items[0].status.podIP}'):8080/status/200" 2>/dev/null || true)"
if ! echo "$code" | grep -q '200'; then
  echo "FAIL: build-runner did not answer HTTP 200 (got '${code}')"
  exit 1
fi

echo "PASS: build-runner is available and answers requests"
