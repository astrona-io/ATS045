# Record API Activity With Audit Logging: Playground

- **Slug:** ats-045-playground-030-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground, clean environment, no task, no grading
- **Status:** UNTESTED: built from documentation, not yet booted.

Clean cluster with the Starfleet workloads and the `deck-cleaner` CronJob. API server audit logging starts disabled so you can enable it and read events.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-030/module-01/playground
astrona destroy ats-045-playground-030-01
```

Authors run the local copy with `astrona run -c .` inside this folder. `astrona destroy` takes the environment name, not the path.
