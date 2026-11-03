---
estimated_duration: 20m
---

# Lab: Pin Images By Digest And Mount Credentials As Files

**UNTESTED: built from documentation, not yet booted.** Static checks only (`astrona validate`, `bash -n`, YAML parse).

Graded lab for the supply chain module. Images start as tags and `uplink` keeps its password in an environment variable. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-010/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-045-lab-010-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-images-pinned.sh` | scout and probe use digest references |
| `validate-no-password-in-env.sh` | uplink has no DB_PASSWORD environment variable |
| `validate-secret-mounted-as-file.sh` | The password is mounted from Secret uplink-db at /etc/uplink |
| `validate-token-not-mounted.sh` | uplink receives no ServiceAccount token |
| `validate-workloads-available.sh` | All workloads are available and shuttle reaches scout |
