# Overview: Trust What You Deploy (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with the example workloads and then waits. There is no task, no `astrona submit` and no pass or fail.

## What's in the box

A single-node `kind` cluster running Kubernetes 1.35. `kubectl` points at it as the cluster administrator.

| Namespace | What is in it |
| --- | --- |
| `starfleet` | `scout`, `probe` and `shuttle`, all referenced by tag. `uplink` reads `DB_PASSWORD` from a plain environment variable, on purpose |
| `outpost` | The `drifter` client |

## Practice tasks

- Read the digest each container runs from `status.containerStatuses[].imageID` and compare it with the `image` field in the pod spec.
- Pin `probe` to its digest with `kubectl set image` and confirm the rollout finishes.
- Move the `uplink` password into a Secret mounted at `/etc/uplink` and delete the environment variable.
- Set `automountServiceAccountToken: false` on `uplink` and list `/var/run/secrets/kubernetes.io/serviceaccount` before and after.
- Run `kubectl get pods -A -o jsonpath` to list every image in the cluster and spot the ones that use a tag.
