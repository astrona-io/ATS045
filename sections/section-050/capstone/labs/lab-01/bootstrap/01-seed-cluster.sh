#!/usr/bin/env bash
# Starting state for the PKI capstone. Environment only: it creates the
# Starfleet workload and the over-broad bindings of the leaked certificate.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
kubectl -n starfleet rollout status deployment/scout --timeout=180s
echo "[lab] Ready."
