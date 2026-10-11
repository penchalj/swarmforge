#!/usr/bin/env bash
# Rewrites files to the project's formatting rules:
#   ./scripts/dev.sh ./scripts/format.sh
set -euo pipefail
cd "$(dirname "$0")/.."

list() {
  find . -path './bazel-*' -prune -o -path './.git' -prune -o -path './dist' -prune -o \
    -type f \( "$@" \) -print | sort
}

mapfile -t cc_files < <(list -name '*.h' -o -name '*.cc')
mapfile -t py_files < <(list -name '*.py')
mapfile -t bzl_files < <(list -name 'BUILD.bazel' -o -name '*.bzl' -o -name 'MODULE.bazel')

clang-format-18 -i "${cc_files[@]}"
ruff check --fix "${py_files[@]}"
ruff format "${py_files[@]}"
buildifier -lint=fix "${bzl_files[@]}"
echo "Formatted. Review the changes with: git diff"
