---
draft: true
exam_objectives:
  - Connectivity
---
# Summary

- **Request path.** A request crosses several connections. Each connection has its own encryption and its own allowed callers. A Service rewrites its address and port to a pod address and the container port.
- **TLS termination.** An entry component that terminates TLS and forwards plain HTTP leaves the next hop readable. A forwarding header is text that a client can write, so only a trusted proxy can be believed.
- **Isolation.** A pod is isolated in a direction when a policy selects it for that direction. An isolated pod accepts only what some rule allows. Rules are added together, and no policy can deny what another allows.
- **Selectors.** `namespaceSelector` and `podSelector` in the same item combine with AND. In two items they combine with OR. An empty `from` or `to` opens every source or destination.
- **Ports.** A policy matches the container port after the Service rewrite.
- **Egress.** An isolated pod needs a rule for CoreDNS on UDP and TCP port 53, or names do not resolve.
- **Management ports.** The API server, kubelet and etcd ports are protected by authentication, authorization and where the node network is exposed. Pod policies do not select the host ports.
- **Verification.** Test from the affected pod, test an allowed and a blocked path, and read the failure: exit code 6 is a name, 7 is a refusal and 28 is a drop.

<!-- astrona:playground:destroy -->
