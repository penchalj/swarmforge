#!/usr/bin/env bash
# Waits until the given workflows have completed successfully for a commit.
#   GH_TOKEN=... ./scripts/wait_for_checks.sh <commit-sha> <workflow-file>...
# Fails if any of them fails, or after TIMEOUT_MIN minutes (default 90).
set -euo pipefail

sha="$1"
shift
deadline=$(($(date +%s) + ${TIMEOUT_MIN:-90} * 60))

for workflow in "$@"; do
  while :; do
    result="$(gh run list --workflow "$workflow" --commit "$sha" --event push \
      --json status,conclusion -q '.[0] | "\(.status) \(.conclusion)"')"
    case "$result" in
      "completed success")
        echo "$workflow: passed on $sha"
        break
        ;;
      completed*)
        echo "::error::$workflow did not pass on $sha ($result)"
        exit 1
        ;;
      *)
        if [ "$(date +%s)" -ge "$deadline" ]; then
          echo "::error::timed out waiting for $workflow on $sha"
          exit 1
        fi
        echo "$workflow: ${result:-not started yet}, waiting 30 s..."
        sleep 30
        ;;
    esac
  done
done
