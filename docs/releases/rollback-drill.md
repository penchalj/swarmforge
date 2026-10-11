# Release and rollback drill (2026-10-11)

| Step | Action | Result |
|------|--------|--------|
| 1 | Release v0.1.0, promote dev -> staging -> production (approved) | All environments on sha256:8dff377a... |
| 2 | Release v0.1.1 (fix), lands in dev automatically | dev on sha256:a14e9f4c... |
| 3 | Promote v0.1.1 straight to production (approved) | **Blocked**: "not what staging runs" |
| 4 | Promote v0.1.1 to staging, then production (approved) | staging and production on v0.1.1 |
| 5 | Rollback: production to v0.1.0 (`rollback=true`, approved) | production back on sha256:8dff377a... in 46 s |

Every promotion verified the cosign signature and smoke-tested the exact
digests before moving the environment tag. Approvals are recorded per run.

Observation: v0.1.1 changed only `forge`, which is not in the images, yet the
image digests differ from v0.1.0 because Docker records the build time.
Reproducible image builds (SOURCE_DATE_EPOCH) are a planned improvement.
