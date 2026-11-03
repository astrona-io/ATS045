# Question

Solve this question on: `terminal`

The `starfleet` namespace runs `scout` and `shuttle`, and the `outpost` namespace runs `drifter`. An earlier operator set up two admission controls for `starfleet`. Both exist, but neither protects the namespace the way the team intended. Find out why and fix it. Do not change the workloads, do not label `outpost`, and do not delete the policy `image-tags`.

1. The team wants pods in `starfleet` to meet the Pod Security `restricted` level, and the API server must reject the pods that do not. A privileged pod and a pod that runs as root with no hardening must be rejected.

2. The policy `image-tags` is meant to reject a Deployment in `starfleet` when a container image uses the `latest` tag or has no tag. A Deployment with a pinned tag must be admitted, and one with the `latest` tag must be rejected.

3. The controls apply to `starfleet` only. A privileged pod and a Deployment with the `latest` tag must still be admitted in `outpost`.

Do not use the `Ignore` failure policy. The binding must use the `Deny` action. The API server needs a few seconds to activate a change, so repeat a check that still shows the old result.

`kubectl` already points at the cluster. Read the controls with `kubectl get namespace starfleet --show-labels`, `kubectl get validatingadmissionpolicy,validatingadmissionpolicybinding` and `kubectl describe`. Ask the API server whether an object would be admitted with a server-side dry run: `kubectl apply -n starfleet --dry-run=server -f deploy.yaml`.
