---
estimated_duration: 20m
---

# Lab: Fix ImagePullBackOff With A Pull Secret

**UNTESTED: built from documentation, not yet booted.** Static checks only (`astrona validate`, `bash -n`, YAML parse).

Graded lab for the image repository module. Two workloads cannot pull from a private registry. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-020/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-020/module-01/labs/lab-01
astrona destroy ats-045-lab-020-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-pull-secret.sh` | registry-pull is a dockerconfigjson Secret for localhost:30500 as puller |
| `validate-service-accounts-carry-secret.sh` | scout and probe ServiceAccounts list the Secret |
| `validate-deployments-use-service-account.sh` | The Deployments do not repeat imagePullSecrets |
| `validate-workloads-running.sh` | scout and probe are available |
| `validate-registry-still-private.sh` | The registry still refuses unauthenticated calls |
