# Solution

Solve this lab on `terminal`. Run `astrona submit` after each step. The lab is built from documentation and has not been booted yet.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-060/module-01/labs/lab-01
```

## Step 1: Isolate the namespace

A policy with an empty `podSelector` selects every pod in its namespace. With `Ingress` in `policyTypes` and no `ingress` rules, it allows no incoming traffic. Save this as `deny.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: starfleet
spec:
  podSelector: {}
  policyTypes: ["Ingress"]
```

```sh
kubectl apply -f deny.yaml
kubectl -n outpost exec deploy/drifter -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 4 http://scout.starfleet/
```

The request prints `000` after four seconds. A dropped connection gives no answer, and a closed port gives a refusal at once. Run `astrona submit`. The first check passes.

## Step 2: Allow one path

Policies only add allowed paths. Allow `shuttle` to reach `scout`. The port is the container port 9898, because the policy is evaluated after the Service has been translated:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: scout-from-shuttle
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
```

Apply it and test:

```sh
kubectl apply -f scout-from-shuttle.yaml
kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 4 http://scout.starfleet/
```

The request prints `200`. Run `astrona submit`.

## Step 3: Restrict the egress of shuttle

An egress policy limits what the selected pods may send. It needs a DNS rule, because the name `scout.starfleet` is resolved by a request to CoreDNS in `kube-system`:

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
    - to:
        - podSelector:
            matchLabels:
              app: scout
      ports:
        - protocol: TCP
          port: 9898
```

```sh
kubectl apply -f shuttle-egress.yaml
kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 4 http://scout.starfleet/
kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 4 http://beacon.outpost/get
```

The first request prints `200` and the second prints `000`. Run `astrona submit`. All five checks should pass.

## Why the shortcuts fail

Deleting the deny policy opens every path and the first check fails. A rule with an empty `from` allows every source, and the hygiene check fails. Without the DNS rule, the request from `shuttle` to `scout` fails at name resolution, so the egress check fails. Using the Service port 80 in the policy blocks the traffic, because the policy matches the container port.
