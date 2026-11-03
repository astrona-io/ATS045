---
draft: true
exam_objectives:
  - Supply Chain Security
---
# Trust What You Deploy

A container image is the last link of a long chain. Source code is reviewed, dependencies are fetched, a build system compiles everything, a registry stores the result, and the Kubernetes cluster pulls and runs it. Each link can be changed by someone who should not change it. This module teaches how to find out which image is really running, what evidence exists about it, and how to keep credentials out of the artifact and out of reach of a compromised process.

Keep one sentence in mind: **a tag names an image, a digest identifies it, and evidence such as a signature or a software bill of materials only helps when it is tied to that exact digest.** You will read the digest of a running image, pin a Deployment to it, and move a password from an environment variable into a mounted Secret.

The module has three parts. **Artifact Evidence And Sensitive Build Inputs** separates the kinds of evidence (digest, signature, provenance, software bill of materials, vulnerability scan) and says what each one proves. **Connecting Verification To Execution Policy** pins workloads to a digest and explains where a cluster can enforce verification. **Credentials And Service Account Tokens** removes a credential from an environment variable, mounts it as a file and stops a pod from receiving a Kubernetes API token it does not need.

## Learning objectives

After this module you can:

- Trace the source, build, publication and deployment trust boundaries of an image.
- Distinguish a digest, a signature, provenance, a software bill of materials and a vulnerability scan, and say what each proves.
- Read the digest of a running container and pin a Deployment to it.
- Explain where in a cluster the verification of an artifact can be enforced.
- Move a credential from an environment variable to a Secret mounted as a file.
- Stop a workload from receiving a ServiceAccount token it does not use.

## Before you start

You need Kubernetes basics: namespaces, Deployments, Secrets, pods, and the commands `kubectl get`, `kubectl apply` and `kubectl patch`. No extra tool is needed on your machine.

Your playground is a single-node `kind` cluster running Kubernetes 1.35. It starts with these objects:

| Namespace | Object | What it is |
| --- | --- | --- |
| `starfleet` | `scout`, `probe`, `shuttle` | The example application. All images are referenced by tag, which is the starting weakness |
| `starfleet` | `uplink` | A workload that gets a database password from a plain environment variable, on purpose |
| `outpost` | `drifter` | A client that belongs to another team |

You run every command as the cluster administrator. `kubectl` already points at the playground cluster.

Launch your playground now and keep it running while you read the parts:

<!-- astrona:playground -->
