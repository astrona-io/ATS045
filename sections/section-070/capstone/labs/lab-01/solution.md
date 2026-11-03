# Solution

Solve this lab on `terminal`. Run `astrona submit` after each step. The lab is built from documentation and has not been booted yet.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-070/capstone/labs/lab-01
```

## Step 1: Read the existing controls

```sh
kubectl get namespace starfleet --show-labels
kubectl get validatingadmissionpolicy,validatingadmissionpolicybinding
kubectl get validatingadmissionpolicybinding image-tags-starfleet -o yaml
```

The namespace carries `pod-security.kubernetes.io/enforce=baseline`, so the root pod is admitted. The binding `image-tags-starfleet` has `validationActions: ["Warn"]`, so a violation prints a warning and the request is admitted. Its `namespaceSelector` asks for the label `admission=enforced`, and the namespace has `admission=enforce`, so the binding does not select `starfleet` at all.

## Step 2: Raise the Pod Security level

```sh
kubectl label namespace starfleet pod-security.kubernetes.io/enforce=restricted --overwrite
```

Test with a pod that runs as root with no hardening. Save it as `pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: admission-test
spec:
  containers:
    - name: app
      image: ghcr.io/stefanprodan/podinfo:6.15.0
```

```sh
kubectl apply -n starfleet --dry-run=server -f pod.yaml
```

The request now fails with `violates PodSecurity "restricted:latest"`. Run `astrona submit`. The first check passes.

## Step 3: Fix the binding

Two things are wrong, and each one alone leaves the policy without effect. Replace the action and the selector. Selecting the namespace by its automatic name label cannot be mistyped in a label value, and it leaves `outpost` out:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: image-tags-starfleet
spec:
  policyName: image-tags
  validationActions: ["Deny"]
  matchResources:
    namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: starfleet
```

```sh
kubectl apply -f binding.yaml
```

Test with a Deployment that uses `ghcr.io/stefanprodan/podinfo:latest`, in `starfleet` and in `outpost`. The first is rejected with a message that names the policy. The second is admitted. Run `astrona submit`. All five checks should pass.

## Why the shortcuts fail

Changing only the action to `Deny` does nothing, because the selector still matches no namespace. Changing only the selector gives a policy that warns and admits. Deleting the policy removes the control. Relabelling `outpost` brings it into scope and the scope check fails. Widening the selector to all namespaces has the same result.
