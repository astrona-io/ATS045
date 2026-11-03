---
draft: true
exam_objectives:
  - Observability
---
# Security Observability And Evidence Quality

A cluster can only be investigated with the evidence it kept. If nobody turned on audit logging, a deleted Deployment leaves no record of who deleted it. If the log records every request body, it holds every Secret that a caller read. This module shows how the Kubernetes API server records requests, how you choose what to record, and what the other sources of security evidence can and cannot tell you.

Keep one sentence in mind: **a log answers only the questions that the policy and the pipeline were built to answer.** You will enable audit logging on a running API server, write a policy that treats Secrets differently from Deployments, find which service account deleted a workload, and see where a telemetry pipeline can lose or expose data.

The module has three parts. **Audit Policy Rules, Levels And Stages** explains levels, stages and the first-match rule order. **Enable Audit Logging And Read Events** adds the flags and mounts to the API server static pod, waits for the restart and reads events with `jq`. **Collection, Retention And Evidence Limits** covers collectors, backends, cardinality, retention, sensitive fields, alerts and the limits of each evidence source.

## Learning objectives

After this module you can:

- Choose an audit level for a request and explain what the event then contains.
- Write an audit policy where rule order gives the intended result.
- Enable audit logging on an API server that runs as a static pod and recover from a failed restart.
- Find the caller, target, time and result of a request in the audit log.
- Distinguish API audit, runtime and application evidence by the boundary each one observes.
- Explain how collection, retention and sensitive fields affect the trust placed in evidence.

## Before you start

You need Kubernetes basics: namespaces, Deployments, Secrets, ServiceAccounts and `kubectl`. You also need Podman or Docker to open commands on the control plane node container, and `jq` on your machine.

Your playground is a single-node `kind` cluster running Kubernetes 1.35. Audit logging starts disabled. The control plane node container is `astro-ats-045-playground-030-01-control-plane`.

| Namespace | Object | What it is |
| --- | --- | --- |
| `starfleet` | `scout`, `probe` | Backends |
| `starfleet` | `shuttle` | A client pod with `curl` |
| `starfleet` | Secret `scout-db-credentials` | The credential that audit must never record in full |
| `outpost` | `drifter` | A client outside `starfleet` |
| `outpost` | CronJob `deck-cleaner` | Every two minutes it reads the Secret, deletes `probe` and recreates it |

You run every command as the cluster administrator.

<!-- astrona:playground -->
