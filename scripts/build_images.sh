#!/usr/bin/env bash
# Builds the runtime images from the files staged by package.sh.
#   TAG=dev ./scripts/build_images.sh      (run on the host, not inside dev.sh)
set -euo pipefail
cd "$(dirname "$0")/.."

tag="${TAG:-dev}"
case "$(uname -m)" in
  x86_64) arch=amd64 ;;
  aarch64) arch=arm64 ;;
  *)
    echo "unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

context="dist/${arch}"
if [ ! -x "$context/fusion_node" ]; then
  echo "No staged files in $context. Run: ./scripts/dev.sh ./scripts/package.sh" >&2
  exit 1
fi

# The build context is only the staged folder: small, and nothing else leaks in.
docker build --load -f docker/fusion-node.Dockerfile -t "swarmforge/fusion-node:${tag}" "$context"
docker build --load -f docker/detector.Dockerfile -t "swarmforge/detector:${tag}" "$context"
docker images 'swarmforge/*'
