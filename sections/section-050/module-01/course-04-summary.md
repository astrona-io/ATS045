---
draft: true
exam_objectives:
  - PKI
---
# Summary

- **Signatures and certificates.** A signature made with a private key is checked with the public key. A certificate binds a name and a purpose to a public key, and a trusted authority signs it. Verification checks the signature, the chain to a trusted root, the time, the name and the purpose.
- **Disabled verification.** Skipping verification removes all of these checks together, so read which check failed.
- **Cluster authorities.** A kubeadm cluster has a cluster CA, an etcd CA and a front proxy CA, plus a separate key pair for service account tokens. The cluster CA key can sign any identity, including `system:masters`.
- **Client certificates.** The API server takes the user from the CN and the groups from the O fields. The certificate holds no permissions, and RBAC bindings by user or group grant them.
- **CertificateSigningRequest.** The user keeps the key, an administrator approves the request, and the signer issues a certificate. `expirationSeconds` limits the lifetime.
- **Expiry.** Leaf certificates last one year and CA certificates ten years in kubeadm. A renewed certificate needs a restart of the process.
- **Compromise.** Client certificates cannot be revoked. Remove every user and group binding, issue a replacement under a new name, check the audit log, and rotate a CA only through a trust bundle.

<!-- astrona:playground:destroy -->
