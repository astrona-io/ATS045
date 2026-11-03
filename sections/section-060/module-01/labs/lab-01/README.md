---
estimated_duration: 25m
---

# Lab: Isolate A Namespace And Allow One Path

**UNTESTED: built from documentation, not yet booted.** Static checks only (`astrona validate`, `bash -n`, YAML parse).

Graded lab for the connectivity module. Isolate a namespace with a default-deny policy, allow one path and restrict the egress of one client. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-060/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-060/module-01/labs/lab-01
astrona destroy ats-045-lab-060-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-default-deny-ingress.sh` | Pods in starfleet are isolated for ingress |
| `validate-shuttle-reaches-scout.sh` | shuttle reaches scout by name on the application port |
| `validate-shuttle-egress-restricted.sh` | shuttle reaches only scout, and DNS still works |
| `validate-no-wildcard-policy.sh` | No policy allows every source or destination and the default deny stays |
| `validate-workloads-unchanged.sh` | The workloads still run and none uses the host network |
