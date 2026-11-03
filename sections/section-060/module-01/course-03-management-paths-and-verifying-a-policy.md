---
draft: true
exam_objectives:
  - Connectivity
---
# Management Paths And Verifying A Policy

Some ports carry authority instead of application data. The API server decides what every other component may do, the kubelet runs containers on a node, and etcd holds every Secret of the cluster. Metrics ports are less powerful, but they describe the system to anyone who reads them. This part lists these ports, shows what protects each one, and then shows how to test a policy so that the result means something.

## The management ports of a cluster

A kubeadm control plane node listens on these ports:

| Port | Component | What it does |
| --- | --- | --- |
| 6443 | `kube-apiserver` | The Kubernetes API. Every client and every component uses it |
| 2379 and 2380 | `etcd` | The data store. Port 2379 is for clients, 2380 for other etcd members |
| 10250 | `kubelet` | Runs and inspects containers on the node. It serves `exec`, logs and metrics |
| 10257 | `kube-controller-manager` | Health and metrics |
| 10259 | `kube-scheduler` | Health and metrics |

Worker nodes listen on 10250 for the kubelet, and `kube-proxy` serves its metrics on 10249 and health on 10256. Each port has its own protection, and none of them is a `NetworkPolicy`:

- The API server requires a client to authenticate. A request with no credential is treated as the user `system:anonymous`. The default roles let that user read only a few public paths such as `/version`, `/healthz` and `/readyz`. Every other path answers `403`.
- etcd requires a client certificate that the etcd certificate authority signed. The API server is the only client that should have one.
- The kubelet in a kubeadm cluster does not allow anonymous requests, and it sends each request to the API server to check whether the caller may do it. A call without a credential gets `401`.

Policies select pods, and the control plane processes run on the node, so a pod policy does not select these ports as a destination. Protection of these ports comes from where the node network is exposed (a firewall or a private network), from authentication at the port, and from authorization of what each caller may do.

## Why reachability still matters

Authentication at the port does not make reachability harmless. A reachable port can be probed for an unpatched bug, flooded with requests, or attacked with a stolen credential from anywhere. Every caller that cannot reach the port is one less place from which a stolen credential works. A design limits the reachability of the API server and kubelet to the nodes, the operators and the tools that need them, and also requires authentication and authorization at the port. Each control covers the failure of the other.

<!-- astrona:playground:renew -->

Read the listening ports of the control plane node and test what an unauthenticated caller can do. The node is a container, so run the commands in it with `podman exec` or `docker exec`:

```sh
export CONTROL_PLANE=astro-ats-045-playground-060-01-control-plane
node() { podman exec -i "$CONTROL_PLANE" "$@"; }
node ss -ltn
```

The output lists the sockets in the listening state. Find 6443, 2379, 2380, 10250, 10257 and 10259, and look at the local address column. A port bound to `127.0.0.1` accepts connections from the node itself only. A port bound to `0.0.0.0` or to the node address accepts connections from the node network too. Check what an unauthenticated caller gets:

```sh
node curl -sk -o /dev/null -w 'version: %{http_code}\n' https://127.0.0.1:6443/version
node curl -sk -o /dev/null -w 'namespaces: %{http_code}\n' https://127.0.0.1:6443/api/v1/namespaces
node curl -sk -o /dev/null -w 'kubelet: %{http_code}\n' https://127.0.0.1:10250/pods
```

`/version` answers `200`, the namespace list answers `403`, and the kubelet answers `401`. The `-k` option skips the check of the server certificate, which is acceptable for a local test and wrong for any real client.

## Metrics and other read-only ports

An application can expose a second port for metrics. `scout` serves them on 9797 apart from its application port. Metrics describe request counts, error rates, versions and sometimes internal names. They give an attacker a map of the system and show when an attack is working. The port has no authentication in many applications, so the network is the only control.

A policy opens such a port for the operations tool only. The `scout` policy has two ingress rules: one for the application port and one for the metrics port. The rule for the metrics port matches the pod `collector` in the namespace `ops`, with both selectors in the same item. A policy that opened the metrics port for the whole namespace, or for all pods that carry a label, would let more clients read it than the design says.

## Verifying a policy

A policy is a claim that has to be tested. A test needs three things:

- **The right source.** Send the request from the pod that the policy is about, with `kubectl exec`, or from a pod with the same labels in the same namespace. A request from your workstation, from the node or from `kubectl port-forward` takes another path. A port-forward is opened by the kubelet inside the network namespace of the pod, so a network policy usually does not apply to it. A passing test from the wrong place proves nothing.
- **Both outcomes.** Test that the intended path works and that at least one path that should be blocked fails. A policy that blocks everything passes the second test, and a missing policy passes the first.
- **The right failure.** Read how a request fails and place the failure.

| Result | Meaning |
| --- | --- |
| Exit code 6 | The name did not resolve. Look at DNS, the Service name, the namespace and the egress rule for port 53 |
| Exit code 7 | The connection was refused. The route works and nothing listens on that port. Look at the port and the Service `targetPort` |
| Exit code 28 | No answer within the timeout. A filter dropped the packets, or the pod is not reachable. Look at policies |
| HTTP `4xx` or `5xx` | The connection works and the application answered. The network path is not the cause |

When a path is dropped and should be allowed, read the policies that select the destination pod and check the labels of the pods and of the namespace:

```sh
kubectl -n starfleet get networkpolicy
kubectl -n starfleet describe networkpolicy scout-ingress
kubectl -n starfleet get pod --show-labels
kubectl get namespace --show-labels
```

A selector that does not match any pod is not an error. A typo in a label produces a policy that selects nothing, and a rule that allows nothing. In `describe` output, compare the `PodSelector` line with the labels of the pods.

## A policy states a contract

A reviewable connectivity design lists each path: the source, the destination, the port, whether the hop is encrypted and which identity is checked. The `NetworkPolicy` objects implement the source, destination and port. Encryption and identity come from TLS and from the application. A cluster in which every path has an entry in this list, and every entry has a test, has no implicit trust between its pods.

Run a final check of the example cluster. Apply a policy that opens only the metrics port of `scout` for `collector`, then test one allowed path and three blocked paths from the pods that send them:

```sh
reach() {
  kubectl -n "$1" exec "deploy/$2" -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 4 "$3" || true
}
SCOUT_IP=$(kubectl -n starfleet get pod -l app=scout -o jsonpath='{.items[0].status.podIP}')
reach ops collector "http://$SCOUT_IP:9797/metrics"
reach starfleet shuttle "http://$SCOUT_IP:9797/metrics"
reach outpost drifter "http://$SCOUT_IP:9797/metrics"
reach ops collector "http://$SCOUT_IP:9898/"
```

With a policy that opens only the metrics port for `collector`, the first request prints `200` and the other three print `000`.

## Common pitfalls

> [!WARNING]
> A management port that needs authentication is still a target when it is reachable from every network, so limit both reachability and permissions. Host ports of the node are not selected by pod policies. A test from your workstation or through `kubectl port-forward` does not use the path that the policy controls. A label typo creates a policy that selects no pod and allows nothing, without any error.
