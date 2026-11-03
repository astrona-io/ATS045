---
draft: true
exam_objectives:
  - PKI
---
# Cluster PKI And Client Certificates

A Kubernetes cluster is a set of components that authenticate each other with certificates. The cluster does not use a public certificate authority for this. It creates its own, signs every component certificate with it, and trusts only it. This part shows which authorities and certificates exist, how the API server turns a certificate into a user and a group, and how an administrator gets a new client certificate.

## The certificate authorities of a cluster

kubeadm, and kind which uses it, creates three separate certificate authorities in `/etc/kubernetes/pki`. Each one has its own key and signs a different group of certificates:

| Authority | Files | What it signs |
| --- | --- | --- |
| Cluster CA | `ca.crt`, `ca.key` | The API server serving certificate, the API server client certificate for kubelets, the kubelet client and serving certificates, and the client certificates of the controller manager, the scheduler and the administrator |
| etcd CA | `etcd/ca.crt`, `etcd/ca.key` | The etcd server, the etcd peer and the API server client certificate for etcd |
| Front proxy CA | `front-proxy-ca.crt`, `front-proxy-ca.key` | The client certificate that the API server uses to talk to aggregated API servers |

Splitting the authorities limits what a compromise gives. Someone who steals a certificate that the cluster CA signed cannot talk to etcd, because etcd trusts only the etcd CA. The cluster CA key is the most valuable file in the cluster. Anyone who holds it can sign a certificate for any user and any group, including `system:masters`, and the API server accepts it.

A separate key pair signs service account tokens: `sa.key` and `sa.pub`. Service account tokens are JSON Web Tokens, not certificates, and they are checked with the public key.

List the files and the identities in them on the node:

<!-- astrona:playground:renew -->

```sh
export CONTROL_PLANE=astro-ats-045-playground-050-01-control-plane
node() { podman exec -i "$CONTROL_PLANE" "$@"; }
node sh -c 'for f in /etc/kubernetes/pki/*.crt /etc/kubernetes/pki/etcd/*.crt; do printf "%s  " "$f"; openssl x509 -in "$f" -noout -subject; done'
```

You see one certificate per component, with a subject that names it. The administrator client certificate is not in this directory. It is embedded in a kubeconfig file.

## How the API server reads a client certificate

When a client connects to the API server with a certificate, the API server first runs the TLS verification against its client CA file. If the certificate was signed by the cluster CA and is valid, authentication succeeds. The API server then reads the identity from the subject:

- The **common name (CN)** becomes the user name.
- Each **organization (O)** becomes a group name. A certificate can have several.

A certificate with `CN=jane, O=auditors` makes the request come from the user `jane`, who is in the group `auditors`. RBAC bindings then match on the user, on the group, or on both. The certificate carries no permissions. A certificate for a user who has no bindings authenticates and can do nothing.

The administrator that kind creates is a client of the cluster CA with the group `kubeadm:cluster-admins`. Read it from the kubeconfig that the node holds:

```sh
node sh -c "grep client-certificate-data /etc/kubernetes/admin.conf | awk '{print \$2}' | base64 -d | openssl x509 -noout -subject"
```

The subject shows an organization that a built-in binding maps to `cluster-admin`. A certificate with the organization `system:masters` skips RBAC altogether, because the API server hard-codes that group as allowed. This group is why the cluster CA key and any certificate for `system:masters` are the most sensitive credentials in the cluster.

## The CertificateSigningRequest API

An administrator should not copy the CA key to sign certificates by hand. Kubernetes has an API for it. The flow has four steps:

1. The user creates a private key and a certificate signing request (CSR) file. The key never leaves the user's machine. The CSR contains the public key and the requested subject.
2. The user submits the CSR as a `CertificateSigningRequest` object, with a signer name and a list of usages.
3. An administrator reviews the object and approves it with `kubectl certificate approve`.
4. The signer in the controller manager signs the certificate with the cluster CA and writes it to `status.certificate`.

For a client certificate that the API server will accept, the signer name is `kubernetes.io/kube-apiserver-client`. The object sets `expirationSeconds` to limit the lifetime. The minimum is 600 seconds, and the signer may issue a shorter lifetime than the request but not a longer one. Without `expirationSeconds`, the lifetime follows the controller manager setting, which is one year by default.

Approval of a CSR is a permission: the verb `approve` on the resource `signers`. A reviewer who approves a request with the organization `system:masters` creates a certificate that bypasses RBAC, so check the requested subject before approval, and give the permission to few people.

## Issue a client certificate

Create a key and a request for a user `jane` in the group `auditors`. The subject carries the name and the group:

```sh
node openssl req -new -newkey rsa:2048 -nodes -keyout /tmp/jane.key -subj "/CN=jane/O=auditors" > jane.csr
```

Submit it with a one-day lifetime:

```sh
cat > jane-csr.yaml <<YAML
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: jane
spec:
  request: $(base64 < jane.csr | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages: ["client auth"]
YAML
kubectl apply -f jane-csr.yaml
kubectl get csr jane
```

The condition is `Pending`. Nothing is issued until someone approves it:

```sh
kubectl certificate approve jane
kubectl get csr jane
kubectl get csr jane -o jsonpath='{.status.certificate}' | base64 -d | node openssl x509 -noout -subject -dates
```

The subject shows `CN=jane` and `O=auditors`, and the dates cover about one day. Verify it against the cluster CA like any other certificate:

```sh
kubectl get csr jane -o jsonpath='{.status.certificate}' | base64 -d | node sh -c 'cat > /tmp/jane.crt && openssl verify -CAfile /etc/kubernetes/pki/ca.crt /tmp/jane.crt'
```

## Permissions come from RBAC

The new user can authenticate, and they can do nothing yet. Check it with impersonation, which asks the API server what the user would be allowed to do:

```sh
kubectl auth can-i list pods -n starfleet --as jane --as-group auditors
```

The answer is `no`. Give the user read access to pods in one namespace:

```sh
kubectl -n starfleet create role pod-reader --verb=get,list --resource=pods
kubectl -n starfleet create rolebinding jane-pods --role=pod-reader --user=jane
kubectl auth can-i list pods -n starfleet --as jane --as-group auditors
kubectl auth can-i list pods -n outpost --as jane --as-group auditors
kubectl auth can-i get secrets -n starfleet --as jane --as-group auditors
```

The first answer is `yes`, and the other two are `no`. The certificate named the user. The Role and RoleBinding limited what the user could do and where.

Notice that RBAC matches the name `jane` and not the certificate. The API server does not store a list of issued certificates. If a second certificate with `CN=jane` is signed, it gets the same permissions, and the API server cannot tell the two apart.

## Components also use certificates

The kubelet on each node has a client certificate that the API server maps to the user `system:node:<node name>` in the group `system:nodes`. The node authorizer limits that identity to the objects that its own pods use. The controller manager and the scheduler each have their own client certificate with a user name such as `system:kube-scheduler`. Using a separate identity for each component allows RBAC to give each one only what it needs, and it allows the audit log to show which component acted. Reusing one powerful credential for all of them gives up both limits.

## Common pitfalls

> [!WARNING]
> A certificate holds an identity and no permissions, so a certificate request is an access request and needs review before approval. The subject decides the user and the groups, and RBAC bindings can use either one. Set `expirationSeconds`, because the default lifetime is long and a client certificate cannot be revoked. Never share the cluster CA key, and never approve a certificate for `system:masters`.
