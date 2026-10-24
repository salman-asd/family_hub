# 0005 - Golden images are generated on Linux (decision D5)

**Status:** accepted (Phase 1 hardening, H1)

Goldens rendered on Windows differ from Linux by a pixel, so CI failed. Rule: goldens are produced
only by the `Update goldens` workflow on `ubuntu-latest` (same Flutter version as CI), downloaded
as an artifact and committed. All golden tests carry `@Tags(['golden'])`; the main CI job excludes
them (`--exclude-tags golden`) and a separate `goldens` job compares them exactly.
