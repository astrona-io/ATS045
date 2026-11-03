# Solution

Solve this lab on `terminal`. Run `astrona submit` after each step to see which checks pass. The lab is built from documentation and has not been booted yet, so treat exact messages as unverified.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-010/module-01/labs/lab-01
```

## Step 1: Pin scout and probe to digests

Read the digest the container runtime resolved for `scout`:

```sh
kubectl -n starfleet get pod -l app=scout -o jsonpath='{.items[0].status.containerStatuses[0].imageID}'
```

The value ends in `@sha256:` and the digest. Use it in `set image`:

```sh
SCOUT_DIGEST=$(kubectl -n starfleet get pod -l app=scout -o jsonpath='{.items[0].status.containerStatuses[0].imageID}' | sed 's/.*@//')
kubectl -n starfleet set image deployment/scout scout=ghcr.io/stefanprodan/podinfo@${SCOUT_DIGEST}
```

Do the same for `probe` with the repository `mccutchen/go-httpbin`:

```sh
PROBE_DIGEST=$(kubectl -n starfleet get pod -l app=probe -o jsonpath='{.items[0].status.containerStatuses[0].imageID}' | sed 's/.*@//')
kubectl -n starfleet set image deployment/probe probe=mccutchen/go-httpbin@${PROBE_DIGEST}
```

Run `astrona submit`. The check `images-pinned` should pass.

## Step 2: Move the password into a mounted Secret

```sh
kubectl -n starfleet create secret generic uplink-db --from-literal=password='orbit-secret-9'
```

Save this as `uplink-patch.yaml`. It deletes the environment variable, adds the volume and the mount, and turns off the ServiceAccount token in one patch:

```yaml
spec:
  template:
    spec:
      automountServiceAccountToken: false
      containers:
        - name: uplink
          env: null
          volumeMounts:
            - name: db-credentials
              mountPath: /etc/uplink
              readOnly: true
      volumes:
        - name: db-credentials
          secret:
            secretName: uplink-db
            defaultMode: 0400
```

Apply it and wait for the new pod:

```sh
kubectl -n starfleet patch deployment uplink --patch-file uplink-patch.yaml
kubectl -n starfleet rollout status deployment/uplink
```

Run `astrona submit`. All five checks should pass.

## Why the shortcuts fail

A `valueFrom.secretKeyRef` environment variable keeps the password in the process environment, so `no-password-in-env` rejects it. Setting `automountServiceAccountToken: false` only on the ServiceAccount does not change the existing pod template, so the running pod keeps its token until it restarts, and `token-not-mounted` checks both the template and the running pod.
