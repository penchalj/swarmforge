#!/usr/bin/env bash
# Promotes a released version to an environment, by digest (never rebuilt).
#   Env: REGISTRY, VERSION (e.g. v0.1.0), TARGET (staging|production),
#        ROLLBACK ("true" skips the promotion-order check), GITHUB_REPOSITORY
# Checks before anything moves:
#   1. the images are signed by main's Images workflow
#   2. the version already runs in the previous environment (unless rollback)
#   3. a smoke test of the exact digests passes
set -euo pipefail
cd "$(dirname "$0")/.."

case "$TARGET" in
  staging) previous="dev" ;;
  production) previous="staging" ;;
  *)
    echo "unknown environment: $TARGET" >&2
    exit 1
    ;;
esac

identity="https://github.com/${GITHUB_REPOSITORY}/.github/workflows/images.yml@refs/heads/main"
issuer="https://token.actions.githubusercontent.com"
declare -A digests

for name in fusion-node detector; do
  base="${REGISTRY}/${name}"
  digest="$(crane digest "${base}:${VERSION}")"
  digests[$name]="$digest"

  cosign verify "${base}@${digest}" \
    --certificate-identity "$identity" --certificate-oidc-issuer "$issuer" >/dev/null
  echo "${name} ${VERSION}: ${digest} (signature verified)"

  if [ "${ROLLBACK:-false}" != "true" ]; then
    in_previous="$(crane digest "${base}:${previous}")"
    if [ "$in_previous" != "$digest" ]; then
      echo "::error::${name} ${VERSION} is not what ${previous} runs (${in_previous})." \
        "Promote in order: dev -> staging -> production." >&2
      exit 1
    fi
  fi
done

echo "== Smoke test of the exact digests"
DETECTOR_IMAGE="${REGISTRY}/detector@${digests[detector]}" \
  FUSION_IMAGE="${REGISTRY}/fusion-node@${digests[fusion-node]}" \
  ./scripts/compose_test.sh

for name in fusion-node detector; do
  base="${REGISTRY}/${name}"
  before="$(crane digest "${base}:${TARGET}" 2>/dev/null || echo "none")"
  crane tag "${base}@${digests[$name]}" "$TARGET"
  echo "${name}: ${TARGET} ${before} -> ${digests[$name]} (${VERSION})" |
    tee -a "${GITHUB_STEP_SUMMARY:-/dev/null}"
done
