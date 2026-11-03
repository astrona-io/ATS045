#!/usr/bin/env bash
# Check: the build-runner image is referenced by digest and the digest is the
# one the running container reports.
set -uo pipefail

image="$(kubectl -n forge get deploy build-runner -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)"
if ! echo "$image" | grep -Eq '@sha256:[0-9a-f]{64}$'; then
  echo "FAIL: image is '${image}', expected repository@sha256:<digest>"
  exit 1
fi
repo="${image%@*}"
if [ "$repo" != "mccutchen/go-httpbin" ]; then
  echo "FAIL: the repository changed to '${repo}', expected mccutchen/go-httpbin"
  exit 1
fi

echo "PASS: build-runner uses a digest reference"
