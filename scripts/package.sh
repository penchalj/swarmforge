#!/usr/bin/env bash
# Builds the release binaries with Bazel and stages them for the runtime images.
#   ./scripts/dev.sh ./scripts/package.sh [extra bazel flags]
set -euo pipefail
cd "$(dirname "$0")/.."

case "$(uname -m)" in
  x86_64) arch=amd64 ;;
  aarch64) arch=arm64 ;;
  *)
    echo "unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

bazel build --config=release "$@" //fusion-node:fusion_node //proto:detection_py_pb2

out="dist/${arch}"
rm -rf "$out"
mkdir -p "$out/app/proto" "$out/app/detector"

cp -L bazel-bin/fusion-node/fusion_node "$out/"
pb2="$(find -L bazel-bin/proto -name detection_pb2.py | head -1)"
if [ -z "$pb2" ]; then
  echo "detection_pb2.py not found under bazel-bin/proto" >&2
  exit 1
fi
cp -L "$pb2" "$out/app/proto/"
cp detector/sim_detector.py "$out/app/detector/"

echo "Staged release files in $out:"
find "$out" -type f | sort
