#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

digest="$(kubectl -n starfleet exec deploy/shuttle -- curl -s -I -u puller-v2:pull-pass-8 -H 'Accept: application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json' http://registry.registry.svc.cluster.local:5000/v2/starfleet/podinfo/manifests/6.15.0 | tr -d '\r' | awk -F': ' 'tolower($1)=="docker-content-digest"{print $2}')"
image="localhost:30500/starfleet/podinfo@${digest}"

for ns in starfleet outpost; do
  kubectl -n "$ns" create secret docker-registry registry-pull --docker-server=localhost:30500 --docker-username=puller-v2 --docker-password=pull-pass-8 --dry-run=client -o yaml | kubectl apply -f -
done

kubectl -n starfleet set image deployment/scout "scout=${image}"
kubectl -n outpost set image deployment/drifter "drifter=${image}"
kubectl -n starfleet patch deployment scout -p '{"spec":{"template":{"spec":{"containers":[{"name":"scout","imagePullPolicy":"Always"}]}}}}'
kubectl -n outpost patch deployment drifter -p '{"spec":{"template":{"spec":{"containers":[{"name":"drifter","imagePullPolicy":"Always"}]}}}}'
kubectl -n starfleet rollout status deployment/scout --timeout=180s
kubectl -n outpost rollout status deployment/drifter --timeout=180s
echo "[solution] Applied."
