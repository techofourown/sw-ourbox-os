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

## Terminology
- `docs/00-Glossary/Terms-and-Definitions.md` is normative for vocabulary.

## 1 Introduction

### 1.1 Purpose
This document defines the high-level architecture of OurBox OS, including tenant-host routing, data boundaries, replication, and deployment constraints.

### 1.2 Scope
This AD defines architecture above the hardware seam and does not define target-specific BSP/image mechanics.

### 1.3 Architectural constraints (from ADRs)
- Shipped apps SHALL be browser-first and offline-capable.
- Tenant SHALL be the canonical top-level data boundary term.
- Full host SHALL carry tenant context; `tenant_id` SHALL be derived from the leftmost DNS label of the full host.
- Path SHALL identify app experience.
- Local-only mode SHALL be HTTP-only.
- Public custom-domain mode SHALL be HTTPS/TLS.
- Tenant origins SHALL be supported in both access modes.
- Full installable-PWA posture SHALL be tied to public custom-domain mode.

## 2 Architectural drivers

### 2.1 Key quality attributes
- Offline-capable local continuity
- Opportunistic sync
- Multi-tenant correctness
- Legibility in URLs/logs

### 2.2 Security posture (Operator Truth)
Tenant boundaries provide product correctness and legibility, not hostile-operator confidentiality.

## 3 System context (informative)

### 3.1 Actors
User, device operator, client browser, and OurBox instance.

### 3.2 Context diagram (informative)

+----------------------+ HTTP(S) +-------------------------------+
| Browser app         | <------> | Gateway (Ingress/Auth/Router)    |
| - tenant origin     |          | - route by full host             |
| - local replica     |          | - derive tenant_id from leftmost |
+----------+-----------+          |   DNS label of full host         |
           |                      +-----------+-----------------------+
           | replication (/db)                |
           v                                  v
+----------------------+            +--------------------------+
| CouchDB (internal)   |            | Platform Services        |
+----------------------+            +--------------------------+

## 4 Architectural model and invariants (normative)

### 4.1 Tenants are addressed as web origins
Supported tenant-origin patterns:
- local-only mode: `http://<tenant_id>.local/...`
- public custom-domain mode: `https://<tenant_id>.<box-host>/...`

Across both modes:
- full host carries tenant context,
- `tenant_id` is derived from the leftmost DNS label of the full host,
- path identifies app.

### 4.2 Apps are addressed as paths under a tenant origin
Supported app route patterns:
- `http://<tenant_id>.local/<app_slug>`
- `https://<tenant_id>.<box-host>/<app_slug>`

### 4.3 Tenant DBs are the replication unit
Each tenant has one tenant DB (`tenant_<tenant_id>`).

### 4.4 Local data is per tenant origin and shared across apps
Within one tenant origin, shipped apps share one local tenant replica (`tenant_local`).

`http://bob.local` and `https://bob.<box-host>` are different origins. They do not share IndexedDB, Cache Storage, service worker registration, or local tenant replica.

### 4.5 Gateway mediates tenant-scoped CouchDB access
Gateway exposes tenant-scoped replication through same-origin `/db` and does not expose raw CouchDB directly.

### 4.6 Replication endpoint shape (normative)
- local-only mode: `http://<tenant_id>.local/db`
- public custom-domain mode: `https://<tenant_id>.<box-host>/db`

## 5 Architecture views

### 5.1 Logical view (components and responsibilities)

#### 5.1.1 Gateway responsibilities
Gateway SHALL:
- serve HTTP in local-only mode,
- terminate TLS in public custom-domain mode,
- route by full host in both modes,
- derive `tenant_id` from the leftmost DNS label of the full host,
- optionally expose reserved local landing host `http://ourbox.local/` for non-tenant setup/admin entry.

#### 5.1.2 Static app hosting
- Public custom-domain mode: secure-context app delivery with service-worker-backed cached assets, installability, and reopen-offline after first successful load.
- Local-only mode: same-origin browser app over HTTP with local data continuity; equivalent full installable-PWA posture is not guaranteed.

### 5.2 Data view
- Local PouchDB name remains `tenant_local` within each origin.
- Origin separation provides isolation across modes.

### 5.3 Runtime/process view

#### 5.3.1 Local-only mode session
1. User opens `http://family.local/tasks`.
2. Gateway derives `tenant_id=family` from leftmost DNS label of full host.
3. App reads/writes local replica and syncs with `http://family.local/db` while box is reachable.
4. Browser may show insecure-transport UI; secure-context features are not assumed.

#### 5.3.2 Public custom-domain mode session
1. User opens `https://family.<box-host>/tasks`.
2. Gateway terminates TLS and derives `tenant_id=family`.
3. App uses service worker and local replica.
4. App syncs with `https://family.<box-host>/db`.

### 5.4 Deployment view (k3s mapping)

#### 5.4.2 Ingress and routing requirements (normative)
- Public custom-domain mode: wildcard host routing for `*.<box-host>`; TLS terminated at gateway.
- Local-only mode: HTTP routing for `<tenant_id>.local`; optional reserved `ourbox.local` landing host.
- Path routing supports `/<app_slug>`, `/db`, and `/api/...`.

## 6 Identity and access (normative)
Tenant context is authoritative from full host; untrusted client parameters do not override it.

## 10 Examples (informative)

### 10.1 App URLs
- `http://bob.local/simplenote`
- `https://bob.<box-host>/simplenote`

### 10.2 Replication endpoints
- `http://bob.local/db`
- `https://bob.<box-host>/db`
