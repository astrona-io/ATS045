---
estimated_duration: 35m
---

# Lab: Audit Access Changes And Keep The Evidence

**UNTESTED: built from documentation, not yet booted.** Static checks only (`astrona validate`, `bash -n`, YAML parse).

Capstone for the observability section. Turn on audit logging with retention and find who bound access in `starfleet`. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-030/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-030/capstone/labs/lab-01
astrona destroy ats-045-capstone-030-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-audit-with-retention.sh` | Audit logging runs and keeps logs for at least 7 days and 3 backups |
| `validate-rbac-bodies-recorded.sh` | Role and RoleBinding changes are recorded with both bodies |
| `validate-secret-metadata-only.sh` | A Secret read is recorded at Metadata, with no bodies |
| `validate-noise-dropped.sh` | Health checks and the RequestReceived stage are not recorded |
| `validate-binding-evidence.sh` | binding-evidence names the caller, audit ID and subject of a real RoleBinding create |
| `validate-patrol-binder-intact.sh` | The CronJob patrol-binder and its RBAC are unchanged |
