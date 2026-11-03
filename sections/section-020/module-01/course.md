---
draft: true
exam_objectives:
  - Image Repository
---
# Secure Access To A Private Image Repository

A cluster cannot run a container until a node has pulled its image from an image repository. If anyone can push to that repository, anyone can change what the cluster runs. If anyone can pull from it, anyone can read the layers, including secrets that were baked into them. This module shows how an image repository stores content, who may do what with it, and how Kubernetes presents credentials to it when a pod starts.

Keep one sentence in mind: **a repository decides who may push, pull and delete, and Kubernetes only passes pull credentials to the node when a pod is created.** You will read the contents of a registry through its HTTP API, watch a pod fail to pull a private image, and fix it by attaching a pull Secret to a ServiceAccount.

The module has three parts. **Image References And Stored Layers** takes an image reference apart and reads manifests, layers and digests from the registry API. **Protecting Publishers, Readers And Repository State** compares push, pull and delete rights, authentication, retention and deletion, and shows an unauthenticated request being refused. **Pull Secrets And Pull Policy** creates a `docker-registry` Secret, attaches it to a ServiceAccount, and explains `imagePullPolicy` and credential rotation.

## Learning objectives

After this module you can:

- Name the parts of an image reference and say which of them is mutable.
- Read an image manifest and its layers from a registry API.
- Compare the push, pull and delete rights of a repository and say who needs each.
- Explain why a pod without a pull Secret fails with `ImagePullBackOff` against a private repository.
- Create a pull Secret, attach it to a ServiceAccount and restart the workload so it takes effect.
- Rotate a pull credential without leaving the old one valid.

## Before you start

You need Kubernetes basics: namespaces, Deployments, Secrets, ServiceAccounts and `kubectl`. The playground needs outbound internet to copy one image into the private registry.

Your playground is a single-node `kind` cluster running Kubernetes 1.35. A private registry (the open source `registry` image with password authentication) runs in the `registry` namespace. The node reaches it at `localhost:30500` through a NodePort Service, and pods reach it at `registry.registry.svc.cluster.local:5000`.

| Namespace | Object | What it is |
| --- | --- | --- |
| `registry` | `registry` Deployment and Service | The private repository. User `publisher` with password `push-pass-3` may push. User `puller` with password `pull-pass-7` is meant for pulling |
| `registry` | Job `seed-images` | Copies `podinfo` 6.15.0 into the registry as `starfleet/podinfo:6.15.0` |
| `starfleet` | `scout` | Runs `localhost:30500/starfleet/podinfo:6.15.0` and has no pull credential, so it cannot start |
| `starfleet` | `shuttle` | A client pod with `curl`, used to call the registry API |

You run every command as the cluster administrator.

<!-- astrona:playground -->
