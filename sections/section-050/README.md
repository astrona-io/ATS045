---
draft: true
exam_objectives:
  - PKI
---
# PKI

This section covers public key infrastructure in Kubernetes. It explains keys, certificates and chain verification, the certificate authorities of a cluster and client certificates, and rotation, expiry and the response to a leaked certificate.

The section has one module, Certificates And Public Key Infrastructure. It has a playground, a graded lab and a capstone lab on a local kind cluster, and ends with a knowledge check. Each part is followed by the lab that practises it, and the module ends with a summary.

## Learning Outcomes

- Read a certificate and verify a chain with openssl
- Name the authorities of a kubeadm cluster and what each one signs
- Issue a short-lived client certificate with the CertificateSigningRequest API
- Explain why a client certificate cannot be revoked and remove its access through RBAC
- Plan certificate and CA rotation without breaking trust

## Contents

| Item | What it is |
| --- | --- |
| Keys, Certificates And Chain Verification | Reading part |
| Cluster PKI And Client Certificates | Reading part |
| Rotation, Expiry And Compromise | Reading part |
| Summary | Reading part |
| Read The Cluster CA And Issue A Short-Lived Client Certificate | Graded module lab (intermediate) |
| Replace A Leaked Client Certificate | Section capstone lab (advanced) |
| Knowledge check | `quiz.yaml`, pass score 70 |

## Authoring Status

The labs and the playground in this section are UNTESTED. They were built from documentation and checked only with static tools (`astrona validate`, `bash -n`, YAML parsing).
