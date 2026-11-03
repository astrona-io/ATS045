---
draft: true
exam_objectives:
  - PKI
---
# Rotation, Expiry And Compromise

Every certificate ends. A cluster whose control plane certificates expire stops working: the API server rejects the kubelet, the controller manager loses its connection, and `kubectl` fails with a certificate error. The other end of the same problem is a certificate that leaks while it is still valid. This part looks at lifetimes and renewal, then at what can and cannot be done when a certificate is stolen.

## Lifetimes in a kubeadm cluster

kubeadm creates the certificates with fixed lifetimes. CA certificates last ten years. Leaf certificates, such as the API server serving certificate, the kubelet client certificate and the administrator client certificate, last one year. The two numbers have different consequences:

- A short lifetime for leaf certificates limits how long a stolen certificate is useful, and it forces regular renewal.
- A long lifetime for the CA means that the trust in it does not change for years, and it also means that a leaked CA key is useful for years.

kubeadm renews leaf certificates automatically during `kubeadm upgrade`. A cluster that is never upgraded and never renewed stops working one year after creation. The kubelet client and serving certificates can also rotate on their own, when the kubelet is configured for rotation.

Check the remaining time on the control plane node:

<!-- astrona:playground:renew -->

```sh
export CONTROL_PLANE=astro-ats-045-playground-050-01-control-plane
node() { podman exec -i "$CONTROL_PLANE" "$@"; }
node kubeadm certs check-expiration
```

The table lists each certificate with its expiry date, the time left, the CA that signed it, and whether it is managed externally. The CA rows show a distance of about ten years. The rows of leaf certificates show less than one year. A leaf certificate that is a few weeks from expiry is the first thing to renew. Run the same check on one file when you need a yes or no answer:

```sh
node openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -checkend $((30*24*3600)) && echo "valid for 30 more days" || echo "expires within 30 days"
```

`kubeadm certs renew all` replaces the leaf certificates with new ones, signed by the same CA, but the running components keep using the old files until they are restarted. In a kubeadm cluster the control plane components are static pods, so the renewal is complete only after each one has restarted and read the new files. A renewal that is not followed by a restart does nothing for the running process.

## Rotation has to keep trust

Replacing a certificate is safe when each peer can verify the new one before the old one disappears. Three cases need different handling:

- **A leaf certificate.** Issue the new one from the same CA, install it, and reload the process. Peers that trust the CA accept it immediately.
- **A CA certificate.** Every peer must trust the new CA before any certificate signed by it is used. The safe order is to distribute a trust bundle that holds both the old and the new CA, then reissue the leaf certificates from the new CA, and finally remove the old CA from the bundle. Changing the CA first breaks every peer that has not received it.
- **A signing key.** A CA key replacement is the same as a CA replacement, because the new key signs under a new CA certificate.

Automation shortens leaf lifetimes to hours or days. A service mesh, for example, can renew workload certificates every day without human action. Short lifetimes depend on the renewal path being reliable. An outage in the issuer then becomes an outage of the applications when the existing certificates expire.

## Why a client certificate cannot be revoked

Certificate revocation is a list or an online service that a verifier consults to reject a certificate that is still inside its validity period. The Kubernetes API server does not consult any such list. It checks the signature, the chain and the time. A client certificate that was signed by the cluster CA and has not expired is accepted, even when the user was deleted, the CSR object was deleted, or the key was reported stolen.

This has three consequences:

1. Deleting the `CertificateSigningRequest` object does nothing to the issued certificate. The certificate is a self-contained signed file, and the API server does not look up the object.
2. The user name in the certificate keeps authenticating. Permissions are the only thing that you control, because they live in RBAC.
3. The only way to make the cluster reject the certificate itself is to replace the cluster CA. That invalidates every certificate that it ever signed, and it is a disruptive operation for the whole cluster.

## Respond to a leaked client certificate

Use the properties that you control, in this order:

1. **Remove the permissions.** Find every binding that matches the user and every group in the certificate subject. A binding to the user and a binding to the group both grant access, so one of them alone does not remove it. Search all namespaces, because a RoleBinding is namespaced.
2. **Check what the identity can still do.** Impersonation shows the effective result without the certificate:

```sh
kubectl auth can-i --list --as leaked-user --as-group leaked-group
kubectl auth can-i get secrets -A --as leaked-user --as-group leaked-group
```

3. **Issue a replacement under a new name.** A new user name avoids a collision with the old certificate, which still authenticates under the old name. Use a short `expirationSeconds`.
4. **Use the audit log to see what the certificate did.** Search for the user name and the group. Audit shows requests that were made before the permissions were removed. If the leaked identity had access to Secrets, treat those Secrets as exposed and rotate them.
5. **Plan a CA rotation if the stolen item was the CA key, or the certificate had `system:masters`.** A `system:masters` certificate bypasses RBAC, so removing bindings does not help. Only replacing the CA does.

Practice the removal. Give a user `jane` access, find the binding by subject, delete it, and check the result:

```sh
kubectl -n starfleet create rolebinding jane-view --clusterrole=view --user=jane
kubectl auth can-i list pods -n starfleet --as jane --as-group auditors
kubectl get clusterrolebinding,rolebinding -A -o json | jq -r '.items[] | select(any(.subjects[]?; .kind == "User" and .name == "jane")) | [.kind, .metadata.namespace // "-", .metadata.name] | @tsv'
kubectl -n starfleet delete rolebinding jane-view
kubectl auth can-i list pods -n starfleet --as jane --as-group auditors
```

The first check prints `yes`, the search lists the binding, and the last check prints `no`. The proof is the impersonation request, because the certificate file cannot be inspected for permissions. A certificate of `jane` still authenticates, and it has no permissions.

## Reduce the damage before it happens

- Issue client certificates with the shortest `expirationSeconds` that the job allows, such as an hour for an incident session.
- Use separate users for separate people and jobs, so that a leak points to one identity and one set of bindings.
- Prefer a group-free subject, or keep group names unique to one certificate purpose, so a binding for a group does not outlive the certificate that it was created for.
- Keep the cluster CA key off the nodes where possible, and restrict who can approve certificate requests.
- Alert on the creation of new `CertificateSigningRequest` objects, and on any use of `system:masters`.

## Common pitfalls

> [!WARNING]
> A client certificate stays valid until it expires, even if you delete the request or the user. Remove every user binding and every group binding, and check the result with `kubectl auth can-i --as`. A renewed certificate needs a restart of the process that reads it. Plan CA changes as a trust bundle with both the old and the new CA, or peers that lack the new CA stop trusting the cluster.
