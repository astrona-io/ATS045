#!/usr/bin/env bash
# Starting state for the network lab. Environment only: it creates the Starfleet
# workloads. No NetworkPolicy exists, so every pod can reach every pod.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
for entry in starfleet/scout starfleet/probe starfleet/shuttle outpost/drifter outpost/beacon; do
  kubectl -n "${entry%/*}" rollout status "deployment/${entry#*/}" --timeout=180s
done
echo "[lab] Ready."
