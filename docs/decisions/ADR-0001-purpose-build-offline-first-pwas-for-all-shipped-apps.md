# ADR-0001: Purpose-build Offline‑First PWAs for All Shipped OurBox Apps

## Date
2026-01-25

## Context
OurBox is browser-first and tenant-origin-centered in two access modes:
- local-only mode: `http://<tenant_id>.local/<app_slug>`
- public custom-domain mode: `https://<tenant_id>.<box-host>/<app_slug>`

Tenant origin rule:
- full host carries tenant context,
- `tenant_id` is the leftmost DNS label of the full host,
- path identifies app.

For the same tenant on the same browser, `http://<tenant_id>.local` and `https://<tenant_id>.<box-host>` are different origins and therefore different local tenant replicas.

References:
- ADR-0014
- RFC-0002
- ADR-0002
- ADR-0003

## Decision
Shipped first-party apps SHALL remain offline-capable, browser-first, and PouchDB-backed with opportunistic sync.

Mode-scoped posture:
1. Public custom-domain mode SHALL provide full installable-PWA posture, including service-worker-backed app caching and reopen-offline after first successful load.
2. Local-only mode SHALL be HTTP-only local web access with local data continuity and opportunistic sync while reachable; equivalent installability/reopen-offline behavior is not guaranteed.
3. Apps SHALL operate within tenant origins in both supported patterns:
   - `http://<tenant_id>.local/...`
   - `https://<tenant_id>.<box-host>/...`
4. Apps SHALL sync through same-origin tenant endpoints (`/db`) in the active mode.
5. Local-only mode does not provide TLS transport authentication, confidentiality, or integrity and may display insecure-transport browser UI.

## Consequences
- Browser-first and offline-capable product posture is preserved across both modes.
- Public mode carries full PWA expectations.
- Local-only mode is intentional HTTP local access with narrower guarantees.

## Mitigations
- Requirements and app specs SHALL scope installability/offline claims by mode.
- Docs SHALL treat local-only and public mode origins as separate browser storage/security boundaries.
