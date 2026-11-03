---
estimated_duration: 30m
---

# Lab: Harden A Build Runner Workload

**UNTESTED: built from documentation, not yet booted.** Static checks only (`astrona validate`, `bash -n`, YAML parse).

Capstone for the supply chain section. A workload in `forge` holds too much authority and must be hardened end to end. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-010/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-010/capstone/labs/lab-01
astrona destroy ats-045-capstone-010
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-dedicated-identity.sh` | build-runner uses its own ServiceAccount without a token |
| `validate-default-account-no-admin.sh` | The default ServiceAccount cannot read Secrets |
| `validate-image-pinned.sh` | The image is referenced by digest |
| `validate-token-secret-as-file.sh` | The registry token is a mounted Secret, not an environment variable |
| `validate-container-hardened.sh` | The container has a hardened security context |
| `validate-build-runner-running.sh` | build-runner is available and answers requests |
