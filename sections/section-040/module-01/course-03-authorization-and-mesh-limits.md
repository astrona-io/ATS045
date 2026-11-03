---
draft: true
exam_objectives:
  - Service Mesh
---
# Authorization And Mesh Limits

Mutual TLS tells the server sidecar which service account is calling. It does not tell the sidecar whether that caller may do what it asks. That decision belongs to an `AuthorizationPolicy`. This part shows how the server sidecar evaluates policy, writes one that allows a single caller, a single method and a single port, and then lists what the mesh still leaves to other controls.

## How a request is authorized

An `AuthorizationPolicy` is enforced by the sidecar of the destination workload, after the connection is accepted. The sidecar builds a set of facts about the request: the peer identity from the client certificate, the namespace of the caller, the HTTP method, the path, the destination port and the headers. It then compares those facts with the rules that apply to the workload.

A policy has an `action` and a list of `rules`. The evaluation order is fixed:

1. If a `CUSTOM` policy applies, it is evaluated first by an external authorizer. This module does not use it.
2. If any `DENY` policy has a rule that matches the request, the request is denied.
3. If no `ALLOW` policy applies to the workload, the request is allowed.
4. If at least one `ALLOW` policy applies, the request must match a rule of one of them. A request that matches none is denied.

Step 3 and step 4 are the source of most surprises. A workload with no policy accepts everything. The moment one `ALLOW` policy selects it, everything that the policy does not list is denied, including requests that worked a second ago. An `ALLOW` policy with an empty `spec: {}` matches no request, so it denies all requests to the workload that it selects.

A denied HTTP request receives the status `403`, and the body says `RBAC: access denied`. A denied TCP connection is closed.

## The rule fields

A rule has up to three parts: `from` for the source, `to` for the operation and `when` for extra conditions. Inside one rule, every part that is present must match, so the parts combine with AND. Inside a list, such as several `methods`, any one value is enough, so the values combine with OR. Several rules in the same policy combine with OR.

| Field | Matches | Needs mTLS |
| --- | --- | --- |
| `from[].source.principals` | The SPIFFE identity of the caller, written without the `spiffe://` prefix | Yes |
| `from[].source.namespaces` | The namespace of the caller, taken from the identity | Yes |
| `to[].operation.methods` | The HTTP method | No |
| `to[].operation.ports` | The destination port on the workload, as a string | No |
| `to[].operation.paths` | The request path | No |

The fields that come from the certificate, `principals` and `namespaces`, can only match a request that arrived over mTLS. A plain-text request has no certificate, so a rule that requires a principal never matches it. This is why `PERMISSIVE` mode and identity rules do not combine well: a plain-text caller is not allowed by an identity rule, and it is also not identified by it.

## Look at the starting state

<!-- astrona:playground:renew -->

Check the requests that the policy will change. `caller` runs as the service account `probe`, and `shuttle` runs as the service account `shuttle`:

```sh
kubectl -n starfleet get authorizationpolicy
kubectl -n starfleet exec deploy/shuttle -c shuttle -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 5 http://scout.starfleet/
kubectl -n starfleet exec deploy/caller -c caller -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 5 http://scout.starfleet/
kubectl -n starfleet exec deploy/shuttle -c shuttle -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 5 -X POST -d hi http://scout.starfleet/echo
```

There is no policy, so all three requests print `200`. If a `STRICT` `PeerAuthentication` exists in `starfleet`, the result is the same, because both clients have sidecars.

## Allow one caller, one method and one port

The goal is that only `shuttle` may call the application port of `scout`, and only with `GET`. The metrics port must keep answering `GET` requests. Save the policy as a file, and then apply it:

```sh
cat > scout-allow.yaml <<'YAML'
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
YAML
kubectl apply -f scout-allow.yaml
```

The first rule has a source and an operation, so a request must come from `shuttle`, use `GET` and reach port 9898. The second rule has only an operation, so any caller may use `GET` on port 9797. The two rules combine with OR.

The ports in the rule are the container ports, 9898 and 9797. They are not the Service port 80. The sidecar evaluates the request after the Service port has been translated to the pod port.

Test the matrix, repeating a request that still shows the old result:

```sh
kubectl -n starfleet exec deploy/shuttle -c shuttle -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 5 http://scout.starfleet/
kubectl -n starfleet exec deploy/shuttle -c shuttle -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 5 -X POST -d hi http://scout.starfleet/echo
kubectl -n starfleet exec deploy/caller -c caller -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 5 http://scout.starfleet/
kubectl -n starfleet exec deploy/caller -c caller -- curl -s --max-time 5 http://scout.starfleet/
```

The first request prints `200`. The second and third print `403`: the method is wrong in one, and the identity is wrong in the other. The last command prints the body, `RBAC: access denied`. If `starfleet` has a `PeerAuthentication` that is `PERMISSIVE` on port 9797 of `scout`, `drifter` can read `http://scout.starfleet:9797/metrics`, because the second rule has no source. Without the second rule, that request returns `403`, because an `ALLOW` policy denies what it does not list.

## What the mesh does not do

**It does not know the user.** The identity in the certificate is a workload. If `shuttle` calls `probe` on behalf of a person, `probe` sees `sa/shuttle`, not the person. Istio can validate a JSON Web Token with a `RequestAuthentication` resource, and a policy can match its claims. The application still decides which records that person may read. A valid service certificate does not replace that check.

**It protects only the hops that it controls.** The loopback hop between a sidecar and its application is plain text. An ingress gateway that terminates TLS starts a new connection to the backend. Traffic to a destination outside the mesh leaves the sidecar in whatever protocol the application chose. State each hop and say where plain text exists, instead of assuming that one encrypted edge covers a path.

**It is enforced by a process that sits beside the application.** A pod without a sidecar is not covered by the policy of its own side. A pod that has the annotation `sidecar.istio.io/inject: "false"` is created without one. A container that runs as user 1337, the user of the proxy, is excluded from the traffic redirection, and a container with the `NET_ADMIN` capability can change the iptables rules. Restrict those settings with admission policy.

**It does not replace NetworkPolicy.** `NetworkPolicy` is enforced by the network plug-in in the kernel at the pod boundary, with no proxy needed. A mesh policy is enforced after the connection is accepted. The two controls fail in different ways, so use both: `NetworkPolicy` to limit which pods can connect at all, and mesh policy to decide what an authenticated peer may do.

**It does not make retries safe.** Istio proxies retry some failed requests by default, up to two times for connection failures and refused streams, and routing rules can add more. Repeating a `GET` is usually safe. Repeating a `POST` that creates a payment may create a second one, if the first reached the server and only the response was lost. Retries need an idempotency key or another deduplication mechanism in the application. Timeouts and retry budgets keep a failing dependency from receiving a flood of repeated calls.

## Common pitfalls

> [!WARNING]
> An `ALLOW` policy denies every request that it does not list, including health, metrics and requests from other clients, so list each port and caller that must keep working. `principals` needs mTLS and does not match plain-text requests. Ports in a rule are the container ports. Identity is the service account, and a shared service account shares the permission. A mesh adds a layer of control, and `NetworkPolicy`, application checks and safe retry design are still needed.
