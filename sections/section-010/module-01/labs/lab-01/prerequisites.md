# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` and `jq`.
- You know the difference between an image tag and a digest, and how a Secret volume differs from an environment variable.

The lab starts a single-node kind cluster (Kubernetes 1.35). The commands for the lab are in the README of this folder.
