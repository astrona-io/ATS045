---
estimated_duration: 25m
---

# Lab: Enforce A Pod Standard And Write A Validation Policy

**UNTESTED: built from documentation, not yet booted.** Static checks only (`astrona validate`, `bash -n`, YAML parse).

Graded lab for the admission control module. Enforce a Pod Security level on one namespace, write a validating admission policy with a binding and keep the scope narrow. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-070/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-070/module-01/labs/lab-01
astrona destroy ats-045-lab-070-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-psa-restricted.sh` | starfleet enforces the Pod Security restricted level |
| `validate-memory-limit-policy.sh` | A Deployment without a memory limit is rejected in starfleet |
| `validate-scope-limited.sh` | outpost is not covered |
| `validate-policy-hygiene.sh` | The binding denies, no policy ignores failures and the enforce label is restricted |
| `validate-workloads-unchanged.sh` | The workloads still run with their pinned image |
