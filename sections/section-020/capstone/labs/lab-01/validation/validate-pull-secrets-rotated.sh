#!/usr/bin/env bash
# Check: registry-pull in starfleet and outpost holds the puller-v2 credential.
set -uo pipefail

for ns in starfleet outpost; do
  user="$(kubectl -n "$ns" get secret registry-pull -o jsonpath='{.data.\.dockerconfigjson}' 2>/dev/null | base64 -d | jq -r '.auths["localhost:30500"].username' 2>/dev/null || true)"
  if [ "$user" != "puller-v2" ]; then
    echo "FAIL: registry-pull in ${ns} has user '${user}' for localhost:30500, expected puller-v2"
    exit 1
  fi
done

echo "PASS: both namespaces hold the puller-v2 credential"
