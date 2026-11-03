# Mesh Identity, mTLS And Certificates: Playground

- **Slug:** ats-045-playground-040-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground, clean environment, no task, no grading
- **Status:** UNTESTED: built from documentation, not yet booted.

Clean cluster with Istio 1.31.1 in sidecar mode, the Starfleet workloads in `starfleet` with sidecars and `drifter` in `outpost` without one. The mesh starts in PERMISSIVE mode.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-040/module-01/playground
astrona destroy ats-045-playground-040-01
```

Authors run the local copy with `astrona run -c .` inside this folder. `astrona destroy` takes the environment name, not the path.
