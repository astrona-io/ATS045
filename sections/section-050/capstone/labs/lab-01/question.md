# Question

Solve this question on: `terminal`

An intern had access to the `starfleet` cluster with a client certificate whose subject is `CN=fleet-intern, O=fleet-ops`. The certificate file has leaked, and it is valid for another year. The control plane node is the container `astro-ats-045-capstone-050-control-plane`. It has `openssl` and the cluster certificates in `/etc/kubernetes/pki`. Run commands in it with `podman exec` or `docker exec`.

1. Remove all access that the leaked certificate has. Kubernetes does not check a revocation list for client certificates, so the certificate stays valid for the API server. Find every binding that names the user `fleet-intern` or the group `fleet-ops`, in every namespace. Do not remove the binding `fleet-auditors-view`.

2. The intern still needs read access. Issue a new client certificate for the user `fleet-intern-2` in the group `interns` with the CertificateSigningRequest API. It must be valid for at most 2 hours and usable for client authentication.

3. Let `fleet-intern-2` list and get pods in `starfleet`, and do nothing else. The user must not read Secrets, delete pods, or see other namespaces.

4. For the incident report, create a ConfigMap `pki-evidence` in `starfleet` with three keys. `ca-fingerprint` holds the SHA-256 fingerprint of `/etc/kubernetes/pki/ca.crt`. `apiserver-notafter` holds the expiry date of `/etc/kubernetes/pki/apiserver.crt`. `apiserver-chain` holds the result of `openssl verify -CAfile /etc/kubernetes/pki/ca.crt /etc/kubernetes/pki/apiserver.crt`, which is the word after the last colon. Store the values as `openssl` prints them.

Do not bind `cluster-admin` or `admin` to a new user or group, and do not change `scout`.

`kubectl` already points at the cluster. Test access with `kubectl auth can-i --as <user> --as-group <group>`.
