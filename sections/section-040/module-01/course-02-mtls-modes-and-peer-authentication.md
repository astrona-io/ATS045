---
draft: true
exam_objectives:
  - Service Mesh
---
# Mutual TLS Modes And Peer Authentication

Every sidecar holds a certificate, but a certificate only protects traffic when the receiving side demands it. By default Istio accepts both encrypted and plain-text connections, so a client that has no certificate can still call every service. This part shows how the receiving sidecar decides, how to change that decision with a `PeerAuthentication` resource, and what a client without a sidecar sees when it is refused.

## Mutual TLS in one connection

In ordinary TLS, only the server shows a certificate and the client checks it. In **mutual TLS (mTLS)**, both sides show a certificate and both sides check the other one. For two sidecars the exchange has these steps:

1. The client sidecar opens a TCP connection to the server sidecar and starts a TLS handshake.
2. The server sidecar sends its workload certificate. The client verifies that the chain leads to the mesh root and that the SAN matches the identity it expects for the destination service.
3. The server sidecar asks for a client certificate. The client sends its workload certificate, and the server verifies the chain.
4. Both sides now know the other side's SPIFFE identity. The traffic is encrypted with keys from the handshake.

The client side needs no configuration. When the destination has a sidecar, Istio sends mTLS by default, which is called automatic mTLS. The receiving side is where the choice is made. If a connection arrives without a handshake, the server sidecar must accept it or refuse it.

## The inbound listener

The sidecar receives all inbound traffic on port 15006. Its listener has more than one filter chain, and a TLS inspector decides which one handles a connection. The inspector looks at the first bytes. A TLS handshake with the Istio protocol marker goes to the mTLS chain, which verifies the client certificate. Anything else goes to the plain-text chain.

Which chains exist depends on the mTLS mode:

| Mode | mTLS chain | Plain-text chain | Effect |
| --- | --- | --- | --- |
| `PERMISSIVE` | yes | yes | Accepts both. This is the default. |
| `STRICT` | yes | no | Accepts only mTLS. A plain connection is closed. |
| `DISABLE` | no | yes | Accepts only plain text. |

`PERMISSIVE` exists so that a namespace can be moved into the mesh one workload at a time. Clients that are not in the mesh keep working during the move. It is not a secure end state, because an attacker who can reach the pod can send plain text, and the sidecar accepts it. Authorization rules that use identities cannot match a plain-text request, because it has no identity.

## The PeerAuthentication resource

`PeerAuthentication` sets the mode for traffic that arrives at a workload. The word "peer" refers to the other side of the connection. The resource has three places where it can apply, and the most specific one wins:

1. **Workload-specific.** A policy with a `selector` applies to the pods that match the labels.
2. **Namespace-wide.** A policy in a namespace without a selector applies to every workload in that namespace. The conventional name is `default`.
3. **Mesh-wide.** A policy without a selector in the root namespace, `istio-system`, applies to every namespace that has no policy of its own.

A policy that sets the mode for a namespace is written like this:

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

A workload-specific policy can also set the mode per port with `portLevelMtls`. Two rules apply to it. The port number is the port that the workload listens on, which is the container port and not the Service port. And `portLevelMtls` is only accepted when the policy has a `selector`. A port-level setting in a policy without a selector is rejected or ignored.

## Look at the starting state

<!-- astrona:playground:renew -->

```sh
kubectl get peerauthentication -A
kubectl -n outpost exec deploy/drifter -c drifter -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 5 http://scout.starfleet/
```

The first command finds no resources, and the second prints `200`. `drifter` has no sidecar and no certificate, and the sidecar of `scout` accepts it in plain text because the mode is `PERMISSIVE`.

## Require mTLS for the namespace

Save the policy as a file, and then apply it:

```sh
cat > strict.yaml <<'YAML'
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
  namespace: starfleet
spec:
  mtls:
    mode: STRICT
YAML
kubectl apply -f strict.yaml
```

`istiod` converts the policy into proxy configuration and pushes it to the sidecars of `starfleet` over the xDS API. This takes a few seconds, so repeat a request that still shows the old result. Test three clients:

```sh
kubectl -n outpost exec deploy/drifter -c drifter -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 5 http://scout.starfleet/
kubectl -n outpost exec deploy/drifter -c drifter -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 5 http://probe.starfleet/get
kubectl -n starfleet exec deploy/shuttle -c shuttle -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 5 http://probe.starfleet/get
```

The first two print `000`. That value is not an HTTP status. It means that no HTTP response arrived, because the sidecar of the server closed the plain-text connection. Run the same `curl` without `-s` and it reports a failed or reset connection. The third prints `200`, because `shuttle` has a sidecar, so its request travels over mTLS.

The mode applies to traffic that arrives at the pod. It does not change what a pod may send. A kubelet readiness probe is plain HTTP from the node, and Istio rewrites application probes so that the kubelet asks `pilot-agent` instead, which then calls the application. This keeps probes working under `STRICT`.

## Open one port

A metrics collector that runs outside the mesh cannot do mTLS, and it still needs to read `/metrics` from port 9797 of `scout`. Making the whole namespace `PERMISSIVE` would also open the application port. The smaller change is a port-level exception for one workload:

```sh
cat > scout-metrics.yaml <<'YAML'
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
YAML
kubectl apply -f scout-metrics.yaml
```

The workload policy has the same mode as the namespace for every other port, so the policy only adds the exception. Test both ports from `drifter`:

```sh
kubectl -n outpost exec deploy/drifter -c drifter -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 5 http://scout.starfleet:9797/metrics
kubectl -n outpost exec deploy/drifter -c drifter -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 5 http://scout.starfleet/
```

The first prints `200`, and the second prints `000`. The exception is for one port of one workload, and `probe` stays strict.

Why is the workload policy needed, and not a second namespace policy? Only one namespace-wide policy applies to a namespace, and two policies without a selector conflict. The selector is also what makes `portLevelMtls` valid.

## Check what the mode does not cover

`STRICT` answers a single question: does the connection carry a valid mesh certificate? It does not answer which identity may call. After the change, `caller` and `shuttle` both reach `probe`, and so would any pod in any namespace that has a sidecar. Another namespace with injection enabled gets certificates from the same CA, and its pods pass the `STRICT` check.

Plain-text exceptions also have a cost. The port that is `PERMISSIVE` accepts any caller that can reach the pod, with no identity, and an authorization rule can only match it on attributes of the request, such as the method and path. Keep the exception to a port that carries data that is safe to read, and do not make it the application port.

## Common pitfalls

> [!WARNING]
> `PERMISSIVE` is the default and it accepts plain text, so installing a mesh does not by itself require mTLS. A `STRICT` policy only protects the workloads that it selects, so check the effective result with a request from a client without a sidecar. A port-level setting needs a selector and uses the container port. A request that shows an old result may only be waiting for the new configuration to reach the sidecar.
