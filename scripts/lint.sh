#!/usr/bin/env bash
# Format and lint checks (no changes). Run inside the build image:
#   ./scripts/dev.sh ./scripts/lint.sh
set -euo pipefail
cd "$(dirname "$0")/.."

list() {
  find . -path './bazel-*' -prune -o -path './.git' -prune -o -path './dist' -prune -o \
    -type f \( "$@" \) -print | sort
}

mapfile -t cc_files < <(list -name '*.h' -o -name '*.cc')
mapfile -t py_files < <(list -name '*.py')
mapfile -t sh_files < <(list -name '*.sh')
mapfile -t bzl_files < <(list -name 'BUILD.bazel' -o -name '*.bzl' -o -name 'MODULE.bazel')

status=0
echo "== clang-format (${#cc_files[@]} files)"
clang-format-18 --dry-run --Werror "${cc_files[@]}" || status=1
echo "== ruff (${#py_files[@]} files)"
ruff check "${py_files[@]}" || status=1
ruff format --check "${py_files[@]}" || status=1
echo "== shellcheck (${#sh_files[@]} files)"
shellcheck "${sh_files[@]}" || status=1
echo "== buildifier (${#bzl_files[@]} files)"
buildifier -mode=check -lint=warn "${bzl_files[@]}" || status=1

if [ "$status" -ne 0 ]; then
  echo "Lint failed. Fix formatting automatically with: ./scripts/dev.sh ./scripts/format.sh"
fi
exit "$status"
