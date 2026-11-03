#!/usr/bin/env bash
# Check: no pull Secret anywhere in the cluster still holds the revoked puller
# account.
set -uo pipefail

found=""
for entry in $(kubectl get secrets -A --field-selector type=kubernetes.io/dockerconfigjson -o json | jq -r '.items[] | .metadata.namespace + "/" + .metadata.name + "=" + ((.data[".dockerconfigjson"] | @base64d | fromjson | .auths | to_entries[] | .value.username) // "")'); do
  case "$entry" in *=puller) found="$entry";; esac
done
if [ -n "$found" ]; then
  echo "FAIL: the revoked credential is still stored in ${found%%=*}"
  exit 1
fi

echo "PASS: no Secret holds the revoked puller credential"
