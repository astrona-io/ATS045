---
draft: true
exam_objectives:
  - Supply Chain Security
---
# Summary

A container image passes through source, build, publication and deployment before it runs. Each step is a trust boundary, and evidence gathered later cannot repair a weakness that appeared earlier. A digest identifies the exact bytes of an image. A signature states who approved that digest. Provenance describes how it was built, a software bill of materials lists what it contains, and a vulnerability scan compares that list with known flaws on the day it runs. None of these replaces the others, and none proves that the application behaves safely.

A tag is a movable name, so a Deployment that uses a tag can run different content after the next pull. Pinning a workload to a digest makes the cluster pull exactly the approved content. Enforcement needs a check at creation time: a validating admission policy can require the digest form, and an admission webhook run by a policy engine can verify signatures against a named signer. Such a webhook is also a dependency, so its failure policy decides whether it blocks everything or enforces nothing when it is unavailable.

Credentials need the same care. A password in an environment variable is visible in the manifest, in `describe` output and in child processes. A Secret mounted as a read-only file keeps it out of the environment, and RBAC and encryption at rest protect the Secret itself. A pod that does not call the Kubernetes API should not receive a ServiceAccount token, so `automountServiceAccountToken: false` removes one credential an attacker could steal. Rotation is complete only when the old credential stops working at the issuer.

Key facts:

- A digest looks like `sha256:` followed by 64 hexadecimal characters.
- `imageID` in the pod status shows the digest that ran. The `image` field shows what was requested.
- A mounted Secret volume updates when the Secret changes unless it uses `subPath`.

<!-- astrona:playground:destroy -->
