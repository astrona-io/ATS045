#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

kubectl -n starfleet create secret docker-registry registry-pull --docker-server=localhost:30500 --docker-username=puller --docker-password=pull-pass-7
for account in scout probe; do
  kubectl -n starfleet patch serviceaccount "$account" -p '{"imagePullSecrets":[{"name":"registry-pull"}]}'
  kubectl -n starfleet rollout restart "deployment/${account}"
done
for name in scout probe; do
  kubectl -n starfleet rollout status "deployment/${name}" --timeout=180s
done
echo "[solution] Applied."
