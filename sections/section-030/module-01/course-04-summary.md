---
draft: true
exam_objectives:
  - Observability
---
# Summary

- **Audit policy.** The API server records requests by the first matching rule. Levels are `None`, `Metadata`, `Request` and `RequestResponse`. Secrets belong at `Metadata`, security-relevant changes can carry bodies, and the `RequestReceived` stage is usually omitted.
- **Enabling audit.** A policy needs the flags `--audit-policy-file` and `--audit-log-path`, plus host path volumes for both paths. The change restarts the API server static pod. A manifest backup outside the watched directory is the recovery path.
- **Reading events.** One JSON document per line. `user.username`, `verb`, `objectRef`, `responseStatus` and `auditID` answer who did what and with which result.
- **Retention.** Rotation flags decide how long the evidence exists. The log file is on the node, so access to the node can change it.
- **Evidence limits.** The audit log, runtime sensors, application logs and metrics each cover a different boundary. A quiet source can mean a failed pipeline. Detection is not prevention.
- **Collection.** Collectors move data and do not store it. Unbounded metric labels cause cardinality problems, and telemetry can hold sensitive values.

<!-- astrona:playground:destroy -->
