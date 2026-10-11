# ADR 0006: Automated releases and promotion by digest

## Context
Images for every main commit are built, tested, scanned and signed (ADR 0005).
Releases need version numbers and changelogs, must only use fully tested
commits, and must reach production through controlled steps.

## Decisions
1. **release-please** derives versions and the CHANGELOG from Conventional
   Commits and opens a release PR; merging it creates the tag and release.
2. **Release only green commits.** The release job waits until CI and Images
   both passed on the release commit.
3. **Build once.** A release adds the version tag to the images already built
   and signed for that commit (crane re-tags, the digest stays identical).
   SBOMs and a release manifest (digests) are attached to the GitHub Release.
4. **Promotion by digest:** dev (automatic on release) -> staging -> production.
   Before an environment tag moves: signature verified, version already in the
   previous environment, smoke test of the exact digests passes.
5. **Production needs a manual approval** (GitHub Environment reviewer).
6. **Rollback** is a promotion of an older version with the order check skipped;
   signature and smoke test still apply.
7. **Least-privilege release token:** fine-grained, one repository, contents /
   pull requests / issues only, 90-day expiry. Needed because PRs opened with
   GITHUB_TOKEN do not trigger the required checks.

## Consequences
+ Every release is traceable: version -> commit -> digests -> signature -> SBOM
+ No release can contain an untested or unsigned image
- Environments are registry tags plus GitHub deployment records for now; real
  targets (k3s, Ansible, edge device) consume these tags in Phase 2
