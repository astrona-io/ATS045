# Overview: Mesh Identity, mTLS And Certificates (Playground)

This playground starts a fresh Kubernetes cluster with Istio in sidecar mode. There is no grading. A service mesh puts a proxy next to each workload so that the proxies, not the applications, encrypt and authenticate traffic between services.

## What's in the box

The single-node kind cluster runs Kubernetes 1.35.8 with Istio 1.31.1 (the `minimal` profile, which installs only the control plane, `istiod`). No `PeerAuthentication` and no `AuthorizationPolicy` exists, so the mesh runs in the default `PERMISSIVE` mode: it accepts both mutual TLS and plain text.

| Namespace | Contents |
| --- | --- |
| `starfleet` | Sidecar injection is on. `scout` (podinfo, application port 9898 and metrics port 9797), `probe`, the `shuttle` client and the `caller` client, which runs as the `probe` service account |
| `outpost` | `drifter`, a client without a sidecar that sends plain text |
| `istio-system` | `istiod`, the control plane and certificate authority of the mesh |

Every application container in `starfleet` has an `istio-proxy` sidecar next to it. The sidecar holds the workload certificate that carries the identity of the pod's service account, in the form `spiffe://cluster.local/ns/<namespace>/sa/<service account>`.

## Helpers

`curl` runs in the application containers `shuttle`, `caller` and `drifter`, and in each `istio-proxy` container. This function prints the identities found in the certificate of a sidecar:

```sh
mesh_identity() {
  kubectl -n starfleet exec "deploy/$1" -c istio-proxy -- curl -s localhost:15000/certs \
    | jq -r '[.certificates[].cert_chain[]?.subject_alt_names[]?.uri] | unique | .[]'
}
```

## Practice tasks

- Print the identity of `scout` and `probe` with `mesh_identity`, and compare it with the service account in each Deployment.
- Send a plain-text request from `drifter` to `scout` while the mesh is `PERMISSIVE`, then apply a `STRICT` `PeerAuthentication` for the namespace and repeat it.
- Open the metrics port of `scout` for plain text with a port-level setting, and prove that the application port stays closed.
- Read the validity period of a workload certificate from `/certs` and compute its lifetime.
- Delete the `scout` pod, read the identity of the new pod, and explain why the certificate changed but the identity did not.
