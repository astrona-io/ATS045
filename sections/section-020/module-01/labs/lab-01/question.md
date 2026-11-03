# Question

Solve this question on: `terminal`

A private registry runs in the `registry` namespace. The node reaches it at `localhost:30500`. The Deployments `scout` and `probe` in `starfleet` run `localhost:30500/starfleet/podinfo:6.15.0` and stay in `ImagePullBackOff`. The registry account `puller` with the password `pull-pass-7` has the right to pull.

1. Create the Secret `registry-pull` in `starfleet` so that the kubelet can authenticate to `localhost:30500` as `puller`.

2. Give the credential to `scout` and `probe` through their ServiceAccounts, which have the same names as the Deployments. Do not add `imagePullSecrets` to the Deployment templates.

3. Make both Deployments available. Pods that already exist do not take the change.

Do not change the registry or turn off its authentication. `kubectl` already points at the cluster as the cluster administrator.
