# Curriculum Coverage

Exam: Kubernetes and Cloud Native Associate (KCSA). Domain: Platform Security (16%).

Verified against the [official objectives](https://training.linuxfoundation.org/certification/kubernetes-and-cloud-native-security-associate-kcsa/) on 2026-10-11. Module titles and questions are original teaching material, not official exam questions.

| Section | Official objective | Modules | Status |
| --- | --- | --- | --- |
| 010 | Supply Chain Security | 1 | Written; review pending |
| 020 | Image Repository | 1 | Written; review pending |
| 030 | Observability | 1 | Written; review pending |
| 040 | Service Mesh | 1 | Written; review pending |
| 050 | PKI | 1 | Written; review pending |
| 060 | Connectivity | 1 | Written; review pending |
| 070 | Admission Control | 1 | Written; review pending |

| Section / module | Module | Teaching lessons | Measurable outcomes |
| --- | --- | --- | --- |
| 010 / 01 | Supply Chain Trust And Verification | 2 | Trace source, build, publication and deployment trust boundaries.; Distinguish provenance, signatures, inventories and vulnerability findings.; Relate admission decisions to exact artifact identity.; Explain continued maintenance after an artifact is approved. |
| 020 / 01 | Repository Access And Artifact Retention | 2 | Distinguish mutable references from content-addressed artifact identity.; Compare repository push, pull and administrative privileges.; Identify sensitive build layers and retained artifact copies.; Relate publication integrity and credential rotation to deployment trust. |
| 030 / 01 | Security Observability And Evidence Quality | 2 | Distinguish API audit, runtime and application security observations.; Explain telemetry collection and retention trust boundaries.; Relate alert quality to relevant behaviors and response ownership.; Identify sensitive fields and evidence gaps. |
| 040 / 01 | Service Mesh Identity And Policy | 1 | Distinguish encrypted transport, peer authentication and authorization.; Explain where mesh components implement communication policy.; Relate certificate rotation and hop boundaries to trust.; Identify residual application and retry requirements. |
| 050 / 01 | Certificates And Public Key Infrastructure | 1 | Explain public keys, private keys and certificate authority trust.; Distinguish server authentication from mutual TLS.; Relate identity names, validity and trust chains to verification.; Describe rotation and compromise recovery for certificate-based identities. |
| 060 / 01 | Connectivity And Protected Network Paths | 1 | Distinguish private reachability from authenticated authority.; Trace ingress, east-west and management connection boundaries.; Relate segmentation and encryption to different protections.; Identify required dependencies and controlled exceptions. |
| 070 / 01 | Admission Policy And Extension Trust | 1 | Distinguish mutation, validation and authorization.; Explain built-in, declarative and webhook admission mechanisms.; Relate failure policy and exemptions to effective enforcement.; Identify extension credentials, transport and availability requirements. |

Every section begins with an introduction. Every module ends with a summary before the next module. YAML checkpoint banks follow selected section summaries; a domain review bank closes the course. They are indexed separately for future application integration.

This course has no labs or playgrounds, as requested by the maintainer. All material is readable without a cluster. Technical content remains draft until review; no runtime execution or lab validation is claimed.
