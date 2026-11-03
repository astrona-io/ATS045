# Overview: Network Paths And NetworkPolicy (Playground)

This playground starts a fresh Kubernetes cluster with the Starfleet workloads and no network policy. There is no grading. Every pod can reach every other pod, which is the default of Kubernetes.

## What's in the box

A single-node kind cluster with Kubernetes 1.35.8. kind installs a network plug-in that enforces `NetworkPolicy`.

| Namespace | Object | What it is |
| --- | --- | --- |
| `starfleet` | `scout` | podinfo. Application port 9898 (Service port 80) and metrics port 9797 (Service port 9797) |
| `starfleet` | `probe` | go-httpbin on port 8080 (Service port 80) |
| `starfleet` | `shuttle` | A client with `curl` |
| `outpost` | `drifter` | A client with `curl` |
| `outpost` | `beacon` | go-httpbin on port 8080 (Service port 80). It stands for a server outside the application |
| `ops` | `collector` | A client with `curl`, for an operations tool |

The control plane node is the container `astro-ats-045-playground-060-01-control-plane`.

## Helpers

This function prints the HTTP status of a request from a pod, or `000` when no answer arrives within four seconds:

```sh
reach() {
  kubectl -n "$1" exec "deploy/$2" -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 4 "$3" || true
}
reach starfleet shuttle http://scout.starfleet/
reach outpost drifter http://scout.starfleet/
```

Both requests print `200` until you add a policy.

## Practice tasks

- Create a default-deny ingress policy for `starfleet` and repeat the requests. Read how a dropped connection differs from a refused one, with the exit code of `curl`.
- Allow only `shuttle` to reach `scout` on its container port, and check that `drifter` is still blocked.
- Add an egress policy for `shuttle`, forget the DNS rule on purpose, and read the failure. Then add it.
- Open the metrics port of `scout` only for the `ops` namespace, with a `namespaceSelector` and a `podSelector` in one rule.
- Read the listening ports of the control plane node with `ss -ltn` and request the API server and the kubelet without credentials.
