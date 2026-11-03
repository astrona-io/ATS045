# Solution

Solve this lab on `terminal`. Run `astrona submit` after each step. The lab is built from documentation and has not been booted yet.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-040/module-01/labs/lab-01
```

## Step 1: Require mutual TLS for the namespace

A `PeerAuthentication` without a selector applies to every workload in its namespace. Save this as `strict.yaml`:

```yaml
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
  namespace: starfleet
spec:
  mtls:
    mode: STRICT
```

Apply it:

```sh
kubectl apply -f strict.yaml
kubectl -n outpost exec deploy/drifter -c drifter -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 5 http://scout.starfleet/
```

The request from `drifter` prints `000`, because the sidecar of `scout` resets a connection without a client certificate. Run `astrona submit`. The first check passes, and the metrics check fails because port 9797 is strict too.

## Step 2: Open the metrics port only

A port-level setting belongs to a `PeerAuthentication` that has a selector. Save this as `scout-metrics.yaml`:

```yaml
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

Apply it and test both ports from `drifter`:

```sh
kubectl apply -f scout-metrics.yaml
kubectl -n outpost exec deploy/drifter -c drifter -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 5 http://scout.starfleet:9797/metrics
kubectl -n outpost exec deploy/drifter -c drifter -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 5 http://scout.starfleet/
```

The first request prints `200` and the second prints `000`. Sidecars need a few seconds to receive the policy, so repeat a request that still shows the old result. Run `astrona submit`.

## Step 3: Read the identity from the certificate

The sidecar keeps its workload certificate. Envoy lists it on its admin port, which is reachable from inside the container:

```sh
kubectl -n starfleet exec deploy/scout -c istio-proxy -- curl -s localhost:15000/certs | jq -r '[.certificates[].cert_chain[]?.subject_alt_names[]?.uri] | unique | first'
```

The output ends in `/ns/starfleet/sa/scout`. Store it:

```sh
kubectl -n starfleet create configmap mesh-identities --from-literal=scout="$(kubectl -n starfleet exec deploy/scout -c istio-proxy -- curl -s localhost:15000/certs | jq -r '[.certificates[].cert_chain[]?.subject_alt_names[]?.uri] | unique | first')"
```

Run `astrona submit`. All four checks should pass.

## Why the shortcuts fail

Setting the namespace policy to `PERMISSIVE` lets `drifter` reach the application port, and the first check fails. A port-level setting in the namespace-wide policy is ignored, because port-level settings need a selector. Writing the identity from memory fails when it does not match the certificate.
