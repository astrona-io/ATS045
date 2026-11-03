#!/usr/bin/env bash
# Starting state for the PKI lab. Environment only: it creates the Starfleet
# workload. The learner issues the certificate and writes the evidence.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
kubectl -n starfleet rollout status deployment/scout --timeout=180s
echo "[lab] Ready."
