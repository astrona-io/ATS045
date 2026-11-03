#!/usr/bin/env bash
# Check: the ConfigMap binding-evidence in starfleet names the caller, the audit ID and the bound subject of a real create of the RoleBinding patrol-view.
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

answer_user="$(kubectl -n starfleet get configmap binding-evidence -o jsonpath='{.data.user}' 2>/dev/null)"
answer_id="$(kubectl -n starfleet get configmap binding-evidence -o jsonpath='{.data.auditID}' 2>/dev/null)"
answer_subject="$(kubectl -n starfleet get configmap binding-evidence -o jsonpath='{.data.subject}' 2>/dev/null)"
if [ -z "$answer_user" ] || [ -z "$answer_id" ] || [ -z "$answer_subject" ]; then
  echo "FAIL: the ConfigMap binding-evidence in starfleet needs the keys user, auditID and subject"
  exit 1
fi

event="$(read_audit_log | jq -c --arg id "$answer_id" 'select(.auditID == $id and .stage == "ResponseComplete")' 2>/dev/null | tail -1)"
if [ -z "$event" ]; then
  echo "FAIL: the audit log has no completed event with auditID $answer_id"
  exit 1
fi
if [ "$(printf "%s" "$event" | jq -r '.verb + " " + .objectRef.resource + " " + .objectRef.namespace + "/" + .objectRef.name + " " + (.responseStatus.code|tostring)')" != "create rolebindings starfleet/patrol-view 201" ]; then
  echo "FAIL: auditID $answer_id is not a successful create of the RoleBinding patrol-view in starfleet"
  fail=1
fi
expected_user="system:serviceaccount:outpost:patrol-binder"
log_user="$(printf "%s" "$event" | jq -r '.user.username')"
if [ "$log_user" != "$expected_user" ]; then
  echo "FAIL: the event is by $log_user, expected $expected_user"
  fail=1
fi
if [ "$answer_user" != "$log_user" ]; then
  echo "FAIL: the answer names the user '$answer_user', but the audit event shows '$log_user'"
  fail=1
fi
log_subject="$(printf "%s" "$event" | jq -r '.requestObject.subjects[0].namespace + "/" + .requestObject.subjects[0].name' 2>/dev/null)"
if [ "$log_subject" != "outpost/drifter" ]; then
  echo "FAIL: the event has no request body naming the subject outpost/drifter. The log must record RoleBindings at RequestResponse or Request."
  fail=1
elif [ "$answer_subject" != "$log_subject" ]; then
  echo "FAIL: the answer names the subject '$answer_subject', but the request body names '$log_subject'"
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  echo "PASS: the answer names the caller, audit ID and bound subject of the RoleBinding create"
fi
exit "$fail"
