#!/usr/bin/env bash
# Check: restricted-style container settings on the pod template.
set -uo pipefail

get() { kubectl -n forge get deploy build-runner -o jsonpath="$1" 2>/dev/null || true; }

[ "$(get '{.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem}')" = "true" ] || { echo "FAIL: readOnlyRootFilesystem is not true"; exit 1; }
[ "$(get '{.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation}')" = "false" ] || { echo "FAIL: allowPrivilegeEscalation is not false"; exit 1; }
[ "$(get '{.spec.template.spec.containers[0].securityContext.capabilities.drop[0]}')" = "ALL" ] || { echo "FAIL: capabilities do not drop ALL"; exit 1; }
run_non_root="$(get '{.spec.template.spec.securityContext.runAsNonRoot}')$(get '{.spec.template.spec.containers[0].securityContext.runAsNonRoot}')"
echo "$run_non_root" | grep -q true || { echo "FAIL: runAsNonRoot is not true"; exit 1; }

echo "PASS: the container is hardened"
