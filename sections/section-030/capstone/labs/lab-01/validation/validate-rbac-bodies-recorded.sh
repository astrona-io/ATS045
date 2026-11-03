#!/usr/bin/env bash
# Check: changes to Roles and RoleBindings are recorded at RequestResponse with both bodies.
set -uo pipefail

fail=0
READER="audit-grader-reader-$$"
START_TIME="$(date -u +%Y-%m-%dT%H:%M:%S)"

cleanup() {
  kubectl -n kube-system delete pod "$READER" --ignore-not-found --wait=false >/dev/null 2>&1
}
trap cleanup EXIT

# start_reader: runs a short-lived pod on the control plane node that mounts
# the node directory /var/log/kubernetes/audit read-only. It lets the grader
# read the audit log with kubectl alone, without access to the node shell.
start_reader() {
  kubectl -n kube-system delete pod "$READER" --ignore-not-found --wait=true >/dev/null 2>&1
  kubectl apply -f - >/dev/null <<YAML || return 1
apiVersion: v1
kind: Pod
metadata:
  name: $READER
  namespace: kube-system
spec:
  nodeSelector:
    node-role.kubernetes.io/control-plane: ""
  tolerations:
    - operator: Exists
  restartPolicy: Never
  terminationGracePeriodSeconds: 0
  containers:
    - name: reader
      image: curlimages/curl:8.22.0
      imagePullPolicy: IfNotPresent
      securityContext:
        runAsUser: 0
      command: ["sh", "-c", "sleep 600"]
      volumeMounts:
        - name: audit
          mountPath: /audit
          readOnly: true
  volumes:
    - name: audit
      hostPath:
        path: /var/log/kubernetes/audit
        type: DirectoryOrCreate
YAML
  kubectl -n kube-system wait --for=condition=Ready "pod/$READER" --timeout=120s >/dev/null 2>&1
}

# read_audit_log: prints the whole audit log, one JSON event per line.
read_audit_log() {
  kubectl -n kube-system exec "$READER" -- cat /audit/audit.log 2>/dev/null
}

if ! start_reader; then
  echo "FAIL: the grader could not read the control plane node (is the API server ready?)"
  exit 1
fi

NAME="audit-grader-$(date +%s)"
kubectl -n starfleet create role "$NAME" --verb=get --resource=pods >/dev/null 2>&1 \
  || { echo "FAIL: the grader could not create a Role in starfleet"; exit 1; }
kubectl -n starfleet create rolebinding "$NAME" --role="$NAME" --serviceaccount=outpost:drifter >/dev/null 2>&1 \
  || { echo "FAIL: the grader could not create a RoleBinding in starfleet"; exit 1; }
kubectl -n starfleet delete rolebinding "$NAME" --wait=false >/dev/null 2>&1
kubectl -n starfleet delete role "$NAME" --wait=false >/dev/null 2>&1

find_event() {
  # find_event <verb> <resource>: prints the last ResponseComplete event of this object
  read_audit_log | jq -c --arg since "$START_TIME" --arg name "$NAME" --arg verb "$1" --arg res "$2" 'select(.stage == "ResponseComplete" and .verb == $verb and .objectRef.resource == $res and .objectRef.namespace == "starfleet" and .objectRef.name == $name and .stageTimestamp >= $since)' 2>/dev/null | tail -1
}

for res in roles rolebindings; do
  event=""
  for _ in $(seq 1 10); do
    event="$(find_event create "$res")"
    [ -n "$event" ] && break
    sleep 3
  done
  if [ -z "$event" ]; then
    echo "FAIL: no audit event for the create of the $res object was written"
    fail=1
    continue
  fi
  level="$(printf "%s" "$event" | jq -r '.level')"
  if [ "$level" != "RequestResponse" ]; then
    echo "FAIL: the create of the $res object was recorded at level $level, expected RequestResponse"
    fail=1
    continue
  fi
  if [ "$(printf "%s" "$event" | jq -r 'has("requestObject") and has("responseObject")')" != "true" ]; then
    echo "FAIL: the create event of the $res object has no requestObject and responseObject"
    fail=1
  fi
done
if [ "$fail" -eq 0 ]; then
  echo "PASS: Role and RoleBinding changes are recorded at RequestResponse with both bodies"
fi
exit "$fail"
