---
draft: true
exam_objectives:
  - Supply Chain Security
---
# Supply Chain Security

This section teaches how to trace trust from source code to a running container and how to limit what a compromised build or pod can do. You pin an image to its digest, learn where signature verification can be enforced, and keep credentials out of the pod environment.

The section has one module, Trust What You Deploy. It has a playground, a graded lab and a capstone lab on a local kind cluster, and ends with a knowledge check. Each part is followed by the lab that practises it, and the module ends with a summary.

## Learning Outcomes

- Trace source, build, publication and deployment trust boundaries.
- Distinguish provenance, signatures, inventories and vulnerability findings.
- Relate admission decisions to exact artifact identity.
- Move credentials into mounted Secrets and remove unneeded ServiceAccount tokens.

## Contents

| Item | What it is |
| --- | --- |
| Artifact Evidence And Sensitive Build Inputs | Reading part |
| Connecting Verification To Execution Policy | Reading part |
| Credentials And Service Account Tokens | Reading part |
| Summary | Reading part |
| Pin Images By Digest And Mount Credentials As Files | Graded module lab (intermediate) |
| Harden A Build Runner Workload | Section capstone lab (advanced) |
| Knowledge check | `quiz.yaml`, pass score 70 |

## Authoring Status

The labs and the playground in this section are UNTESTED. They were built from documentation and checked only with static tools (`astrona validate`, `bash -n`, YAML parsing).
