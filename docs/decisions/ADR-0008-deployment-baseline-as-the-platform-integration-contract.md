# ADR-0008: Deployment Baseline as the Platform Integration Contract

## Date
2026-01-25

## Context
Platform baseline includes mode-aware routing seams:
- local-only HTTP tenant-host routing for `<tenant_id>.local`
- optional reserved local landing host routing for `ourbox.local`
- public HTTPS wildcard routing for `*.<box-host>`
- gateway path routing for `/<app_slug>`, `/db`, `/api/...`

## Decision
Conformance/integration tests SHALL verify:
- mode-aware host routing,
- local-only HTTP posture,
- public HTTPS posture,
- same-origin `/db` routing in both modes.

## Implementation Notes
Baseline governance includes access-mode route and conformance tests.

## References
- ADR-0014
