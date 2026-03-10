# ADR-0008: Deployment Baseline as the Platform Integration Contract

## Date
2026-01-25

## Context
The deployment baseline includes platform wiring for both access modes:
- local-only HTTP tenant-host routing for `<tenant_id>.local`,
- optional local landing host routing for `ourbox.local`,
- public HTTPS wildcard host routing for `*.<box-host>`,
- gateway path routing for `/<app_slug>`, `/db`, `/api/...`.

## Decision
Conformance/integration tests SHALL verify:
- mode-aware host routing,
- local-only HTTP posture,
- public HTTPS posture,
- same-origin `/db` routing in both modes.

Implementation notes include access-mode route/conformance tests as baseline governance.
