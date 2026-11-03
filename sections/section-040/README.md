---
draft: true
exam_objectives:
  - Service Mesh
---
# Service Mesh

This section covers service mesh security with Istio. It explains workload certificates and SPIFFE identity, mutual TLS modes and port exceptions, identity-based authorization, and what a mesh does not cover.

The section has one module, Service Mesh Identity And Policy. It has a playground, a graded lab and a capstone lab on a local kind cluster, and ends with a knowledge check. Each part is followed by the lab that practises it, and the module ends with a summary.

## Learning Outcomes

- Read a workload identity and validity period from a sidecar
- Choose PERMISSIVE or STRICT and predict what a client without a sidecar receives
- Write a workload-specific PeerAuthentication with a port exception
- Write an AuthorizationPolicy for one identity, one method and one port
- State what remains outside the mesh

## Contents

| Item | What it is |
| --- | --- |
| Mesh Identity And Certificates | Reading part |
| Mutual TLS Modes And Peer Authentication | Reading part |
| Authorization And Mesh Limits | Reading part |
| Summary | Reading part |
| Require mTLS And Open One Port | Graded module lab (intermediate) |
| Secure Service-To-Service Traffic With Istio | Section capstone lab (advanced) |
| Knowledge check | `quiz.yaml`, pass score 70 |

## Authoring Status

The labs and the playground in this section are UNTESTED. They were built from documentation and checked only with static tools (`astrona validate`, `bash -n`, YAML parsing).
