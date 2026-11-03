---
estimated_duration: 35m
---

# Lab: Close The Admission Gaps In Starfleet

**UNTESTED: built from documentation, not yet booted.** Static checks only (`astrona validate`, `bash -n`, YAML parse).

Capstone lab for the admission control section. Find why two admission controls do not protect a namespace and fix the level, the action and the scope. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-070/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-070/capstone/labs/lab-01
astrona destroy ats-045-capstone-070
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-psa-restricted.sh` | starfleet enforces the Pod Security restricted level |
| `validate-image-tags-denied.sh` | A Deployment with the latest tag is rejected in starfleet |
| `validate-scope-limited.sh` | outpost is not covered |
| `validate-policy-hygiene.sh` | The binding denies, no policy ignores failures and the enforce label is restricted |
| `validate-workloads-unchanged.sh` | The workloads still run with their pinned image |
