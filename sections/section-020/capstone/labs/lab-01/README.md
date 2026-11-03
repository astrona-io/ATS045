---
estimated_duration: 30m
---

# Lab: Rotate Registry Pull Credentials And Pin Digests

**UNTESTED: built from documentation, not yet booted.** Static checks only (`astrona validate`, `bash -n`, YAML parse).

Capstone for the image repository section. A revoked pull account must be replaced in two namespaces and the images pinned. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-020/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-020/capstone/labs/lab-01
astrona destroy ats-045-capstone-020
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-pull-secrets-rotated.sh` | Both namespaces hold the puller-v2 credential |
| `validate-old-credential-gone.sh` | No Secret holds the revoked puller account |
| `validate-images-pinned-to-registry-digest.sh` | scout and drifter use the digest of tag 6.15.0 |
| `validate-pull-policy-always.sh` | Both workloads use imagePullPolicy Always |
| `validate-workloads-running.sh` | scout and drifter are available |
| `validate-registry-still-private.sh` | The registry refuses unauthenticated calls |
