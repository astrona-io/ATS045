---
draft: true
exam_objectives:
  - Supply Chain Security
---
# Credentials And Service Account Tokens

A signed, pinned image can still leak. A password in an environment variable is visible to anyone who can run `kubectl describe` on the pod, to a process that dumps its environment, and to the diagnostic bundles that people attach to tickets. This part moves a credential into a Secret that is mounted as a file, and removes the Kubernetes API token that most pods receive without asking for it.

## Why an environment variable is a weak place

The `uplink` Deployment in `starfleet` reads its database password from the environment variable `DB_PASSWORD`, and the value is written in the Deployment manifest. Look at what that means:

<!-- astrona:playground:renew -->

```sh
kubectl -n starfleet get deploy uplink -o jsonpath='{.spec.template.spec.containers[0].env}'
```

The password prints in clear text, so every person and tool with `get` on Deployments can read it. The manifest also lives in a Git repository or a pipeline log. An environment variable is copied into every child process, appears in crash reports and is shown by `kubectl describe pod`.

A Kubernetes **Secret** is an API object for sensitive values. It does not hide anything by itself. Its data is only base64-encoded, and the API server stores it in etcd, so protection comes from three controls: RBAC that limits who can `get` the Secret, encryption at rest for etcd, and a delivery method that keeps the value away from logs.

## Create the Secret and mount it as a file

A Secret can reach a container as an environment variable or as a file in a volume. A mounted file is not part of the process environment, so child processes do not inherit it. Kubernetes also updates a mounted Secret when the Secret changes (for volumes that are not `subPath` mounts), while an environment variable is fixed at container start.

Create the Secret from a literal value:

```sh
kubectl -n starfleet create secret generic uplink-db --from-literal=password='orbit-secret-9'
```

Now replace the environment variable with a volume. Save this as `uplink-patch.yaml`:

```yaml
spec:
  template:
    spec:
      containers:
        - name: uplink
          env: null
          volumeMounts:
            - name: db-credentials
              mountPath: /etc/uplink
              readOnly: true
      volumes:
        - name: db-credentials
          secret:
            secretName: uplink-db
            defaultMode: 0400
```

Apply it as a strategic merge patch:

```sh
kubectl -n starfleet patch deployment uplink --patch-file uplink-patch.yaml
kubectl -n starfleet rollout status deployment/uplink
```

Setting `env: null` deletes the field in a strategic merge patch. The `defaultMode: 0400` makes the file readable only by its owner. Check that the application can still read the value and that the environment no longer has it:

```sh
kubectl -n starfleet exec deploy/uplink -- cat /etc/uplink/password
kubectl -n starfleet get deploy uplink -o jsonpath='{.spec.template.spec.containers[0].env}'
```

The first command prints the password from the file. The second prints nothing, because the field is gone. The value still exists in the Secret, so the real work remains: limiting who can read that Secret.

## The Kubernetes API token

Every pod gets a ServiceAccount, and by default the kubelet mounts a token for it in `/var/run/secrets/kubernetes.io/serviceaccount`. This token authenticates the pod to the API server. Most application pods never call the API server, so the token is an unused credential that an attacker who gets code execution in the pod can steal and use.

A modern token is a projected token: it is bound to the pod, expires, and stops working when the pod is deleted. That limits damage, but it does not remove the risk while the pod runs. If the ServiceAccount has RBAC permissions, those permissions are available to the attacker.

Two fields turn the token off. Setting `automountServiceAccountToken: false` on the pod specification (or on the ServiceAccount) stops the mount. Check the pod before the change:

```sh
kubectl -n starfleet exec deploy/uplink -- ls /var/run/secrets/kubernetes.io/serviceaccount
```

You should see the files `ca.crt`, `namespace` and `token`. Now turn the mount off in the Deployment:

```sh
kubectl -n starfleet patch deployment uplink -p '{"spec":{"template":{"spec":{"automountServiceAccountToken":false}}}}'
kubectl -n starfleet rollout status deployment/uplink
```

Run the `ls` again. The directory no longer exists, and the pod cannot call the API server as a ServiceAccount. The pod-level setting wins over the ServiceAccount setting when both are set.

## Least privilege for the runtime

Least privilege means each process holds only the authority it needs. For credentials, that means one Secret per consumer, mounted only in the pod that needs it, readable only by the Roles that must manage it, with a rotation plan. Rotation needs two steps: issue the new credential and add it to the consumer, then revoke the old credential at the issuer. Changing only the stored value while the old password still works at the database leaves the old credential alive.

You now have a pinned image and a protected credential. Together they limit what a compromised build and a compromised pod can do.

## Common pitfalls

> [!WARNING]
> - Believing that base64 in a Secret is encryption. It is encoding. Anyone who can read the Secret can decode it.
> - Using `subPath` for a mounted Secret and expecting it to update when the Secret changes. `subPath` mounts do not receive updates.
> - Turning the token off in the pod but leaving a broad Role bound to the ServiceAccount. Another pod that uses the account still has the rights.
> - Rotating the Secret value without revoking the old credential at the issuer.
