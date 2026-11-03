---
draft: true
exam_objectives:
  - Admission Control
---
# Summary

- **Order.** Authentication, authorization, mutating admission, schema validation, validating admission, then the write to etcd. Validation sees the object after mutation. Reads are not admitted.
- **Authorization and admission.** Authorization checks the verb and the resource. Admission reads the object. An authorized caller can still submit an unsafe object.
- **Dry run.** `kubectl apply --dry-run=server` goes through admission and stores nothing. A client-side dry run never reaches it.
- **Pod Security Admission.** Namespace labels set a level (`privileged`, `baseline`, `restricted`) per mode (`enforce`, `warn`, `audit`). It checks Pods, so a Deployment is admitted and its Pods fail later. Existing Pods stay.
- **ValidatingAdmissionPolicy.** A policy holds a CEL rule, and a binding applies it. No binding or no matching namespace means no check. `Deny` rejects, `Warn` and `Audit` admit.
- **Webhooks.** The API server posts an `AdmissionReview` to a service over HTTPS. `failurePolicy` decides the outcome when the service does not answer: `Fail` blocks, `Ignore` admits. Selectors decide coverage.
- **Trust.** A webhook workload, its image and its configuration are part of the trust chain. Exceptions and the labels that grant them are bypasses.
- **Evidence.** Approval of a mutable tag is not approval of the content. Bind the approval to a digest.

<!-- astrona:playground:destroy -->
