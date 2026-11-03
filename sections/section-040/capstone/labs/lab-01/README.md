---
estimated_duration: 35m
---

# Lab: Secure Service-To-Service Traffic With Istio

**UNTESTED: built from documentation, not yet booted.** Static checks only (`astrona validate`, `bash -n`, YAML parse).

Capstone for the service mesh section. Require mutual TLS, open one port, authorize by identity and method, and record the certificate identities. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-040/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-040/capstone/labs/lab-01
astrona destroy ats-045-capstone-040
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-strict-mtls-required.sh` | starfleet refuses plain text and still serves mesh clients |
| `validate-metrics-port-only.sh` | Port 9797 of scout answers plain text and the application port does not |
| `validate-scout-allows-only-shuttle-get.sh` | Only GET from shuttle reaches the application port and metrics stay open |
| `validate-identity-evidence.sh` | mesh-identities holds the real identities of scout and probe |
| `validate-sidecars-present.sh` | Every running pod in starfleet has a sidecar |
| `validate-no-permissive-namespace-policy.sh` | The namespace-wide policy is STRICT |
