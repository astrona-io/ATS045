# Question

Solve this question on: `terminal`

The `starfleet` namespace runs `scout`, `probe`, `shuttle` and `uplink`. The images of `scout` and `probe` are referenced by tag, and `uplink` reads a database password from the environment variable `DB_PASSWORD`, set directly in its Deployment. The security team wants exact image identity and no credential in the pod environment.

1. Pin the Deployments `scout` and `probe` to the digest of the image that runs now. The image field must have the form `repository@sha256:<digest>`.

2. Create the Secret `uplink-db` with the key `password` and the value `orbit-secret-9`. Mount it read-only at `/etc/uplink` in the `uplink` container, and remove the environment variable `DB_PASSWORD`. Do not use `valueFrom` for it.

3. Stop the `uplink` pod from receiving a ServiceAccount token.

Every Deployment must stay available, and `shuttle` must still get an answer from the `scout` Service. Do not change the `outpost` namespace. `kubectl` already points at the cluster as the cluster administrator.
