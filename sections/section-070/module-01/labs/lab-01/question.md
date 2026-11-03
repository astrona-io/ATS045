# Question

Solve this question on: `terminal`

The `starfleet` namespace runs `scout` and `shuttle`, and the `outpost` namespace runs `drifter`. All three workloads meet the Pod Security `restricted` level, pin their image tag and set a memory limit. No admission control of your own exists. Add controls that apply to `starfleet` only. Do not change the workloads and do not label `outpost`.

1. Make the API server reject pods in `starfleet` that do not meet the Pod Security `restricted` level. A privileged pod and a pod that runs as root with no hardening must be rejected, and a hardened pod must be admitted.

2. Make the API server reject a Deployment in `starfleet` when any container has no memory limit. Use a `ValidatingAdmissionPolicy` and a `ValidatingAdmissionPolicyBinding`. A Deployment with a memory limit must be admitted.

3. Check that `outpost` is not affected: a privileged pod and a Deployment without a limit must still be admitted there.

Do not use the `Ignore` failure policy. The binding must use the `Deny` action. The API server needs a few seconds to activate a new policy, so repeat a check that still shows the old result.

`kubectl` already points at the cluster. Ask the API server whether an object would be admitted with a server-side dry run: `kubectl apply -n starfleet --dry-run=server -f pod.yaml`. It stores nothing.
