# Solution

Solve this lab on `terminal`. Run `astrona submit` after each step. The lab is built from documentation and has not been booted yet.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-020/capstone/labs/lab-01
```

## Step 1: Rotate the Secret in both namespaces

Create the Secret in each namespace and apply it, which replaces the stored value:

```sh
kubectl -n starfleet create secret docker-registry registry-pull --docker-server=localhost:30500 --docker-username=puller-v2 --docker-password=pull-pass-8 --dry-run=client -o yaml | kubectl apply -f -
kubectl -n outpost create secret docker-registry registry-pull --docker-server=localhost:30500 --docker-username=puller-v2 --docker-password=pull-pass-8 --dry-run=client -o yaml | kubectl apply -f -
```

## Step 2: Read the digest of the tag from the registry

Ask the registry for the manifest headers. The `Accept` header selects the manifest formats:

```sh
kubectl -n starfleet exec deploy/shuttle -- curl -s -I -u puller-v2:pull-pass-8 -H 'Accept: application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json' http://registry.registry.svc.cluster.local:5000/v2/starfleet/podinfo/manifests/6.15.0
```

Copy the value of `Docker-Content-Digest`.

## Step 3: Pin both Deployments and set the pull policy

Replace `<DIGEST>` with the value from the previous step:

```sh
kubectl -n starfleet set image deployment/scout scout=localhost:30500/starfleet/podinfo@<DIGEST>
kubectl -n outpost set image deployment/drifter drifter=localhost:30500/starfleet/podinfo@<DIGEST>
kubectl -n starfleet patch deployment scout -p '{"spec":{"template":{"spec":{"containers":[{"name":"scout","imagePullPolicy":"Always"}]}}}}'
kubectl -n outpost patch deployment drifter -p '{"spec":{"template":{"spec":{"containers":[{"name":"drifter","imagePullPolicy":"Always"}]}}}}'
kubectl -n starfleet rollout status deployment/scout
kubectl -n outpost rollout status deployment/drifter
```

Run `astrona submit`. All six checks should pass.

## Why the shortcuts fail

Creating a second Secret with a new name leaves the old credential stored, and `old-credential-gone` rejects it. Using the tag with the new credential works for pulling but fails `images-pinned-to-registry-digest`. Pods that failed with the revoked credential stay failed until the Deployment creates new pods, which the image change does.
