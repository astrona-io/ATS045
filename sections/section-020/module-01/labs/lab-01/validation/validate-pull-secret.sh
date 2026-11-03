#!/usr/bin/env bash
# Check: Secret registry-pull in starfleet is a dockerconfigjson Secret for
# localhost:30500 with the puller account.
set -uo pipefail

type="$(kubectl -n starfleet get secret registry-pull -o jsonpath='{.type}' 2>/dev/null || true)"
if [ "$type" != "kubernetes.io/dockerconfigjson" ]; then
  echo "FAIL: secret registry-pull has type '${type}', expected kubernetes.io/dockerconfigjson"
  exit 1
fi
user="$(kubectl -n starfleet get secret registry-pull -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d | jq -r '.auths["localhost:30500"].username' 2>/dev/null || true)"
if [ "$user" != "puller" ]; then
  echo "FAIL: the secret has no credential for localhost:30500 with the user puller (got '${user}')"
  exit 1
fi

echo "PASS: registry-pull holds the puller credential for localhost:30500"
