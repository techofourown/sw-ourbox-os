# AD-0001: OurBox OS Architecture Description

## Status
Draft (normative unless explicitly marked "informative")

## Date
2026-01-25

## Related decisions
- ADR-0001: Purpose-build Offline-First PWAs for All Shipped OurBox Apps
- ADR-0002: Adopt CouchDB + PouchDB and Standardize OurBox Data Modeling (Tenant DBs + Partitions)
- ADR-0003: Standardize on Tenant as the OurBox OS Data Boundary Term
- ADR-0004: OurBox Document IDs
- ADR-0005: Store blobs in a content-addressed blob store keyed by a canonical multihash key (no chunking)
- ADR-0006: Deterministic sharded path layout for blob payloads
- ADR-0007: Run CouchDB as a k3s Workload (Not a Host Service)
- ADR-0008: Deployment Baseline as the Platform Integration Contract
- ADR-0011: Separate Hardware Enablement from the Platform Contract
- ADR-0014: Adopt Two Access Modes: Local HTTP `.local` and Public HTTPS Custom-Domain

## 1 Introduction

### 1.3 Architectural constraints (from ADRs)
- Local-only mode SHALL be HTTP-only.
- Public custom-domain mode SHALL be HTTPS/TLS.
- Tenant origins SHALL be supported in both modes.
- Full installable-PWA posture SHALL be tied to public custom-domain mode.
- Tenant SHALL be the canonical top-level data boundary term.

## 3 System context (informative)

### 3.2 Context diagram (informative)

+----------------------+ HTTP(S) +-------------------------------+
| Browser (Web App)    | <---------------> | Gateway (Ingress/Auth/Router) |
| - tenant origin      |                   | - tenant routing by full host |
| - local tenant       |                   | - membership enforcement       |
| replica (PouchDB)    |                   | - stable endpoints             |
+----------+-----------+                   +-----------+-------------------+
           |                                               |
           | replication via /db                           | internal
           v                                               v
+----------------------+                     +--------------------------+
| CouchDB              |                     | Platform Services        |
+----------------------+                     +--------------------------+

## 4 Architectural model and invariants (normative)

### 4.1 Tenants are addressed as web origins
Tenant origin patterns:
- local-only mode: `http://<tenant_id>.local/...`
- public custom-domain mode: `https://<tenant_id>.<box-host>/...`

Rule:
- the full host carries tenant context,
- `tenant_id` is derived from the leftmost DNS label of the full host,
- path identifies app.

### 4.2 Apps are addressed as paths under a tenant origin
App path patterns:
- local-only mode: `http://<tenant_id>.local/<app_slug>`
- public custom-domain mode: `https://<tenant_id>.<box-host>/<app_slug>`

Examples:
- `http://bob.local/simplenote`
- `https://bob.example.com/simplenote`

### 4.4 Local data is per tenant origin and shared across apps
Within one origin, apps share one local tenant replica (`tenant_local`) across app paths.

Origins differ across modes for the same tenant:
- `http://bob.local`
- `https://bob.<box-host>`

These are different origins and therefore do not share IndexedDB, Cache Storage, service worker registration, or local tenant replica.

### 4.5 Gateway mediates tenant-scoped CouchDB access
The gateway exposes same-origin replication endpoints in both modes:
- `http://<tenant_id>.local/db`
- `https://<tenant_id>.<box-host>/db`

Raw CouchDB node/admin interfaces are not exposed to tenant clients.

### 4.6 Replication endpoint shape (normative)
Replication SHALL use `/db` on the tenant origin in the active mode. Clients SHALL NOT select arbitrary CouchDB database names.

## 5 Architecture views

### 5.1.1 Gateway responsibilities
- serve HTTP tenant hosts in local-only mode,
- terminate TLS in public custom-domain mode,
- route by full host and path in both modes,
- derive `tenant_id` from the leftmost DNS label of the full host,
- support optional local landing host `ourbox.local` for non-tenant flows.

### 5.1.2 Static app hosting
- Public custom-domain mode: full installable-PWA posture, service-worker-backed assets, reopen-offline after first successful load.
- Local-only mode: same-origin browser app delivery over HTTP with local data continuity; equivalent full installable-PWA posture is not guaranteed.

### 5.3 Runtime/process view
#### 5.3.1 Local-only mode session flow
1. User opens `http://family.local/tasks`.
2. Gateway routes by full host and app path.
3. App reads/writes `tenant_local` in that HTTP origin.
4. App replicates with `http://family.local/db` while box is reachable.

#### 5.3.2 Public custom-domain mode session flow
1. User opens `https://family.<box-host>/tasks`.
2. Gateway terminates TLS and routes by full host and path.
3. App uses service-worker-backed asset caching in secure-context browser mode.
4. App replicates with `https://family.<box-host>/db` while box is reachable.

### 5.4.2 Ingress/routing requirements
- Local-only mode: HTTP routing for `<tenant_id>.local` and optional `ourbox.local`.
- Public custom-domain mode: wildcard routing for `*.<box-host>` with TLS terminated at gateway.
- Path routing in both modes: `/<app_slug>`, `/db`, `/api/...`.

## 10 Examples
- Local app URL: `http://alice.local/richnote`
- Public app URL: `https://alice.example.com/richnote`
- Local replication: `http://alice.local/db`
- Public replication: `https://alice.example.com/db`
