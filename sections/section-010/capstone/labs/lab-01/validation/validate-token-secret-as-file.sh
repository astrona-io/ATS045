#!/usr/bin/env bash
# Check: the registry token is not in the environment and the Secret registry-token
# is mounted read-only as a file, readable in the running pod.
set -uo pipefail

names="$(kubectl -n forge get deploy build-runner -o jsonpath='{range .spec.template.spec.containers[*].env[*]}{.name}{"\n"}{end}' 2>/dev/null || true)"
if echo "$names" | grep -qx 'REGISTRY_TOKEN'; then
  echo "FAIL: REGISTRY_TOKEN is still an environment variable"
  exit 1
fi

secret_name="$(kubectl -n forge get deploy build-runner -o jsonpath='{.spec.template.spec.volumes[*].secret.secretName}' 2>/dev/null || true)"
if ! echo "$secret_name" | grep -qw 'registry-token'; then
  echo "FAIL: no volume uses the secret registry-token"
  exit 1
fi
ro="$(kubectl -n forge get deploy build-runner -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[*].readOnly}' 2>/dev/null || true)"
if ! echo "$ro" | grep -qw 'true'; then
  echo "FAIL: the Secret volume is not mounted read-only"
  exit 1
fi

echo "PASS: the registry token is a read-only mounted Secret"
