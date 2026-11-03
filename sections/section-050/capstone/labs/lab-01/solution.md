# Solution

Solve this lab on `terminal`. Run `astrona submit` after each step. The lab is built from documentation and has not been booted yet.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-050/capstone/labs/lab-01
export CONTROL_PLANE=astro-ats-045-capstone-050-control-plane
node() { podman exec -i "$CONTROL_PLANE" "$@"; }
```

## Step 1: Remove the access of the leaked certificate

The certificate states a user and a group. RBAC grants access by either one, so find the bindings for both:

```sh
kubectl get clusterrolebinding,rolebinding -A -o json | jq -r '.items[] | select(any(.subjects[]?; (.kind == "User" and .name == "fleet-intern") or (.kind == "Group" and .name == "fleet-ops"))) | [.kind, .metadata.namespace // "-", .metadata.name] | @tsv'
```

Three bindings are listed: `fleet-intern-admin`, `fleet-ops-admin` and `intern-edit` in `starfleet`. Delete them:

```sh
kubectl delete clusterrolebinding fleet-intern-admin fleet-ops-admin
kubectl -n starfleet delete rolebinding intern-edit
kubectl auth can-i get secrets -A --as fleet-intern --as-group fleet-ops
```

The last command prints `no`. The certificate is still valid and the API server still accepts it. It has an identity and no permissions. Run `astrona submit`.

## Step 2: Issue the replacement certificate

```sh
node openssl req -new -newkey rsa:2048 -nodes -keyout /tmp/fleet-intern-2.key -subj "/CN=fleet-intern-2/O=interns" > fleet-intern-2.csr
cat > csr.yaml <<YAML
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: fleet-intern-2
spec:
  request: $(base64 < fleet-intern-2.csr | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 3600
  usages: ["client auth"]
YAML
kubectl apply -f csr.yaml
kubectl certificate approve fleet-intern-2
```

Read the result:

```sh
kubectl get csr fleet-intern-2 -o jsonpath='{.status.certificate}' | base64 -d | node openssl x509 -noout -subject -enddate
```

Run `astrona submit`.

## Step 3: Grant read access to one namespace

```sh
kubectl -n starfleet create rolebinding fleet-intern-2-view --clusterrole=view --user=fleet-intern-2
kubectl auth can-i list pods -n starfleet --as fleet-intern-2 --as-group interns
kubectl auth can-i get secrets -n starfleet --as fleet-intern-2 --as-group interns
```

The built-in `view` role reads most namespaced objects and does not include Secrets. A `RoleBinding` limits it to `starfleet`. Run `astrona submit`.

## Step 4: Write the evidence

```sh
kubectl -n starfleet create configmap pki-evidence \
  --from-literal=ca-fingerprint="$(node openssl x509 -in /etc/kubernetes/pki/ca.crt -noout -fingerprint -sha256 | sed 's/^.*=//')" \
  --from-literal=apiserver-chain="$(node openssl verify -CAfile /etc/kubernetes/pki/ca.crt /etc/kubernetes/pki/apiserver.crt | sed 's/^.*: //')" \
  --from-literal=apiserver-notafter="$(node openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -enddate | sed 's/^notAfter=//')"
```

Run `astrona submit`. All five checks should pass.

## Why the shortcuts fail

Deleting the user binding and keeping the group binding leaves the access in place, because the leaked certificate carries both. Deleting every binding fails the `fleet-intact` check. A request without `expirationSeconds` gets a certificate with the default lifetime, and the short-lived check fails. Binding `cluster-admin` to the new user fails the least-privilege check.
