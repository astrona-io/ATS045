# Solution

Solve this lab on `terminal`. Run `astrona submit` after each step. The lab is built from documentation and has not been booted yet.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-070/module-01/labs/lab-01
```

## Step 1: Enforce a Pod Security level on the namespace

Pod Security Admission reads labels on the namespace. The `enforce` mode rejects a pod that violates the level:

```sh
kubectl label namespace starfleet pod-security.kubernetes.io/enforce=restricted
```

Test with a privileged pod. Save it as `pod.yaml`:

```yaml
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
```

```sh
kubectl apply -n starfleet --dry-run=server -f pod.yaml
```

The request fails with a message that starts `violates PodSecurity "restricted:latest"` and lists the privileged container. Run `astrona submit`. The first check passes.

## Step 2: Write the validation policy

A `ValidatingAdmissionPolicy` holds the rule, written in the Common Expression Language (CEL). It does nothing until a binding applies it. Save this as `policy.yaml`:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: require-memory-limit
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
      - apiGroups: ["apps"]
        apiVersions: ["v1"]
        operations: ["CREATE", "UPDATE"]
        resources: ["deployments"]
  validations:
    - expression: |-
        object.spec.template.spec.containers.all(c, has(c.resources) && has(c.resources.limits) && "memory" in c.resources.limits)
      message: "Every container must set a memory limit."
```

## Step 3: Bind the policy to starfleet

The binding chooses the namespaces and what happens on a violation. `Deny` rejects the request. `Warn` returns a warning and admits it, and `Audit` records the violation in the audit event:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: require-memory-limit-starfleet
spec:
  policyName: require-memory-limit
  validationActions: ["Deny"]
  matchResources:
    namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: starfleet
```

```sh
kubectl apply -f policy.yaml
kubectl apply -f binding.yaml
```

Test with a Deployment that has no memory limit, in `starfleet` and in `outpost`. The request to `starfleet` fails with a message that names the policy and the binding. The request to `outpost` is admitted, because the binding does not select that namespace. The policy needs a few seconds to compile, so repeat the request if the first one is admitted. Run `astrona submit`. All five checks should pass.

## Why the shortcuts fail

Labelling `outpost` with the Pod Security level breaks the scope check. A binding with `Warn` prints a warning and admits the object, so the policy check fails. A policy with `failurePolicy: Ignore` is flagged by the hygiene check, because an error in the policy would then admit every request. A change to the workloads is not needed, and the last check fails if `scout` stops running.
