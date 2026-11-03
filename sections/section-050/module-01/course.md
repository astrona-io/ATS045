---
draft: true
exam_objectives:
  - PKI
---
# Certificates And Public Key Infrastructure

Every Kubernetes component and every administrator that connects to the API server proves who it is with a certificate. A certificate that is accepted gives access, and a certificate that is stolen gives the same access to the thief. This module explains what a certificate contains, how a client decides to trust it, how a Kubernetes cluster issues and checks its own certificates, and why a leaked client certificate cannot be revoked.

Keep one sentence in mind: **a certificate is trusted because a trusted authority signed it, and it is accepted for a name, a purpose and a time.** You will read the certificates of a real control plane, verify a chain with `openssl`, issue a client certificate through the Kubernetes certificate API, and see what it takes to remove access that a certificate carries.

The module has three parts. **Keys, Certificates And Chain Verification** explains public and private keys, signatures, certificate authorities, the fields of a certificate and the steps of verification. **Cluster PKI And Client Certificates** covers the certificate authorities of a kubeadm cluster, how the API server maps a certificate to a user and a group, and the CertificateSigningRequest API. **Rotation, Expiry And Compromise** covers certificate lifetimes, `kubeadm certs check-expiration`, why there is no revocation, and a response plan for a leaked certificate.

## Learning objectives

After this module you can:

- Explain what a signature proves and what a certificate binds together.
- Read the subject, issuer, validity, key usage and names of a certificate with `openssl`.
- Verify a certificate against a certificate authority and explain a failure.
- Name the certificate authorities of a kubeadm cluster and what each one signs.
- Issue a short-lived client certificate with the CertificateSigningRequest API.
- Respond to a leaked client certificate when the cluster has no revocation.

## Before you start

You need Kubernetes basics: namespaces, `kubectl` and RBAC roles and bindings. You do not need to know cryptography. Terms are defined where they first appear.

Your playground is a single-node `kind` cluster running Kubernetes 1.35. The control plane node is a container named `astro-ats-045-playground-050-01-control-plane`. It has the certificate files in `/etc/kubernetes/pki`, and `openssl` and `kubeadm` installed.

| Namespace | Object | What it is |
| --- | --- | --- |
| `starfleet` | `scout` | A backend with its own service account |
| `outpost` | none | An empty namespace to test what a new user cannot reach |

You run every command as the cluster administrator.

<!-- astrona:playground -->
