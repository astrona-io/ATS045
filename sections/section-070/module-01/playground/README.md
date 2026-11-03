# Admission Control: Playground

- **Slug:** ats-045-playground-070-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground, clean environment, no task, no grading
- **Status:** UNTESTED: built from documentation, not yet booted.

Clean cluster with compliant Starfleet workloads in `starfleet` and `outpost` and no admission policy.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-070/module-01/playground
astrona destroy ats-045-playground-070-01
```

Authors run the local copy with `astrona run -c .` inside this folder. `astrona destroy` takes the environment name, not the path.
