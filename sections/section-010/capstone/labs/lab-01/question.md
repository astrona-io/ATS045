# Question

Solve this question on: `terminal`

The `forge` namespace runs the Deployment `build-runner` with the image `mccutchen/go-httpbin:2.25.0`. It uses the `default` ServiceAccount, which a RoleBinding named `default-admin` gives the `admin` ClusterRole. A publishing token is set as the environment variable `REGISTRY_TOKEN`, and the Secret `registry-token` already holds the same value in the key `token`. The container has a writable root file system and no security settings.

Harden the workload so that a compromised `build-runner` pod holds as little authority as possible.

1. Run `build-runner` under the existing ServiceAccount `build-runner`, with no ServiceAccount token mounted, and remove the RoleBinding `default-admin`.

2. Reference the image by the digest of the image that runs now. Keep the repository `mccutchen/go-httpbin`.

3. Remove the `REGISTRY_TOKEN` environment variable and mount the Secret `registry-token` read-only at any path.

4. Set `runAsNonRoot: true` with `runAsUser: 65532`, `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true` and `capabilities.drop: ["ALL"]`.

The Deployment must stay available and answer HTTP requests on port 8080. `kubectl` already points at the cluster as the cluster administrator.
