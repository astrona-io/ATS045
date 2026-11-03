---
estimated_duration: 25m
---

# Lab: Read The Cluster CA And Issue A Short-Lived Client Certificate

**UNTESTED: built from documentation, not yet booted.** Static checks only (`astrona validate`, `bash -n`, YAML parse).

Graded lab for the PKI module. Read the cluster CA from the node, issue a short-lived client certificate through the CertificateSigningRequest API and bind the user to read-only access. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-050/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-050/module-01/labs/lab-01
astrona destroy ats-045-lab-050-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-ca-evidence.sh` | pki-evidence holds the CA fingerprint and the API server expiry date read from the node |
| `validate-csr-issued.sh` | scout-auditor has an approved client certificate that lasts at most one day |
| `validate-auditor-least-privilege.sh` | scout-auditor can read pods in starfleet and nothing else |
| `validate-no-admin-shortcut.sh` | scout still runs and scout-auditor is not an admin |
