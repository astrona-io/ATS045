---
estimated_duration: 40m
---

# Lab: Segment The Starfleet Network

**UNTESTED: built from documentation, not yet booted.** Static checks only (`astrona validate`, `bash -n`, YAML parse).

Capstone lab for the connectivity section. Segment a namespace with default deny in both directions, allow the application paths and open a management port for one client. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-060/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-060/capstone/labs/lab-01
astrona destroy ats-045-capstone-060
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-default-deny-both.sh` | Every pod in starfleet is isolated for ingress and egress |
| `validate-east-west-paths.sh` | shuttle reaches scout and probe by name and nothing else |
| `validate-management-port.sh` | Only the collector in ops reads the metrics port 9797 |
| `validate-egress-contained.sh` | shuttle cannot reach beacon in outpost |
| `validate-policy-hygiene.sh` | No policy allows every source or destination |
| `validate-workloads-unchanged.sh` | The workloads still run and none uses the host network |
