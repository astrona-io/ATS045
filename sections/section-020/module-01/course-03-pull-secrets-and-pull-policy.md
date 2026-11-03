---
draft: true
exam_objectives:
  - Image Repository
---
# Pull Secrets And Pull Policy

A node pulls an image on behalf of a pod, so Kubernetes must hand the node a credential when the pod is created. The object that carries it is a pull Secret, and the places that reference it are the pod and the ServiceAccount. This part creates a pull Secret, attaches it to a ServiceAccount, fixes the failing `scout` pod, and explains how `imagePullPolicy` and rotation change the security of the result.

## Create a pull Secret

A pull Secret is a Secret of type `kubernetes.io/dockerconfigjson`. Its single key, `.dockerconfigjson`, holds a JSON document with the registry address and the base64 encoding of `username:password`. The `kubectl create secret docker-registry` command builds it:

<!-- astrona:playground:renew -->

```sh
kubectl -n starfleet create secret docker-registry registry-pull --docker-server=localhost:30500 --docker-username=puller --docker-password=pull-pass-7
```

The `--docker-server` value must match the registry host in the image reference exactly, because the kubelet looks up the credential by that host. A Secret for `registry.registry.svc.cluster.local:5000` would not be used for an image that starts with `localhost:30500`. A Secret is namespaced, so this one exists only in `starfleet`, and a pod in another namespace cannot reference it.

## Attach it to a ServiceAccount

A pod can name its pull Secrets in `spec.imagePullSecrets`. That works, but every manifest must repeat it. A ServiceAccount can carry `imagePullSecrets` too, and the ServiceAccount admission controller copies them into every pod that runs under that account when the pod is created. One change to the account then covers all of its workloads.

Patch the ServiceAccount `scout`:

```sh
kubectl -n starfleet patch serviceaccount scout -p '{"imagePullSecrets":[{"name":"registry-pull"}]}'
```

The pod that is already failing does not change. The copy happens at pod creation, and the kubelet reads the Secret list of the pod object. Restart the Deployment so the controller creates a new pod:

```sh
kubectl -n starfleet rollout restart deployment/scout
kubectl -n starfleet rollout status deployment/scout
```

The rollout finishes, because the new pod carries the pull Secret. Confirm that the Deployment itself holds no pull Secret, and that the pod does:

```sh
kubectl -n starfleet get deploy scout -o jsonpath='{.spec.template.spec.imagePullSecrets}'
kubectl -n starfleet get pod -l app=scout -o jsonpath='{.items[0].spec.imagePullSecrets}'
```

The first command prints nothing. The second prints the Secret name. The admission controller added it to the pod, and the Deployment template stays clean.

## What imagePullPolicy changes

The field `imagePullPolicy` decides when the kubelet contacts the registry. With `Always`, it asks the registry on every container start, which resolves the tag again and checks the credential each time. With `IfNotPresent`, it uses an image that is already on the node and contacts the registry only when the image is missing. With `Never`, it only uses what is on the node. The default is `Always` for the tag `latest` or no tag, and `IfNotPresent` otherwise.

This is a security setting. A node that cached a private image lets any pod on that node start it with `IfNotPresent`, even a pod without a pull Secret. The credential check is skipped, because the kubelet never contacts the registry. Setting `imagePullPolicy: Always` makes every start prove access. A cluster can also enforce this with the `AlwaysPullImages` admission controller, which forces the policy to `Always` for every pod.

## Rotate a pull credential

Rotation means replacing a credential before it leaks or after it did. Create the new credential at the registry first, then give the new value to the cluster, then revoke the old credential at the registry. Replacing the Secret value in the cluster while the old account stays valid does not revoke anything. A ServiceAccount that references the Secret by name keeps working after you replace the Secret in place:

```sh
kubectl -n starfleet create secret docker-registry registry-pull --docker-server=localhost:30500 --docker-username=puller --docker-password=pull-pass-7 --dry-run=client -o yaml | kubectl apply -f -
```

The command renders the Secret to YAML on your machine and applies it, which replaces the stored value. Running pods are not affected, since their images are already pulled. New pods use the new value. Remember that a credential written to a Secret can also be read by anyone with `get` permission on Secrets in that namespace, so limit that RBAC permission too.

## Scope of a pull credential

Give each namespace only the credential it needs, and prefer a credential limited to pulling from specific repositories. A cluster-wide pull credential stored in every namespace turns one stolen Secret into access to every private image. Per-team credentials limit the loss.

## Diagnose a pull failure in order

When a pod stays in `ImagePullBackOff`, work from the outside in. Four causes explain nearly every case, and the events of the pod tell them apart.

The first cause is the name: a wrong host, repository or tag gives a not found error from the registry. The second is the credential: a missing, wrong or expired pull Secret gives an unauthorized error. The third is the Secret reference: the Secret exists in another namespace, has a different host, or is not listed on the pod, so the kubelet has nothing to send. The fourth is the network: the node cannot reach the registry, which gives a timeout or a connection error.

Check them in this order. Read the image string in the pod. Read `imagePullSecrets` on the pod, not only on the Deployment. Decode the Secret and compare the host. Last, test the registry from a pod with `curl`. This order stops you from changing credentials when the real problem is a typo.

```sh
kubectl -n starfleet get secret registry-pull -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d
```

The command prints the JSON with the registry host and the encoded credential. Treat that output as a secret: do not paste it into a ticket.

A fifth case appears after the credential works: the node pulled the image once and now caches it. Later failures can then hide, because pods with `IfNotPresent` start from the cache. Test pull access with a fresh node or with `Always`, not only with a pod that already ran.

## Common pitfalls

> [!WARNING]
> - Expecting a running pod to pick up a new ServiceAccount `imagePullSecrets`. Only new pods do.
> - Creating the Secret for a different registry host than the one in the image reference.
> - Using `imagePullPolicy: IfNotPresent` and assuming it still checks credentials. A cached image is used without any check.
> - Replacing the Secret value in the cluster and forgetting to revoke the old credential at the registry.
