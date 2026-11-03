# Solution

Solve this lab on `terminal`. Run `astrona submit` after each step. The lab is built from documentation and has not been booted yet.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-040/capstone/labs/lab-01
```

## Step 1: Require mutual TLS and open the metrics port

Save this as `mesh.yaml`:

```yaml
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
  namespace: starfleet
spec:
  mtls:
    mode: STRICT
---
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: scout-metrics
  namespace: starfleet
spec:
  selector:
    matchLabels:
      app: scout
  mtls:
    mode: STRICT
  portLevelMtls:
    9797:
      mode: PERMISSIVE
```

```sh
kubectl apply -f mesh.yaml
```

The namespace policy has no selector. Port-level settings need the selector on the second policy.

## Step 2: Authorize callers by identity, method and port

An `ALLOW` policy denies every request that none of its rules match, including the plain-text metrics request. Each rule below covers one port. Save this as `scout-allow.yaml`:

```yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: scout-allow
  namespace: starfleet
spec:
  selector:
    matchLabels:
      app: scout
  action: ALLOW
  rules:
    - from:
        - source:
            principals: ["cluster.local/ns/starfleet/sa/shuttle"]
      to:
        - operation:
            methods: ["GET"]
            ports: ["9898"]
    - to:
        - operation:
            methods: ["GET"]
            ports: ["9797"]
```

```sh
kubectl apply -f scout-allow.yaml
```

Test the four requests from the question, repeating a request that still shows the old result. Run `astrona submit`.

## Step 3: Record the identities

Read the identity of each sidecar and store both:

```sh
identity() { kubectl -n starfleet exec "deploy/$1" -c istio-proxy -- curl -s localhost:15000/certs | jq -r '[.certificates[].cert_chain[]?.subject_alt_names[]?.uri] | unique | first'; }
kubectl -n starfleet create configmap mesh-identities --from-literal=scout="$(identity scout)" --from-literal=probe="$(identity probe)"
```

Run `astrona submit`. All six checks should pass.

## Why the shortcuts fail

A namespace-wide `PERMISSIVE` policy opens the application port to plain text, and two checks fail. An `ALLOW` policy with only the `shuttle` rule makes the metrics request fail with `403`. A request with the wrong identity for `probe` fails because `caller` shares its service account, and its certificate carries `sa/probe`.
