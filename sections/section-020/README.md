---
draft: true
exam_objectives:
  - Image Repository
---
# Image Repository

This section covers access to an image repository. It explains what a registry stores, what authentication does and does not protect, and how pull Secrets, ServiceAccounts and pull policy decide whether a node can start a workload.

The section has one module, Secure Access To A Private Image Repository. It has a playground, a graded lab and a capstone lab on a local kind cluster, and ends with a knowledge check. Each part is followed by the lab that practises it, and the module ends with a summary.

## Learning Outcomes

- Read an image reference and the content a registry stores
- State what authentication covers and what needs separate authorization
- Create pull Secrets, attach them to ServiceAccounts and rotate them
- Choose an imagePullPolicy and diagnose pull failures in order

## Contents

| Item | What it is |
| --- | --- |
| Image References And Stored Layers | Reading part |
| Protecting Publishers, Readers And Repository State | Reading part |
| Pull Secrets And Pull Policy | Reading part |
| Summary | Reading part |
| Fix ImagePullBackOff With A Pull Secret | Graded module lab (intermediate) |
| Rotate Registry Pull Credentials And Pin Digests | Section capstone lab (advanced) |
| Knowledge check | `quiz.yaml`, pass score 70 |

## Authoring Status

The labs and the playground in this section are UNTESTED. They were built from documentation and checked only with static tools (`astrona validate`, `bash -n`, YAML parsing).
