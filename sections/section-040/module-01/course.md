---
draft: true
exam_objectives:
  - Service Mesh
---
# Service Mesh Identity And Policy

Two services in a cluster talk over the network. Without a mesh, each application must bring its own encryption, its own way to prove who it is, and its own rules for who may call it. A service mesh moves that work into a proxy that runs next to every workload. The proxies set up encrypted connections between each other, check certificates, and enforce policy before a request reaches the application. This module shows how that works in Istio, and where it stops.

Keep one sentence in mind: **the mesh proves which workload is calling, and a separate policy decides what that workload may do.** You will read the workload certificate of a sidecar, turn on mutual TLS for a namespace, open one port for a client that has no sidecar, and then restrict a service to one caller, one method and one port.

The module has three parts. **Mesh Identity And Certificates** explains sidecar injection, the certificate authority in `istiod`, the SPIFFE identity inside a workload certificate, and certificate rotation. **Mutual TLS Modes And Peer Authentication** covers `PERMISSIVE` and `STRICT`, namespace-wide and workload-specific policy, port-level exceptions, and what a client without a sidecar sees. **Authorization And Mesh Limits** covers `AuthorizationPolicy`, default deny behavior, and what a mesh does not do: end-user identity, plain-text hops, retries and `NetworkPolicy`.

## Learning objectives

After this module you can:

- Explain how a sidecar gets a workload certificate and what identity the certificate carries.
- Read the identity and the validity period of a workload certificate from the proxy.
- Choose between `PERMISSIVE` and `STRICT` mutual TLS and predict what a client without a sidecar receives.
- Write a workload-specific `PeerAuthentication` with a port-level exception.
- Write an `AuthorizationPolicy` that allows one identity, one method and one port.
- State which risks remain after mutual TLS: plain-text hops, end-user permission, unsafe retries and network reachability.

## Before you start

You need Kubernetes basics: namespaces, Deployments, Services, ServiceAccounts and `kubectl`. You do not need to know Istio. Every term is defined where it first appears.

Your playground is a single-node `kind` cluster running Kubernetes 1.35 with Istio 1.31.1 in sidecar mode. The mesh starts in the default `PERMISSIVE` mode, and no policy exists.

| Namespace | Object | What it is |
| --- | --- | --- |
| `starfleet` | `scout` | A backend that serves its application on port 9898 (Service port 80) and its metrics on port 9797 |
| `starfleet` | `probe` | A second backend |
| `starfleet` | `shuttle` | A client with a sidecar, running as the `shuttle` service account |
| `starfleet` | `caller` | A client with a sidecar, running as the `probe` service account |
| `outpost` | `drifter` | A client without a sidecar that sends plain text |
| `istio-system` | `istiod` | The control plane and certificate authority |

You run every command as the cluster administrator.

<!-- astrona:playground -->
