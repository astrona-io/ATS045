---
draft: true
exam_objectives:
  - Admission Control
---
# Pod Security Admission And Validating Admission Policy

Two admission mechanisms run inside the API server and need no extra workload: Pod Security Admission, which checks Pods against a fixed set of standards, and ValidatingAdmissionPolicy, which checks any object against a rule that you write. This part shows how each one decides, how the namespace or the binding sets its scope and mode, and where each one can fail to protect.

## Pod Security Admission

Pod Security Admission checks a Pod against one of three standards:

| Level | What it allows |
| --- | --- |
| `privileged` | Everything. No restriction |
| `baseline` | Blocks the known privilege escalations: privileged containers, host namespaces, host paths, extra capabilities and similar settings |
| `restricted` | Follows current hardening practice: non-root user, no privilege escalation, all capabilities dropped, a seccomp profile, and limited volume types |

The level is not a field of the Pod. It is set with labels on the **namespace**, one per mode:

- `pod-security.kubernetes.io/enforce`: reject a Pod that violates the level.
- `pod-security.kubernetes.io/warn`: admit the Pod and send a warning to the client.
- `pod-security.kubernetes.io/audit`: admit the Pod and record the violation in the audit event.

The three modes are independent, and each can have its own level. A common migration sets `warn` and `audit` to `restricted` first, reads what would break, fixes the workloads, and then sets `enforce`. A namespace with no label uses the cluster default, which is `privileged` unless an operator configured another one. An optional `-version` label, such as `pod-security.kubernetes.io/enforce-version`, pins the version of the standard. Without it the level follows the latest version of the cluster.

<!-- astrona:playground:renew -->

Set a warning on `starfleet` and ask the API server whether a privileged Pod would be admitted:

```sh
kubectl label namespace starfleet pod-security.kubernetes.io/warn=restricted
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

The command prints a line that starts with `Warning: would violate PodSecurity "restricted:latest"` and lists each setting that breaks the level. The Pod is still admitted. Change the mode to `enforce` and repeat the request:

```sh
kubectl label namespace starfleet pod-security.kubernetes.io/enforce=restricted
```

The same request fails with `violates PodSecurity "restricted:latest"` and the same list of settings.

## Pod Security with controllers

Pod Security Admission checks **Pods**. A Deployment, a StatefulSet or a Job contains a Pod template, and a request to create one is admitted with a warning at most, because the object is not a Pod. The Pod is created later by a controller, and the controller's request is the one that is rejected. The result is a Deployment that exists, shows `0/1` ready, and has an event that explains the rejection. Try it in a scratch namespace:

```sh
kubectl create namespace psa-demo
kubectl label namespace psa-demo pod-security.kubernetes.io/enforce=restricted
kubectl -n psa-demo create deployment root-app --image=ghcr.io/stefanprodan/podinfo:6.15.0
kubectl -n psa-demo get deployment root-app
kubectl -n psa-demo get events --field-selector reason=FailedCreate
```

The Deployment is created without an error and has no ready replicas. The event lists the `restricted` violations. A person who reads only the output of `kubectl apply` sees success. Delete the namespace when you are done:

```sh
kubectl delete namespace psa-demo
```

Two more limits matter. A label change does not touch Pods that already run. Enforcement applies to new Pods and to updates of Pods, and a Pod that was admitted before stays. And an operator can exempt users, namespaces or runtime classes in the Pod Security configuration of the API server. Every exemption is a bypass that needs an owner.

## ValidatingAdmissionPolicy

Pod Security has fixed standards. For any other rule, such as "every Deployment needs a memory limit", a `ValidatingAdmissionPolicy` holds the rule and runs in the API server. Two objects work together:

- The **policy** says which requests it matches and what must be true. The rule is an expression in the Common Expression Language (CEL), which can read `object`, `oldObject`, `request` and parameters.
- The **binding** applies the policy: it names the policy, chooses the namespaces or objects, and sets what happens when the rule is false.

A policy with no binding checks nothing. A binding that selects no namespace checks nothing.

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
---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: require-memory-limit-starfleet
spec:
  policyName: require-memory-limit
  validationActions: ["Warn"]
  matchResources:
    namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: starfleet
```

`validationActions` is a list, and it decides what a violation does:

| Action | Effect |
| --- | --- |
| `Deny` | Reject the request with the message of the rule |
| `Warn` | Admit the request and send the message as a warning |
| `Audit` | Admit the request and add the message to the audit event |

`Warn` and `Audit` can be set together, and `Deny` can be combined with either. A binding with only `Warn` is a policy that nobody has to obey, which is the right setting for a rollout and the wrong setting for a control.

Save both objects in `policy.yaml`, apply them, and send a Deployment that has no memory limit:

```sh
kubectl apply -f policy.yaml
kubectl apply -n starfleet --dry-run=server -f - <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: admission-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: admission-test
  template:
    metadata:
      labels:
        app: admission-test
    spec:
      containers:
        - name: app
          image: ghcr.io/stefanprodan/podinfo:6.15.0
YAML
```

The API server needs a few seconds to compile a new policy, so a request sent at once can be admitted. Repeat it. With `Warn` the output is a warning that names the policy and the binding, and the Deployment is admitted. Edit the binding to `validationActions: ["Deny"]`, apply it, and repeat the request. The request now fails with a message that names the policy, the binding and the text of the rule. Send the same Deployment to `outpost`. It is admitted, because the binding selects `starfleet` only.

## Scope, failure and what a rule cannot see

- **Matching.** A rule covers the resources, operations and namespaces that it matches, and nothing else. A rule for `deployments` does not cover a `CronJob` or a bare Pod. A `namespaceSelector` that uses a label that nobody set, or that is spelled differently from the label on the namespace, selects no namespace and the rule never runs. The label `kubernetes.io/metadata.name` is set by Kubernetes on every namespace, so a selector on it cannot drift.
- **Failure policy.** `failurePolicy: Fail` rejects a request when the policy itself cannot be evaluated, for example when an expression raises an error on an unexpected object. `Ignore` admits it. Prefer `Fail` for a control, and make the expression handle absent fields with `has()`.
- **Parameters.** A policy can read a parameter object, such as an allowed list, so that the rule is written once and the values are changed without editing the policy.
- **Exemptions.** A binding can leave out namespaces by selector. Each exemption needs a reason and an owner, and whoever can edit the labels used for matching can move a namespace in or out of scope.
- **Who can change the rules.** The policy, the binding and the namespace labels are API objects. An identity that may update them can weaken the control, so keep that permission narrow.

## Common pitfalls

> [!WARNING]
> A binding with `Warn` or `Audit` only does not block anything. A selector that matches no namespace silently disables a rule. Pod Security checks Pods, so a Deployment is admitted and its Pods fail later with no error at apply time. Existing Pods are not removed when a level is raised. A policy with `failurePolicy: Ignore` admits every request that it cannot evaluate.
