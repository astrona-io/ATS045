---
draft: true
exam_objectives:
  - Connectivity
---
# Connectivity

This section covers connectivity and protected network paths. It follows a request from a client to a pod, explains how NetworkPolicy isolates pods and allows single paths, and covers the management ports of a cluster and how to verify a policy.

The section has one module, Connectivity And Protected Network Paths. It has a playground, a graded lab and a capstone lab on a local kind cluster, and ends with a knowledge check. Each part is followed by the lab that practises it, and the module ends with a summary.

## Learning Outcomes

- Describe the hops of a request and where TLS terminates
- Isolate a namespace with default deny and add single allowed paths
- Write selectors and ports that do not open more than intended
- Keep name resolution working under an egress policy
- Limit a management port to one client and verify the result from the right pod

## Contents

| Item | What it is |
| --- | --- |
| Ingress Paths And Where Encryption Stops | Reading part |
| NetworkPolicy Mechanics | Reading part |
| Management Paths And Verifying A Policy | Reading part |
| Summary | Reading part |
| Isolate A Namespace And Allow One Path | Graded module lab (intermediate) |
| Segment The Starfleet Network | Section capstone lab (advanced) |
| Knowledge check | `quiz.yaml`, pass score 70 |

## Authoring Status

The labs and the playground in this section are UNTESTED. They were built from documentation and checked only with static tools (`astrona validate`, `bash -n`, YAML parsing).
