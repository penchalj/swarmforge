#!/usr/bin/env bash
# Gives the images that were built, tested and signed for a commit a version
# tag (and the "dev" tag). Nothing is rebuilt: the digest stays identical.
# Writes release-manifest.json.
#   Env: REGISTRY, SHA (full commit), VERSION (e.g. v0.1.0), GITHUB_REPOSITORY
set -euo pipefail

short="${SHA::7}"
identity="https://github.com/${GITHUB_REPOSITORY}/.github/workflows/images.yml@refs/heads/main"
issuer="https://token.actions.githubusercontent.com"
images='[]'

for name in fusion-node detector; do
  base="${REGISTRY}/${name}"
  digest="$(crane digest "${base}:sha-${short}")"

  # Only images signed by main's Images workflow can become a release.
  cosign verify "${base}@${digest}" \
    --certificate-identity "$identity" --certificate-oidc-issuer "$issuer" >/dev/null

  crane tag "${base}@${digest}" "${VERSION}"
  crane tag "${base}@${digest}" dev

  if [ "$(crane digest "${base}:${VERSION}")" != "$digest" ]; then
    echo "::error::${name}:${VERSION} does not point to ${digest}" >&2
    exit 1
  fi

  images="$(jq -c --arg n "$name" --arg i "$base" --arg d "$digest" \
    '. + [{name: $n, image: $i, digest: $d}]' <<<"$images")"
  echo "${name}: ${VERSION} -> ${digest} (signature verified, also tagged dev)" |
    tee -a "${GITHUB_STEP_SUMMARY:-/dev/null}"
done

jq -n --arg v "$VERSION" --arg c "$SHA" --argjson images "$images" \
  '{version: $v, commit: $c, images: $images}' >release-manifest.json
cat release-manifest.json
