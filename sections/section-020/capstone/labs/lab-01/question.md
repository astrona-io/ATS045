# Question

Solve this question on: `terminal`

The platform team revoked the registry account `puller`. The new pull account is `puller-v2` with the password `pull-pass-8`. The private registry at `localhost:30500` holds `starfleet/podinfo` with the tag `6.15.0`. The Deployment `scout` in `starfleet` and the Deployment `drifter` in `outpost` both run `localhost:30500/starfleet/podinfo:6.15.0`. Each namespace has a Secret `registry-pull` that holds the revoked account, and each ServiceAccount of the same name as its Deployment lists that Secret.

1. Replace the credential in `registry-pull` in both namespaces with the account `puller-v2`. Keep the Secret name so the ServiceAccounts keep working. No Secret in the cluster may hold `puller` any more.

2. Reference the image of both Deployments by digest: `localhost:30500/starfleet/podinfo@sha256:<digest>`. The digest is the one the registry reports for the tag `6.15.0`. The `shuttle` pod in `starfleet` has `curl` for registry calls.

3. Set `imagePullPolicy: Always` on both containers.

4. Both Deployments must be available. Do not change the registry. `kubectl` already points at the cluster as the cluster administrator.
