# Secure Access To A Private Image Repository: Playground

- **Slug:** ats-045-playground-020-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground, clean environment, no task, no grading
- **Status:** UNTESTED: built from documentation, not yet booted.

A single-node kind cluster with a private, password-protected registry and two workloads that cannot pull from it until a pull Secret is added.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-020/module-01/playground
astrona destroy ats-045-playground-020-01
```

Authors run the local copy with `astrona run -c .` inside this folder. `astrona destroy` takes the environment name, not the path.
