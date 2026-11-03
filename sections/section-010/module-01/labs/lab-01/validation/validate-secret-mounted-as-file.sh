#!/usr/bin/env bash
# Check: Secret uplink-db holds the password and is mounted read-only as a file
# at /etc/uplink in the uplink container, and the running pod can read it.
set -uo pipefail

value="$(kubectl -n starfleet get secret uplink-db -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null || true)"
if [ "$value" != "orbit-secret-9" ]; then
  echo "FAIL: secret uplink-db key 'password' is missing or has a different value"
  exit 1
fi

mount="$(kubectl -n starfleet get deploy uplink -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[?(@.mountPath=="/etc/uplink")].readOnly}' 2>/dev/null || true)"
if [ "$mount" != "true" ]; then
  echo "FAIL: no read-only volume mount at /etc/uplink in the uplink container"
  exit 1
fi

secret_name="$(kubectl -n starfleet get deploy uplink -o jsonpath='{.spec.template.spec.volumes[*].secret.secretName}' 2>/dev/null || true)"
if ! echo "$secret_name" | grep -qw 'uplink-db'; then
  echo "FAIL: no volume uses the secret uplink-db"
  exit 1
fi

content="$(kubectl -n starfleet exec deploy/uplink -- cat /etc/uplink/password 2>/dev/null || true)"
if [ "$content" != "orbit-secret-9" ]; then
  echo "FAIL: the running uplink pod cannot read the password from /etc/uplink/password"
  exit 1
fi

echo "PASS: uplink reads the password from a mounted Secret file"
