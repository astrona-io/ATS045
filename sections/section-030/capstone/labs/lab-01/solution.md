# Solution

Solve this lab on `terminal`. Run `astrona submit` after each step. The lab is built from documentation and has not been booted yet. Run every `podman exec` command on your own machine. If you use Docker, replace `podman` with `docker`.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-030/capstone/labs/lab-01
```

## Step 1: Write the audit policy on the node

```sh
export NODE=astro-ats-045-capstone-030-01-control-plane
podman exec "$NODE" mkdir -p /etc/kubernetes/audit /var/log/kubernetes/audit
```

Save the policy on the node. The first matching rule applies, so the Secret rule comes before the rule that drops reads:

```sh
podman exec -i "$NODE" sh -c 'cat > /etc/kubernetes/audit/audit-policy.yaml' <<'EOF'
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages:
  - RequestReceived
rules:
  - level: None
    nonResourceURLs: ["/healthz*", "/livez*", "/readyz*", "/version"]
  - level: Metadata
    resources:
      - group: ""
        resources: ["secrets"]
  - level: RequestResponse
    resources:
      - group: "rbac.authorization.k8s.io"
        resources: ["roles", "rolebindings", "clusterroles", "clusterrolebindings"]
  - level: None
    verbs: ["get", "list", "watch"]
  - level: Metadata
EOF
```

## Step 2: Add the flags and mounts to the API server

Back up the manifest outside the watched directory, then edit it on the node:

```sh
podman exec "$NODE" cp /etc/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/kube-apiserver.backup.yaml
podman exec -it "$NODE" vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

Under `command`, add these four flags after `- kube-apiserver`:

```yaml
    - --audit-policy-file=/etc/kubernetes/audit/audit-policy.yaml
    - --audit-log-path=/var/log/kubernetes/audit/audit.log
    - --audit-log-maxage=7
    - --audit-log-maxbackup=3
```

Under `volumeMounts` add the two mounts, and under `volumes` add the two host paths:

```yaml
    - mountPath: /etc/kubernetes/audit
      name: audit-policy
      readOnly: true
    - mountPath: /var/log/kubernetes/audit
      name: audit-log
```

```yaml
  - hostPath:
      path: /etc/kubernetes/audit
      type: Directory
    name: audit-policy
  - hostPath:
      path: /var/log/kubernetes/audit
      type: DirectoryOrCreate
    name: audit-log
```

Wait until `kubectl get --raw=/readyz` answers `ok`. Run `astrona submit`. The first, third and fourth checks should pass.

## Step 3: Find the RoleBinding create

Wait for the next two-minute CronJob run, then select the event:

```sh
podman exec "$NODE" cat /var/log/kubernetes/audit/audit.log \
  | jq -c 'select(.stage == "ResponseComplete" and .verb == "create" and .objectRef.resource == "rolebindings" and .objectRef.name == "patrol-view")'
```

Read `user.username`, `auditID` and `requestObject.subjects`.

## Step 4: Record the evidence

Replace the three values with what you read:

```sh
kubectl -n starfleet create configmap binding-evidence \
  --from-literal=user=<USER> \
  --from-literal=auditID=<AUDIT_ID> \
  --from-literal=subject=outpost/drifter
```

Run `astrona submit`. All six checks should pass.

## Why the shortcuts fail

Recording RoleBindings at `Metadata` shows the caller but not the bound subject, so `rbac-bodies-recorded` and `binding-evidence` fail. Putting the read-dropping rule before the Secret rule hides Secret reads, and `secret-metadata-only` fails. A `RequestResponse` rule for Secrets writes the Secret data into the log.
