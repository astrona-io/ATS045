#!/usr/bin/env bash
# Check: scout and drifter use the repository localhost:30500/starfleet/podinfo
# with the digest that the registry reports for tag 6.15.0.
set -uo pipefail

registry_digest() {
  kubectl -n starfleet exec deploy/shuttle -- curl -s -I -u puller-v2:pull-pass-8 -H 'Accept: application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json' http://registry.registry.svc.cluster.local:5000/v2/starfleet/podinfo/manifests/6.15.0 | tr -d '\r' | awk -F': ' 'tolower($1)=="docker-content-digest"{print $2}'
}

expected="$(registry_digest)"
if ! echo "$expected" | grep -Eq '^sha256:[0-9a-f]{64}$'; then
  echo "FAIL: could not read the digest of tag 6.15.0 from the registry (got '${expected}')"
  exit 1
fi
for target in starfleet/scout outpost/drifter; do
  ns="${target%%/*}"; name="${target##*/}"
  image="$(kubectl -n "$ns" get deploy "$name" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)"
  if [ "$image" != "localhost:30500/starfleet/podinfo@${expected}" ]; then
    echo "FAIL: ${name} uses '${image}', expected localhost:30500/starfleet/podinfo@${expected}"
    exit 1
  fi
done

echo "PASS: scout and drifter are pinned to the registry digest"
