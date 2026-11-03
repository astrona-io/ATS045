---
estimated_duration: 25m
---

# Lab: Record API Activity With Audit Logging

**UNTESTED: built from documentation, not yet booted.** Static checks only (`astrona validate`, `bash -n`, YAML parse).

Graded lab for the observability module. Turn on API server audit logging, write a policy and find a deletion in the log. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-030/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-030/module-01/labs/lab-01
astrona destroy ats-045-lab-030-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-audit-logging-enabled.sh` | The API server runs with an audit policy file and writes /var/log/kubernetes/audit/audit.log |
| `validate-secret-metadata-only.sh` | A Secret read is recorded at Metadata level, with no request or response body |
| `validate-deployment-bodies-recorded.sh` | Deployment changes are recorded at RequestResponse, with both bodies |
| `validate-noise-dropped.sh` | Health checks and the RequestReceived stage are not recorded |
| `validate-probe-deletion-evidence.sh` | The ConfigMap probe-deletion in starfleet names the caller and the audit ID of a real deletion of probe |
