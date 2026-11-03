---
draft: true
exam_objectives:
  - Connectivity
---
# Connectivity And Protected Network Paths

In a default Kubernetes cluster every pod can open a connection to every other pod, and the control plane ports are reachable from the node network. Being able to reach a component says nothing about whether the caller is allowed to use it. This module explains how a request travels from a client to a pod, where encryption starts and stops on that path, how a `NetworkPolicy` decides which connections the network plug-in allows, and how to test a path from the pod that really sends the traffic.

Keep one sentence in mind: **a network policy limits who can connect, encryption protects the bytes on one hop, and neither one decides what a caller is allowed to do.** You will isolate a namespace, open single paths, restrict outgoing traffic including name resolution, and open a management port for one client.

The module has three parts. **Ingress Paths And Where Encryption Stops** follows a request from outside the cluster to a pod and shows where TLS ends. **NetworkPolicy Mechanics** covers default deny, selectors, ports, egress and the DNS exception. **Management Paths And Verifying A Policy** covers the ports of the control plane and node, metrics endpoints, and how to test a policy and read its failures.

## Learning objectives

After this module you can:

- Describe the hops of a request from a client to a pod and where TLS terminates.
- Explain what a default-deny policy selects and what an allow rule adds.
- Write ingress and egress rules with pod selectors, namespace selectors and ports.
- Explain why a policy uses the container port and not the Service port.
- Keep name resolution working under an egress policy.
- Limit a management port to one client and test the result from the right pod.

## Before you start

You need Kubernetes basics: namespaces, Deployments, Services and labels. You do not need to know networking. Terms are defined where they first appear.

Your playground is a single-node `kind` cluster running Kubernetes 1.35. The network plug-in of the cluster enforces `NetworkPolicy`. The control plane node is a container named `astro-ats-045-playground-060-01-control-plane`.

| Namespace | Object | What it is |
| --- | --- | --- |
| `starfleet` | `scout` | podinfo. Application port 9898 (Service port 80) and metrics port 9797 |
| `starfleet` | `probe` | go-httpbin on port 8080 (Service port 80) |
| `starfleet` | `shuttle` | A client with `curl` |
| `outpost` | `drifter` | A client with `curl` |
| `outpost` | `beacon` | go-httpbin on port 8080. It stands for a server outside the application |
| `ops` | `collector` | A client with `curl`, for an operations tool |

You run every command as the cluster administrator. No network policy exists when you start.

<!-- astrona:playground -->
