# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` and `jq`.
- You know Deployments, Services and ServiceAccounts.
- Outbound internet is available so `istioctl` can be downloaded.

The lab starts a single-node kind cluster (Kubernetes 1.35). The commands for the lab are in the README of this folder.
