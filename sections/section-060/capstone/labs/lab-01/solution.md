# Solution

Solve this lab on `terminal`. Run `astrona submit` after each step. The lab is built from documentation and has not been booted yet.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-060/capstone/labs/lab-01
```

## Step 1: Deny everything in both directions

Save this as `deny.yaml` and apply it:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: starfleet
spec:
  podSelector: {}
  policyTypes: ["Ingress", "Egress"]
```

```sh
kubectl apply -f deny.yaml
kubectl -n outpost exec deploy/drifter -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 4 http://scout.starfleet/
```

The request prints `000`. Every pod now has no allowed paths in either direction, including the lookup of names. Run `astrona submit`. The first check passes and the path checks fail until you add the allow rules.

## Step 2: Allow names to resolve

Egress deny also blocks the request to CoreDNS. Allow it for every pod in the namespace:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: starfleet
spec:
  podSelector: {}
  policyTypes: ["Egress"]
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
```

## Step 3: Allow the application paths

A path between two pods needs both sides. `shuttle` needs an egress rule, and `scout` and `probe` need an ingress rule. Policies use the container ports, 9898 and 8080:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: shuttle-egress
  namespace: starfleet
spec:
  podSelector:
    matchLabels:
      app: shuttle
  policyTypes: ["Egress"]
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: scout
      ports:
        - protocol: TCP
          port: 9898
    - to:
        - podSelector:
            matchLabels:
              app: probe
      ports:
        - protocol: TCP
          port: 8080
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: probe-ingress
  namespace: starfleet
spec:
  podSelector:
    matchLabels:
      app: probe
  policyTypes: ["Ingress"]
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: shuttle
      ports:
        - protocol: TCP
          port: 8080
```

## Step 4: Allow the management port for one client

The metrics port is a separate port of `scout`. Put the `namespaceSelector` and the `podSelector` in the same `from` item. The two selectors are then combined with AND, so only a pod labelled `app=collector` in the namespace `ops` matches. Two separate items would be combined with OR and would allow every pod in `ops` and every `collector`-labelled pod in `starfleet`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: scout-ingress
  namespace: starfleet
spec:
  podSelector:
    matchLabels:
      app: scout
  policyTypes: ["Ingress"]
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: shuttle
      ports:
        - protocol: TCP
          port: 9898
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ops
          podSelector:
            matchLabels:
              app: collector
      ports:
        - protocol: TCP
          port: 9797
```

Apply the files and test:

```sh
kubectl apply -f .
SCOUT_IP=$(kubectl -n starfleet get pod -l app=scout -o jsonpath='{.items[0].status.podIP}')
kubectl -n ops exec deploy/collector -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 4 http://$SCOUT_IP:9797/metrics
kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 4 http://$SCOUT_IP:9797/metrics
kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 4 http://beacon.outpost/get
```

The first request prints `200`. The second and third print `000`. Run `astrona submit`. All six checks should pass.

## Why the shortcuts fail

An `ipBlock` of `0.0.0.0/0` or an empty `to` opens every destination, and the hygiene check fails. Without the DNS rule, `shuttle` cannot resolve `scout.starfleet`. Allowing the whole `ops` namespace on port 9797 instead of the `collector` pod opens the port to more clients than the task allows.
