#!/usr/bin/env bash
# Run any command inside the pinned SwarmForge build environment.
set -euo pipefail
cd "$(dirname "$0")/.."
docker build -q -t swarmforge-dev -f docker/dev.Dockerfile . >/dev/null
exec docker run --rm -it \
  -v "$PWD":/workspace \
  -v swarmforge-bazel-cache:/home/ubuntu/.cache \
  swarmforge-dev "$@"
