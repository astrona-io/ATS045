# Trust What You Deploy: Playground

- **Slug:** ats-045-playground-010-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground, clean environment, no task, no grading
- **Status:** UNTESTED: built from documentation, not yet booted.

A single-node kind cluster (Kubernetes 1.35) with the Starfleet workloads referenced by tag and an `uplink` Deployment that keeps a password in an environment variable.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-010/module-01/playground
astrona destroy ats-045-playground-010-01
```

Authors run the local copy with `astrona run -c .` inside this folder. `astrona destroy` takes the environment name, not the path.
