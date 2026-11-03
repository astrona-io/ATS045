# Network Paths And NetworkPolicy: Playground

- **Slug:** ats-045-playground-060-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground, clean environment, no task, no grading
- **Status:** UNTESTED: built from documentation, not yet booted.

Clean cluster with the Starfleet workloads in `starfleet`, `outpost` and `ops` and no network policy.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-060/module-01/playground
astrona destroy ats-045-playground-060-01
```

Authors run the local copy with `astrona run -c .` inside this folder. `astrona destroy` takes the environment name, not the path.
