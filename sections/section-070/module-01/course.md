---
draft: true
exam_objectives:
  - Admission Control
---
# Admission Policy And Extension Trust

A user who may create Pods can still ask for a privileged container, a host mount or an image from an unknown source. Authorization says that the user may create Pods. It does not look at what the Pod contains. Admission is the stage of the API server that looks at the object itself, after the caller is authorized and before the object is stored. This module explains what admission can change and check, which mechanisms exist, and what makes a rule actually apply to a request.

Keep one sentence in mind: **an admission rule protects only the requests it matches, in the mode it is set to, while the component that evaluates it is working.** A policy that exists is not the same as a policy that denies. You will enforce a Pod Security level, write a validating admission policy, read how a binding decides its scope, and register a webhook that fails.

The module has three parts. **The Admission Chain And Built-In Controllers** covers where admission sits in a request, mutation and validation, and the built-in plug-ins. **Pod Security Admission And Validating Admission Policy** covers the two mechanisms that run inside the API server, with their modes, scope and failure settings. **Admission Webhooks, Failure And Exceptions** covers external webhooks, their trust and failure behavior, and the exceptions that weaken a rule.

## Learning objectives

After this module you can:

- Place admission in the request path and tell mutation, validation and authorization apart.
- Enforce a Pod Security level with namespace labels and explain `enforce`, `warn` and `audit`.
- Write a `ValidatingAdmissionPolicy` and a binding, and choose `Deny`, `Warn` or `Audit`.
- Explain how matching, failure policy and exceptions decide the real coverage of a rule.
- Describe what a webhook must provide and what happens when it does not answer.
- Ask the API server whether an object would be admitted with a server-side dry run.

## Before you start

You need Kubernetes basics: namespaces, Pods, Deployments and labels. You do not need to know how the API server is built. Terms are defined where they first appear.

Your playground is a single-node `kind` cluster running Kubernetes 1.35. The control plane node is a container named `astro-ats-045-playground-070-01-control-plane`.

| Namespace | Object | What it is |
| --- | --- | --- |
| `starfleet` | `scout` | podinfo. Meets the Pod Security `restricted` level, pins its image tag and sets a memory limit |
| `starfleet` | `shuttle` | A client with `curl`, with the same settings |
| `outpost` | `drifter` | A client with `curl`, with the same settings |

You run every command as the cluster administrator. No admission policy of your own exists when you start.

<!-- astrona:playground -->
