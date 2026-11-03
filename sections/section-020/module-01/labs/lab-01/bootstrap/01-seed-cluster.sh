#!/usr/bin/env bash
# Starting state: a private registry with one image, and workloads that cannot
# pull it yet. Environment only. The learner fixes the pull credential.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/registry.yaml"
kubectl -n registry rollout status deployment/registry --timeout=180s
kubectl -n registry wait --for=condition=complete job/seed-images --timeout=300s
kubectl apply -f "$DIR/manifests/lab-start.yaml"
kubectl -n starfleet rollout status deployment/shuttle --timeout=180s
echo "[lab] Ready. scout and probe cannot pull their image yet, on purpose."
