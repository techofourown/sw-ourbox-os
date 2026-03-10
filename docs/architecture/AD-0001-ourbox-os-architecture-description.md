# AD-0001: OurBox OS Architecture Description

## Related decisions
ADR-0001, ADR-0002, ADR-0003, ADR-0007, ADR-0008, ADR-0011, ADR-0014.

## 1 Introduction

### 1.3 Architectural constraints (from ADRs)
- OurBox supports two first-class tenant access modes.
- Local-only mode is HTTP-only: `http://<tenant_id>.local/...`.
- Public custom-domain mode is HTTPS/TLS: `https://<tenant_id>.<box-host>/...`.
- Tenant origins are supported in both modes.
- Full installable-PWA posture is tied to public custom-domain mode.

## 3 System context (informative)

### 3.2 Context diagram (informative)
Browser ↔ Gateway is `HTTP(S)` depending on mode.

- Local-only mode: Browser —HTTP→ Gateway (`<tenant_id>.local`, optional `ourbox.local`).
- Public custom-domain mode: Browser —HTTPS→ Gateway (`<tenant_id>.<box-host>`).

## 4 Architectural model and invariants (normative)

### 4.1 Tenants are addressed as web origins
Supported tenant-origin patterns:
- `http://<tenant_id>.local/...`
- `https://<tenant_id>.<box-host>/...`

Rules:
- full host carries tenant context,
- gateway derives `tenant_id` from the leftmost DNS label of the full host,
- path identifies the app.

### 4.2 Apps are addressed as paths under a tenant origin
Supported app-route patterns:
- local-only mode: `http://<tenant_id>.local/<app_slug>`
- public custom-domain mode: `https://<tenant_id>.<box-host>/<app_slug>`

Examples:
- `http://bob.local/simplenote`
- `https://bob.example.com/simplenote`

### 4.4 Local data is per tenant origin and shared across apps
Within one tenant origin, apps share one local tenant replica.

Origins are mode-specific. `http://bob.local` and `https://bob.<box-host>` are different origins, so they use different IndexedDB/Cache Storage/service worker registrations and different local tenant replicas.

### 4.5 Gateway mediates tenant-scoped CouchDB access
Gateway is the tenant-facing surface in both modes.

- local-only mode: `http://<tenant_id>.local/db`
- public custom-domain mode: `https://<tenant_id>.<box-host>/db`

Raw CouchDB endpoints are not exposed as tenant-facing interfaces.

### 4.6 Replication endpoint shape (normative)
Same-origin replication endpoint:
- local-only mode: `http://<tenant_id>.local/db`
- public custom-domain mode: `https://<tenant_id>.<box-host>/db`

`/db` on the tenant origin maps to CouchDB `tenant_<tenant_id>` through the gateway.

## 5 Architecture views

### 5.1 Logical view

#### 5.1.1 Gateway responsibilities
Gateway SHALL:
- serve HTTP in local-only mode,
- terminate TLS in public custom-domain mode,
- route by full host and path in both modes,
- derive `tenant_id` from the leftmost DNS label of the full host,
- optionally expose `ourbox.local` for local landing/setup flows.

#### 5.1.2 Static app hosting
- Public custom-domain mode: installable PWA posture, service-worker-backed cached assets, reopen-offline after first successful load.
- Local-only mode: same-origin browser app over HTTP with local data continuity; no guarantee of equivalent full installable-PWA posture.

### 5.3 Runtime/process view
- Local-only flow: open `http://<tenant_id>.local/<app_slug>`, use local replica, opportunistically sync to `http://<tenant_id>.local/db` while box is reachable.
- Public flow: open `https://<tenant_id>.<box-host>/<app_slug>`, service worker can support reopen-offline after first successful load, opportunistically sync to `https://<tenant_id>.<box-host>/db`.

### 5.4.2 Ingress and routing requirements
- Local-only mode: HTTP routing for `<tenant_id>.local`; optional `ourbox.local` landing host.
- Public custom-domain mode: wildcard host routing for `*.<box-host>` with TLS terminated at gateway.
- Path routing: `/<app_slug>`, `/db`, `/api/...`.

## 10 Examples

### 10.1 App URLs
- `http://family.local/simplenote`
- `https://family.example.com/simplenote`

### 10.2 Replication endpoints
- `http://family.local/db`
- `https://family.example.com/db`
