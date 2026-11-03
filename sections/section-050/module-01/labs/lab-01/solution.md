# Solution

Solve this lab on `terminal`. Run `astrona submit` after each step. The lab is built from documentation and has not been booted yet.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-050/module-01/labs/lab-01
```

Set up the node helper first:

```sh
export CONTROL_PLANE=astro-ats-045-lab-050-01-control-plane
node() { podman exec -i "$CONTROL_PLANE" "$@"; }
```

## Step 1: Read the certificates and store the evidence

```sh
node openssl x509 -in /etc/kubernetes/pki/ca.crt -noout -fingerprint -sha256
node openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -enddate
```

The first line prints `sha256 Fingerprint=` followed by pairs of hexadecimal digits with colons. The second prints `notAfter=` and a date. Store the part after the equals sign:

```sh
kubectl -n starfleet create configmap pki-evidence \
  --from-literal=ca-fingerprint="$(node openssl x509 -in /etc/kubernetes/pki/ca.crt -noout -fingerprint -sha256 | sed 's/^.*=//')" \
  --from-literal=apiserver-notafter="$(node openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -enddate | sed 's/^notAfter=//')"
```

Run `astrona submit`. The evidence check passes.

## Step 2: Issue the client certificate

The key must be created by the user and stays with the user. Create it and a signing request. The subject carries the user name in `CN` and the group in `O`:

```sh
node openssl req -new -newkey rsa:2048 -nodes -keyout /tmp/scout-auditor.key -subj "/CN=scout-auditor/O=auditors" > scout-auditor.csr
```

Submit the request. `expirationSeconds` limits the lifetime, and 86400 is one day:

```sh
cat > csr.yaml <<YAML
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: scout-auditor
spec:
  request: $(base64 < scout-auditor.csr | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages: ["client auth"]
YAML
kubectl apply -f csr.yaml
kubectl certificate approve scout-auditor
```

Check that a certificate was issued, then read its subject and expiry:

```sh
kubectl get csr scout-auditor
kubectl get csr scout-auditor -o jsonpath='{.status.certificate}' | base64 -d | node openssl x509 -noout -subject -enddate
```

Run `astrona submit`. The certificate check passes.

## Step 3: Give the user read access to pods

A certificate only proves who the user is. RBAC decides what the user may do. Save this as `auditor.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: starfleet
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: scout-auditor-pods
  namespace: starfleet
subjects:
  - kind: User
    name: scout-auditor
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

```sh
kubectl apply -f auditor.yaml
kubectl auth can-i list pods -n starfleet --as scout-auditor --as-group auditors
kubectl auth can-i get secrets -n starfleet --as scout-auditor --as-group auditors
```

The first command prints `yes` and the second prints `no`. Run `astrona submit`. All four checks should pass.

## Why the shortcuts fail

A certificate request without `expirationSeconds` gets the default lifetime, which is longer than one day, so the lifetime check fails. A request that is not approved never receives a certificate. Binding `cluster-admin` fails the least-privilege and the admin checks. Writing the fingerprint from memory fails when it does not match the certificate on the node.
