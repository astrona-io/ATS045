# Question

Solve this question on: `terminal`

The cluster has no certificate issued for the auditor of the `starfleet` namespace. The control plane node is the container `astro-ats-045-lab-050-01-control-plane`. It has `openssl` and the cluster certificates in `/etc/kubernetes/pki`. Run commands in it with `podman exec` or `docker exec`.

1. Create a ConfigMap `pki-evidence` in `starfleet` with two keys. `ca-fingerprint` holds the SHA-256 fingerprint of `/etc/kubernetes/pki/ca.crt`, and `apiserver-notafter` holds the expiry date of `/etc/kubernetes/pki/apiserver.crt`. Store each value as `openssl` prints it after the equals sign.

2. Issue a client certificate for a user named `scout-auditor` who is a member of the group `auditors`, with the CertificateSigningRequest API. The certificate must be valid for at most 24 hours and must be usable for client authentication.

3. Let `scout-auditor` list and get pods in `starfleet`, and do nothing else. The user must not read Secrets, delete pods or see other namespaces.

Do not bind `cluster-admin` or `admin` to the user or the group. Do not change `scout`.

`kubectl` already points at the cluster. Test the access with `kubectl auth can-i --as scout-auditor --as-group auditors`.
