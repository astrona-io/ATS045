#!/usr/bin/env bash
# Check: build-runner runs as its own ServiceAccount and receives no token.
set -uo pipefail

sa="$(kubectl -n forge get deploy build-runner -o jsonpath='{.spec.template.spec.serviceAccountName}' 2>/dev/null || true)"
if [ "$sa" != "build-runner" ]; then
  echo "FAIL: serviceAccountName is '${sa}', expected 'build-runner'"
  exit 1
fi
flag="$(kubectl -n forge get deploy build-runner -o jsonpath='{.spec.template.spec.automountServiceAccountToken}' 2>/dev/null || true)"
if [ "$flag" != "false" ]; then
  echo "FAIL: automountServiceAccountToken is '${flag}', expected 'false'"
  exit 1
fi

echo "PASS: build-runner uses its own ServiceAccount without a token"
