# Overview: Cluster PKI And Client Certificates (Playground)

This playground starts a fresh Kubernetes cluster. There is no grading. The cluster built by kubeadm inside the kind node has its own certificate authority, and every control plane component and every client certificate leads back to it.

## What's in the box

A single-node kind cluster with Kubernetes 1.35.8. The certificate files are on the control plane node in `/etc/kubernetes/pki`. The node is a container named `astro-ats-045-playground-050-01-control-plane`, and `openssl` and `kubeadm` are installed inside it.

| Namespace | Contents |
| --- | --- |
| `starfleet` | `scout`, a podinfo backend, and its service account |
| `outpost` | Empty. Use it to test what a new user cannot reach |

## Helpers

Run commands on the node with this function. It uses Podman, and you can replace `podman` with `docker`:

```sh
export CONTROL_PLANE=astro-ats-045-playground-050-01-control-plane
node() { podman exec -i "$CONTROL_PLANE" "$@"; }
node ls /etc/kubernetes/pki
```

## Practice tasks

- Print the subject, issuer, validity and Subject Alternative Names of `apiserver.crt`, and compare the issuer with the subject of `ca.crt`.
- Verify the chain of `apiserver.crt` against `ca.crt` with `openssl verify`, then try it against `etcd/ca.crt` and read the failure.
- Create a key and a certificate signing request for a user, submit it with the CertificateSigningRequest API, approve it, and read the issued certificate.
- Give the user a `Role` and a `RoleBinding`, and test the access with `kubectl auth can-i --as`.
- Run `kubeadm certs check-expiration` on the node and find which certificates expire first.
