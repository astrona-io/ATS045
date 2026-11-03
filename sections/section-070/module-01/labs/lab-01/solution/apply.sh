#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kubectl apply -f "$DIR/solution.yaml"
echo "[solution] Applied. Waiting until the policy is active."
for _ in $(seq 1 30); do
  if kubectl apply -n starfleet --dry-run=server -f - >/dev/null 2>&1 <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: admission-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: admission-test
  template:
    metadata:
      labels:
        app: admission-test
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 10001
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: app
          image: ghcr.io/stefanprodan/podinfo:6.15.0
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop: ["ALL"]
YAML
  then
    sleep 2
  else
    echo "[solution] Policy is active."
    exit 0
  fi
done
echo "[solution] Policy was not active in time." >&2
exit 1
