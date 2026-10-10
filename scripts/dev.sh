#!/usr/bin/env bash
# Run any command inside the pinned SwarmForge build environment.
#
# Locally the Bazel cache lives in a Docker volume. In CI, set BAZEL_CACHE_DIR
# to a host folder so the workflow can save and restore it between runs.
# Set SKIP_IMAGE_BUILD=1 when the image was already built (e.g. by CI).
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -z "${SKIP_IMAGE_BUILD:-}" ]; then
  docker build -q -t swarmforge-dev -f docker/dev.Dockerfile . >/dev/null
fi

# Always keep stdin open (for piped input); add a terminal only when there is one.
flags=(-i)
if [ -t 0 ] && [ -t 1 ]; then
  flags+=(-t)
fi

cache_mount="swarmforge-bazel-cache:/home/ubuntu/.cache"
if [ -n "${BAZEL_CACHE_DIR:-}" ]; then
  mkdir -p "$BAZEL_CACHE_DIR"
  cache_mount="$BAZEL_CACHE_DIR:/home/ubuntu/.cache"
fi

# Run as the calling user, so files written into the repo keep the right owner.
exec docker run --rm "${flags[@]}" \
  --user "$(id -u):$(id -g)" -e HOME=/home/ubuntu -e USER=builder \
  -v "$PWD":/workspace \
  -v "$cache_mount" \
  swarmforge-dev "$@"
