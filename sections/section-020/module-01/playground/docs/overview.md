# Overview: Private Image Repository (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a private registry and workloads that cannot pull from it yet. There is no task and no `astrona submit`.

## What's in the box

A single-node `kind` cluster running Kubernetes 1.35. The playground needs outbound internet to copy `podinfo` into the registry.

| Where | What |
| --- | --- |
| `registry` namespace | The registry on port 5000 with password authentication. `publisher` / `push-pass-3` and `puller` / `pull-pass-7`. The node reaches it at `localhost:30500` |
| `starfleet` namespace | `scout` and `probe` run `localhost:30500/starfleet/podinfo:6.15.0` with no pull Secret, so they stay in `ImagePullBackOff`. `shuttle` has `curl` |

## Practice tasks

- Call `/v2/_catalog` and `/v2/starfleet/podinfo/tags/list` from `shuttle` with the `puller` account, then without credentials, and compare the status codes.
- Read the `Docker-Content-Digest` header of the manifest for tag `6.15.0`.
- Describe the failing `scout` pod and find the event that names the authorization failure.
- Create a pull Secret, attach it to the `scout` ServiceAccount and restart the Deployment.
- Attach the Secret directly in the `probe` Deployment with `spec.imagePullSecrets` and compare the two methods.
