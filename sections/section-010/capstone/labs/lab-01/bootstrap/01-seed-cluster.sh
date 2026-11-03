#!/usr/bin/env bash
# Starting state: build-runner in forge runs as the default ServiceAccount, which
# has the admin role, with a tag image, a token in the environment and a
# writable root file system. The learner hardens it.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
kubectl -n forge rollout status deployment/build-runner --timeout=180s
echo "[lab] Ready."
