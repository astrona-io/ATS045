# Solution

Solve this lab on `terminal`. Run `astrona submit` after each step. The lab is built from documentation and has not been booted yet.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-020/module-01/labs/lab-01
```

## Step 1: Create the pull Secret

The server value must match the host in the image reference:

```sh
kubectl -n starfleet create secret docker-registry registry-pull --docker-server=localhost:30500 --docker-username=puller --docker-password=pull-pass-7
```

## Step 2: Attach the Secret to both ServiceAccounts

```sh
kubectl -n starfleet patch serviceaccount scout -p '{"imagePullSecrets":[{"name":"registry-pull"}]}'
kubectl -n starfleet patch serviceaccount probe -p '{"imagePullSecrets":[{"name":"registry-pull"}]}'
```

## Step 3: Restart the Deployments

The ServiceAccount admission controller adds the Secret when a pod is created, so the failing pods must be replaced:

```sh
kubectl -n starfleet rollout restart deployment/scout deployment/probe
kubectl -n starfleet rollout status deployment/scout
kubectl -n starfleet rollout status deployment/probe
```

Run `astrona submit`. All five checks should pass.

## Why the shortcuts fail

Adding `imagePullSecrets` to each Deployment makes the pods run, but `deployments-use-service-account` rejects it. A Secret for a different host than `localhost:30500` is not used by the kubelet. Removing the registry's authentication would fail `registry-still-private`.
