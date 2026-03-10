# ADR-0001: Purpose-build Offline-First PWAs for All Shipped OurBox Apps

## Date
2026-01-25

## Context
OurBox is browser-first and tenant-oriented. ADR-0014 defines two permanent access modes and RFC-0002 defines behavioral differences.

### Critical architectural constraint: shared tenant origin + shared local replica
Tenant-origin patterns:
- local-only mode: `http://<tenant_id>.local/<app_slug>`
- public custom-domain mode: `https://<tenant_id>.<box-host>/<app_slug>`

In both modes, full host carries tenant context, `tenant_id` is from the leftmost DNS label of the full host, and path identifies app.

Within one tenant origin, shipped apps share one local tenant replica (`tenant_local`).

`http://bob.local` and `https://bob.<box-host>` are different origins and therefore different local tenant replicas.

## Decision
Shipped apps SHALL be browser-first, offline-capable apps using local persistence (PouchDB) and opportunistic sync.

Mode promises:
1. Public custom-domain mode (`https://<tenant_id>.<box-host>/...`) is the canonical full installable-PWA mode with service-worker-backed asset caching and reopen-offline after first successful load.
2. Local-only mode (`http://<tenant_id>.local/...`) is HTTP-only local web mode with local data continuity and opportunistic sync while reachable, without guaranteed equivalent installability or reopen-offline behavior.
3. Local-only mode is HTTP-only and does not provide TLS transport authentication, confidentiality, or integrity; browser insecure-transport UI may appear.
4. Apps operate within tenant origins in both modes.

## Consequences
### Positive
- Browser-first posture remains consistent.
- Mode-specific guarantees are explicit and testable.

### Negative
- Same tenant across modes is origin-split, so browser-local replica continuity does not transparently span modes.

### Mitigation
- Product documentation and onboarding explicitly distinguish local continuity from full installable-PWA behavior.

## References
- ADR-0014
- RFC-0002
