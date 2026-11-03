---
draft: true
exam_objectives:
  - Service Mesh
---
# Summary

- **Identity.** Each sidecar receives a workload certificate from `istiod` after it proves its service account with a token. The certificate carries `spiffe://<trust domain>/ns/<namespace>/sa/<service account>`. The identity follows the service account, so workloads that share one share the identity.
- **Rotation.** Certificates last 24 hours by default and are renewed at about half of their life. The key and serial number change, and the identity stays. A short lifetime narrows the window of a stolen key, and it does not close it.
- **Mutual TLS.** `PERMISSIVE` accepts plain text and mTLS, `STRICT` accepts only mTLS, and a refused plain-text connection ends with no HTTP answer. The most specific `PeerAuthentication` wins: workload, then namespace, then mesh.
- **Port exceptions.** `portLevelMtls` needs a selector and uses the container port. Keep exceptions to data that is safe to read without identity.
- **Authorization.** `AuthorizationPolicy` is evaluated by the destination sidecar. With no policy everything is allowed, and once an `ALLOW` policy selects a workload, everything unlisted is denied with `403`. `principals` needs mTLS.
- **Limits.** The mesh does not know the end user, does not protect plain-text hops, depends on the sidecar being present, does not replace `NetworkPolicy` and does not make retries safe.

<!-- astrona:playground:destroy -->
