# ADR-0008: Deployment Baseline as the Platform Integration Contract

## Context
Platform wiring includes:
- local-only HTTP tenant-host routing for `<tenant_id>.local`,
- optional local landing host routing (`ourbox.local`),
- public HTTPS wildcard host routing for `*.<box-host>`,
- gateway path routing (`/<app_slug>`, `/db`, `/api/...`).

## Decision
Conformance/integration test suite SHALL verify:
- mode-aware host routing,
- local-only HTTP posture,
- public HTTPS posture,
- same-origin `/db` routing in both modes.

Implementation notes include access-mode route/conformance tests as baseline governance.
