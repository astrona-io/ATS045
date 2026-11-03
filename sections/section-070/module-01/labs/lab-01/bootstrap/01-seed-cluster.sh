#!/usr/bin/env bash
# Starting state. Environment only: it creates the Starfleet workloads. No admission policy and no Pod Security label exist.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
for entry in starfleet/scout starfleet/shuttle outpost/drifter; do
  kubectl -n "${entry%/*}" rollout status "deployment/${entry#*/}" --timeout=180s
done
echo "[lab] Ready."
