#!/usr/bin/env bash
# Reads changed file paths (one per line) on stdin and prints the Bazel test
# targets that depend on them.
#   prints "//..."   when a change can affect everything
#   prints nothing   when no Bazel target is affected (e.g. docs only)
set -euo pipefail
cd "$(dirname "$0")/.."

mapfile -t files < <(grep -v '^[[:space:]]*$' || true)
if [ "${#files[@]}" -eq 0 ]; then
  exit 0
fi

labels=()
for f in "${files[@]}"; do
  case "$f" in
    MODULE.bazel | MODULE.bazel.lock | .bazelrc | .bazelversion | docker/* | scripts/* | .github/*)
      echo "//..."
      exit 0
      ;;
  esac
  if [ ! -e "$f" ]; then # deleted or renamed: be safe
    echo "//..."
    exit 0
  fi
  case "$(basename "$f")" in
    BUILD | BUILD.bazel)
      dir="$(dirname "$f")"
      if [ "$dir" = "." ]; then labels+=("//:all"); else labels+=("//$dir:all"); fi
      ;;
    *)
      # A file that is not part of any Bazel target (e.g. docs) is skipped.
      if label=$(bazel query --config=ci "$f" 2>/dev/null); then
        labels+=("$label")
      fi
      ;;
  esac
done

if [ "${#labels[@]}" -eq 0 ]; then
  exit 0
fi

bazel query --config=ci --keep_going \
  "kind('.*_test rule', rdeps(//..., set(${labels[*]})))" 2>/dev/null || true
