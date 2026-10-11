#!/usr/bin/env bash
# Runs the runtime images together with Docker Compose and checks the result.
# Uses DETECTOR_IMAGE and FUSION_IMAGE if set (defaults: local :dev images).
set -euo pipefail
cd "$(dirname "$0")/.."

compose=(docker compose -f tests/compose/compose.yaml -p swarmforge-test)
cleanup() { "${compose[@]}" down -v >/dev/null 2>&1 || true; }
trap cleanup EXIT

echo "== detector"
"${compose[@]}" run --rm -T detector

echo "== fusion-node"
output="$("${compose[@]}" run --rm -T --no-deps fusion-node)"
echo "$output"

rows="$(grep -c '^[0-9]' <<<"$output" || true)"
if [ "$rows" -ne 3 ]; then
  echo "FAIL: expected 3 tracks, got $rows" >&2
  exit 1
fi
echo "PASS: the runtime images work together (3 tracks)"
