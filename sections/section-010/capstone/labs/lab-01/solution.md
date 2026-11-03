# Solution

Solve this lab on `terminal`. Run `astrona submit` after each step. The lab is built from documentation and has not been booted yet.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-010/capstone/labs/lab-01
```

## Step 1: Read the digest and remove the broad grant

```sh
kubectl -n forge get pod -l app=build-runner -o jsonpath='{.items[0].status.containerStatuses[0].imageID}'
kubectl -n forge delete rolebinding default-admin
```

Keep the digest, the part after the `@`. The `default` ServiceAccount can no longer read Secrets after the binding is gone.

## Step 2: Replace the Deployment

Save this as `build-runner.yaml`, and replace `<DIGEST>` with the digest, for example `sha256:` followed by 64 hexadecimal characters:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: build-runner
  namespace: forge
  labels:
    app: build-runner
spec:
  replicas: 1
  selector:
    matchLabels:
      app: build-runner
  template:
    metadata:
      labels:
        app: build-runner
    spec:
      serviceAccountName: build-runner
      automountServiceAccountToken: false
      securityContext:
        runAsNonRoot: true
        runAsUser: 65532
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: build-runner
          image: mccutchen/go-httpbin@<DIGEST>
          ports:
            - name: http
              containerPort: 8080
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: ["ALL"]
          volumeMounts:
            - name: registry-token
              mountPath: /etc/build-runner
              readOnly: true
          resources:
            requests:
              cpu: 10m
              memory: 16Mi
            limits:
              memory: 64Mi
      volumes:
        - name: registry-token
          secret:
            secretName: registry-token
```

Apply it and wait:

```sh
kubectl apply -f build-runner.yaml
kubectl -n forge rollout status deployment/build-runner
```

Run `astrona submit`. All six checks should pass.

## Why the shortcuts fail

Deleting the RoleBinding without a dedicated ServiceAccount leaves the token mounted, and `dedicated-identity` rejects that. A `secretKeyRef` environment variable still exposes the token in the process environment. A read-only root file system works here because `go-httpbin` writes nothing to disk.
