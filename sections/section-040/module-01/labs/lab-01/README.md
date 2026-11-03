---
estimated_duration: 25m
---

# Lab: Require mTLS And Open One Port

**UNTESTED: built from documentation, not yet booted.** Static checks only (`astrona validate`, `bash -n`, YAML parse).

Graded lab for the service mesh module. Require mutual TLS for a namespace, open one metrics port and read a workload identity from its certificate. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-040/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-040/module-01/labs/lab-01
astrona destroy ats-045-lab-040-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-strict-mtls-required.sh` | starfleet refuses plain text and still serves mesh clients |
| `validate-metrics-port-only.sh` | Port 9797 of scout answers plain text and the application port does not |
| `validate-identity-evidence.sh` | mesh-identities holds the real certificate identity of scout |
| `validate-sidecars-present.sh` | Every running pod in starfleet has a sidecar |
