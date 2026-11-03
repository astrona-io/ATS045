# Question

Solve this question on: `terminal`

The security team of the `starfleet` namespace needs a record of who changes access in the cluster. The API server of this kind cluster has no audit logging. Its control plane node runs as a container named `astro-ats-045-capstone-030-01-control-plane`; use `podman exec` or `docker exec` to work on it. A CronJob named `patrol-binder` in `outpost` already runs. Do not delete it, suspend it or change it, and do not leave the API server broken.

1. Turn on audit logging on the API server. It must write the log to `/var/log/kubernetes/audit/audit.log` on the control plane node and read an audit policy file that you write. The log must be kept at most 7 days (`--audit-log-maxage`) with at most 3 rotated files kept (`--audit-log-maxbackup`). Wait until the API server is ready again.

2. The audit policy must follow these rules:
   - Requests for Secrets are recorded at level `Metadata`. The log must never hold a Secret body.
   - Changes to Roles, RoleBindings, ClusterRoles and ClusterRoleBindings (API group `rbac.authorization.k8s.io`) are recorded at level `RequestResponse`.
   - The health check requests `/healthz`, `/livez` and `/readyz` are not recorded.
   - The `RequestReceived` stage is not recorded.
   - Other requests may be recorded at `Metadata`, or not recorded.

3. The `patrol-binder` CronJob runs every two minutes. One run creates the RoleBinding `patrol-view` in `starfleet`. Find that creation in the audit log. Create a ConfigMap named `binding-evidence` in the namespace `starfleet` with three keys: `user`, the user name of the caller; `auditID`, the `auditID` of the successful `create` event; and `subject`, the subject that the RoleBinding grants access to, written as `namespace/name`.

`kubectl` already points at the cluster. The kubelet needs time to start the new API server pod, and `kubectl` fails while it restarts. Run a command again if it fails. A change of the policy file takes effect only when the API server restarts.
