# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` and `jq`.
- You completed the module lab or know pull Secrets, ServiceAccounts and imagePullPolicy.
- Outbound internet is available so the registry can be seeded.

The lab starts a single-node kind cluster (Kubernetes 1.35). The commands for the lab are in the README of this folder.
