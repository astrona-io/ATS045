#!/usr/bin/env bash
# Check: starfleet enforces the Pod Security restricted level: a privileged pod and a root pod are rejected, a hardened pod is admitted.
set -uo pipefail

fail=0

pod_compliant() {
  cat <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: admission-test
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 10001
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: app
      image: ghcr.io/stefanprodan/podinfo:6.15.0
      resources:
        limits:
          memory: 128Mi
      securityContext:
        allowPrivilegeEscalation: false
        capabilities:
          drop: ["ALL"]
YAML
}

pod_privileged() {
  cat <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: admission-test
spec:
  containers:
    - name: app
      image: ghcr.io/stefanprodan/podinfo:6.15.0
      securityContext:
        privileged: true
YAML
}

# Runs as root with no hardening: meets the baseline level, not the restricted level.
pod_plain() {
  cat <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: admission-test
spec:
  containers:
    - name: app
      image: ghcr.io/stefanprodan/podinfo:6.15.0
YAML
}

# deploy <image> <with memory limit: yes|no>
deploy() {
  local limits=""
  if [ "$2" = yes ]; then
    limits="          resources:
            limits:
              memory: 128Mi"
  fi
  cat <<YAML
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
          image: $1
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop: ["ALL"]
$limits
YAML
}
deploy_nolimit() { deploy ghcr.io/stefanprodan/podinfo:6.15.0 no; }
deploy_limit() { deploy ghcr.io/stefanprodan/podinfo:6.15.0 yes; }
deploy_latest() { deploy ghcr.io/stefanprodan/podinfo:latest yes; }

# expect <description> <accept|reject> <namespace> <manifest function> [pattern the rejection must contain]
# Sends a server-side dry run and retries for about a minute, because the API server
# needs a few seconds to compile a new policy.
expect() {
  local description="$1" want="$2" namespace="$3" fn="$4" pattern="${5:-}" out rc
  for _ in $(seq 1 12); do
    out="$("$fn" | kubectl apply -n "$namespace" --dry-run=server -f - 2>&1)"
    rc=$?
    if [ "$want" = accept ] && [ "$rc" -eq 0 ]; then
      return 0
    fi
    if [ "$want" = reject ] && [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -qi "$pattern"; then
      return 0
    fi
    sleep 3
  done
  echo "FAIL: $description (wanted $want in $namespace)"
  printf '%s\n' "$out" | tail -3
  fail=1
}

expect "privileged pod was not rejected" reject starfleet pod_privileged "violates PodSecurity"
expect "root pod with no hardening was not rejected by the restricted level" reject starfleet pod_plain "restricted"
expect "hardened pod was rejected" accept starfleet pod_compliant

if [ "$fail" -eq 0 ]; then
  echo "PASS: starfleet enforces the restricted level"
fi
exit "$fail"
