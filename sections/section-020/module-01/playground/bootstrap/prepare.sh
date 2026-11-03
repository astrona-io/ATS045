#!/usr/bin/env bash
# Environment preparation for the private repository playground. No task and no
# grading. Starts the registry, seeds one image and applies the workloads. The
# workloads cannot pull the image yet, on purpose.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/registry.yaml"
kubectl -n registry rollout status deployment/registry --timeout=180s
kubectl -n registry wait --for=condition=complete job/seed-images --timeout=300s
kubectl apply -f "$DIR/manifests/starfleet.yaml"
kubectl -n starfleet rollout status deployment/shuttle --timeout=180s
echo "[playground] Ready."
