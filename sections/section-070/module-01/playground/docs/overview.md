# Overview: Admission Control (Playground)

This playground starts a fresh Kubernetes cluster with the Starfleet workloads and no admission policy of your own. There is no grading. The API server runs its built-in admission plug-ins, and you add the rest.

## What's in the box

A single-node kind cluster with Kubernetes 1.35.8.

| Namespace | Object | What it is |
| --- | --- | --- |
| `starfleet` | `scout` | podinfo. Meets the Pod Security `restricted` level, pins its image tag and sets a memory limit |
| `starfleet` | `shuttle` | A client with `curl`, with the same settings |
| `outpost` | `drifter` | A client with `curl`, with the same settings |

Neither namespace carries a Pod Security label, and no `ValidatingAdmissionPolicy` exists.

The control plane node is the container `astro-ats-045-playground-070-01-control-plane`.

## Helper

A server-side dry run sends a request through authentication, authorization and admission, and stops before it stores anything. It is the safe way to ask whether an object would be admitted:

```sh
kubectl apply -n starfleet --dry-run=server -f - <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: admission-test
spec:
  containers:
    - name: app
      image: ghcr.io/stefanprodan/podinfo:6.15.0
      securityContext:
        privileged: true
YAML
```

Without a policy, the request prints `pod/admission-test created (server dry run)`.

## Practice tasks

- Label `starfleet` with `pod-security.kubernetes.io/warn=restricted` and repeat the dry run. Read the warning, then change the label to `enforce` and read the rejection.
- Create a `LimitRange` with a default memory limit in `outpost`, create a pod without limits, and read the resulting pod. Read what changed.
- Write a `ValidatingAdmissionPolicy` that requires a memory limit on every container of a Deployment. Bind it with `Warn`, then with `Deny`, and read the difference.
- Limit the binding to `starfleet` with a `namespaceSelector` and check that `outpost` is not affected.
- Register a validating webhook for a labelled `ConfigMap` that points to a Service that does not exist. Compare `failurePolicy: Ignore` with `failurePolicy: Fail`, then delete the webhook.
