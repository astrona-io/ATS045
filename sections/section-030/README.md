---
draft: true
exam_objectives:
  - Observability
---
# Observability

This section covers security observability. It explains how the API server records requests with an audit policy, how to enable and read audit logs, and what collection, retention and the different evidence sources can and cannot establish.

The section has one module, Security Observability And Evidence Quality. It has a playground, a graded lab and a capstone lab on a local kind cluster, and ends with a knowledge check. Each part is followed by the lab that practises it, and the module ends with a summary.

## Learning Outcomes

- Choose audit levels and write a policy where rule order gives the intended result
- Enable audit logging on a static pod API server and recover from a failed restart
- Find the caller, target and result of a request in the log
- Explain how collection, retention and sensitive fields limit evidence

## Contents

| Item | What it is |
| --- | --- |
| Audit Policy Rules, Levels And Stages | Reading part |
| Enable Audit Logging And Read Events | Reading part |
| Collection, Retention And Evidence Limits | Reading part |
| Summary | Reading part |
| Record API Activity With Audit Logging | Graded module lab (intermediate) |
| Audit Access Changes And Keep The Evidence | Section capstone lab (advanced) |
| Knowledge check | `quiz.yaml`, pass score 70 |

## Authoring Status

The labs and the playground in this section are UNTESTED. They were built from documentation and checked only with static tools (`astrona validate`, `bash -n`, YAML parsing).
