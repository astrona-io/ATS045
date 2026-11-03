---
estimated_duration: 35m
---

# Lab: Replace A Leaked Client Certificate

**UNTESTED: built from documentation, not yet booted.** Static checks only (`astrona validate`, `bash -n`, YAML parse).

Capstone for the PKI section. Remove the access of a leaked client certificate through every binding, issue a short-lived replacement and record the evidence from the cluster certificates. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-050/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS045.git -c sections/section-050/capstone/labs/lab-01
astrona destroy ats-045-capstone-050
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-old-access-removed.sh` | The leaked certificate has no access through any user or group binding |
| `validate-replacement-csr-short-lived.sh` | fleet-intern-2 has an approved client certificate that lasts at most two hours |
| `validate-replacement-least-privilege.sh` | fleet-intern-2 can read pods in starfleet and nothing else |
| `validate-pki-evidence.sh` | pki-evidence holds the CA fingerprint, the API server expiry and the chain result |
| `validate-fleet-intact.sh` | scout still runs, the auditors binding stays and no admin shortcut was added |
