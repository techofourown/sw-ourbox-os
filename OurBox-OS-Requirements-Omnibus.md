# OurBox OS Requirements Omnibus


## Included Specifications
- SyRS-0001-ourbox-os-system-requirements-specification.md (source: spec:SyRS-0001)
- SRS-0201-gateway-software-requirements-specification.md (source: spec:SRS-0201)
- SRS-0202-couchdb-service-software-requirements-specification.md (source: spec:SRS-0202)
- SRS-0203-k3s-platform-contract-software-requirements-specification.md (source: spec:SRS-0203)
- SRS-0204-local-tenant-replica-software-requirements-specification.md (source: spec:SRS-0204)
- SRS-0205-tenant-blob-store-software-requirements-specification.md (source: spec:SRS-0205)
- SRS-0206-identity-and-tenant-membership-software-requirements-specification.md (source: spec:SRS-0206)
- SRS-1001-simplenote-software-requirements-specification.md (source: spec:SRS-1001)
- SRS-1002-richnote-software-requirements-specification.md (source: spec:SRS-1002)
- SRS-1003-messager-software-requirements-specification.md (source: spec:SRS-1003)
- SRS-1004-scout-software-requirements-specification.md (source: spec:SRS-1004)
- SRS-1005-compass-software-requirements-specification.md (source: spec:SRS-1005)
- SRS-1006-spar-software-requirements-specification.md (source: spec:SRS-1006)

---

# Terms and Definitions

## Purpose
This document defines canonical terms and acronyms used across OurBox OS requirements, architecture, design, and verification artifacts.

This glossary is the vocabulary authority for host-routing terms, access modes, and requirement language.

## OurBox OS product and architecture terms (normative)

### full host
The entire host portion of a URL before any port and before the path.

### box-host
In public custom-domain mode, the public custom-domain base host suffix after the tenant label.

Pattern: `<tenant_id>.<box-host>`

### tenant host
The full host used to address a tenant.

Supported patterns:
- local-only mode: `<tenant_id>.local`
- public custom-domain mode: `<tenant_id>.<box-host>`

### local landing host
A reserved non-tenant local host used for setup/admin entry flows.

Recommended pattern: `ourbox.local`

### Local-only mode
HTTP-only tenant-host mode for joined-LAN access.

Patterns:
- `http://<tenant_id>.local/<app_slug>`
- `http://<tenant_id>.local/db`
- optional `http://ourbox.local/`

Implications:
- no TLS transport authentication,
- no TLS transport confidentiality/integrity,
- browser insecure-transport UI may appear,
- secure-context browser features are not automatically available.

### Public custom-domain mode
HTTPS/TLS mode for public custom-domain tenant-host access.

Patterns:
- `https://<tenant_id>.<box-host>/<app_slug>`
- `https://<tenant_id>.<box-host>/db`

### tenant_id
Stable identifier for a tenant.

Constraints:
- SHALL be lowercase.
- SHALL be safe for use in DNS labels.
- SHALL be safe for use as the leftmost DNS label of a tenant host.
- SHALL be safe for use in CouchDB database names.

### Tenant origin
A tenant-scoped browser origin.

Supported patterns by mode:
- local-only mode: `http://<tenant_id>.local/...`
- public custom-domain mode: `https://<tenant_id>.<box-host>/...`

Across both modes:
- the full host carries tenant context,
- `tenant_id` is derived from the leftmost DNS label of the full host,
- the path identifies app context.

`http://bob.local` and `https://bob.example.com` are different origins and therefore do not share IndexedDB, Cache Storage, service workers, or local tenant replicas.

### Gateway
Tenant-facing HTTP service surface that routes by full host and path.

- local-only mode: serves HTTP tenant hosts and optional local landing host.
- public custom-domain mode: terminates TLS and serves HTTPS tenant hosts.
- exposes same-origin replication at `/db` in both modes.

### Progressive Web App (PWA)
Shipped apps are PWA-capable. Full installable-PWA posture (secure context, service-worker-backed reopen-offline) is tied to public custom-domain mode. Local-only mode is HTTP-only and does not guarantee equivalent behavior.

---

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

---

# SyRS-0001: OurBox OS System Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-01-27
**Status:** Draft

This specification is an early, intentionally small set of normative requirements derived from:
- architecture docs ([[arch_doc:AD-0001]])
- decisions ([[adr:ADR-0001]]..[[adr:ADR-0006]])

It is compiled from GraphMD records into `SyRS-0001-ourbox-os-system-requirements-specification.md`.

## Normative Language

The key words **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, and **MAY** are to be interpreted as
requirements. When a requirement references a record, that record is part of the normative context.

## Application Requirements

These requirements describe the baseline posture for shipped OurBox applications operating within a
single tenant origin, including offline-first behavior and doc-kind handling.

### APP-001: Public custom-domain mode SHALL provide full installable-PWA posture

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Installability and reopen-offline guarantees depend on HTTPS secure-context behavior.

In public custom-domain mode, shipped OurBox apps SHALL support full installable-PWA behavior,
including service-worker-backed reopen-offline operation after first successful load.

### APP-002: Shipped apps SHALL persist working data locally

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Offline writes depend on local persistence.

Shipped apps SHALL store working data locally in the tenant origin using PouchDB-backed IndexedDB.

### APP-003: Shipped apps SHALL sync opportunistically

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Supports sporadic connectivity while keeping data consistent.

Shipped apps SHALL initiate incremental replication with the tenant DB when connectivity is available.

### APP-004: Shipped apps SHALL use mode-aware tenant-origin route patterns

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Tenant routing is mode-aware and path identifies app in both modes.

Shipped apps SHALL be served at tenant origins using supported mode patterns: local-only mode
`http://<tenant_id>.local/<app_slug>` and public custom-domain mode
`https://<tenant_id>.<box-host>/<app_slug>`, where `tenant_id` is derived from the leftmost DNS
label of the full host.

### APP-005: Apps SHALL share one local tenant replica per origin

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Ensures apps share doc kinds offline.

All shipped apps under the same tenant origin SHALL read and write through a single local tenant
replica database on that device.

### APP-006: Apps SHALL honor doc-kind contracts

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Shared storage requires strict doc-kind boundaries.

Shipped apps SHALL only create and update documents whose `_id` prefixes match the stable doc-kind
vocabulary defined for OurBox OS.

### APP-007: Local-only mode SHALL be documented with HTTP-only local continuity posture

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Local HTTP mode has different guarantees than public HTTPS mode.

Documentation and requirements for local-only mode SHALL state that it is HTTP-only and SHALL NOT
claim guaranteed full installable-PWA/reopen-offline behavior equivalent to public custom-domain
mode.

## Data and Replication

These requirements capture the canonical data modeling and replication posture for tenant databases
and local replicas.

### DATA-001: Each tenant SHALL have exactly one tenant DB

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Tenant DBs are the replication unit for data modeling and replication.

OurBox SHALL maintain one CouchDB database per tenant, named using the `tenant_<tenant_id>` pattern.

### DATA-002: Tenant DBs SHALL be partitioned databases

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Partitioning enforces doc-kind boundaries.

All tenant databases SHALL be created as CouchDB partitioned databases.

### DATA-003: Document IDs SHALL use the doc_kind:uuidv4 scheme

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Canonical IDs ensure consistent replication and conflict boundaries.

Application documents SHALL have `_id` values shaped as `<doc_kind>:<uuidv4>`.

### DATA-004: Doc kind SHALL be derived from _id only

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Avoids divergent sources of truth for document classification.

Applications and services SHALL derive `doc_kind` from the `_id` prefix and SHALL NOT store a separate
doc-type field as the authoritative source.

### DATA-005: Tenant replication SHALL be whole-DB

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Replication posture is tenant DB ↔ tenant DB.

Replication between client devices and the box SHALL use the tenant DB as the unit of replication and
SHALL NOT require selective partition replication.

### DATA-006: Blobs SHALL be stored outside CouchDB by default

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Large binary content should not be default CouchDB attachments; tenant-scoped blob stores enable legible tenant operations.

Large binary assets (photos/video/audio) SHALL be stored outside CouchDB by default in the tenant blob store (one blob store per tenant), with references stored in application documents.

### DATA-007: Each tenant SHALL have exactly one tenant blob store

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Tenant-scoped blob stores keep blob payload bytes legible for tenant operations and align with ADR-0006 storage roots.

OurBox SHALL maintain one tenant blob store per tenant for blob payload bytes stored outside CouchDB.

Each tenant blob store SHALL use a tenant-scoped storage root (ADR-0006).

### DATA-008: Local tenant replicas SHALL remain origin-separated across access modes

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Browser origin boundaries isolate local replicas across scheme/host differences.

The same tenant accessed as `http://<tenant_id>.local` and `https://<tenant_id>.<box-host>` SHALL
be treated as different browser origins and therefore SHALL use different local tenant replicas.

## Gateway and Identity

These requirements define tenant routing, identity enforcement, and the gateway surface used by
clients and shipped apps.

### GW-001: Gateway SHALL derive tenant context from full host

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Tenant origins are the canonical boundary in both access modes.

The gateway SHALL derive `tenant_id` from the leftmost DNS label of the request full host and
shall treat that value as authoritative tenant context.

### GW-002: Gateway SHALL enforce tenant membership

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Ensures user access is scoped to the tenant origin.

The gateway SHALL enforce that authenticated users are members of the tenant implied by the hostname
before allowing access to tenant-scoped services.

### ID-002: `tenant_id` SHALL be DNS-label safe

**Status:** Draft  
**Testable:** true  
**Area:** identity  
**Rationale:** `tenant_id` is derived from the leftmost DNS label of tenant hosts.

`tenant_id` SHALL be safe for use in DNS labels, including use as the leftmost DNS label of a
tenant host.

### GW-003: Replication endpoints SHALL be same-origin in both access modes

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Browser clients must replicate without CORS or topology leakage.

The gateway SHALL expose replication at `/db` on the tenant origin in both modes:
`http://<tenant_id>.local/db` and `https://<tenant_id>.<box-host>/db`, and SHALL NOT require
clients to know internal CouchDB endpoints.

### GW-005: Gateway SHALL terminate TLS for public custom-domain tenant hosts

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** TLS is required for public custom-domain mode and not for local-only mode.

For public custom-domain mode, TLS SHALL be terminated at the gateway for tenant hosts matching
`*.<box-host>`.

### GW-007: Gateway SHALL map `/db` on tenant origins to tenant DBs

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Same-origin replication requires stable tenant-origin mapping.

The gateway SHALL map `/db` on tenant origins to CouchDB database `tenant_<tenant_id>` in both
modes:
- `http://<tenant_id>.local/db`
- `https://<tenant_id>.<box-host>/db`

### GW-010: Local-only mode SHALL be HTTP-only

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Access-mode transport posture is an explicit platform contract.

In local-only mode, gateway tenant-host interfaces SHALL be HTTP-only and SHALL NOT require or
assume TLS.

## Kubernetes and Deployment

These requirements describe the k3s/Kubernetes posture for deploying OurBox OS services and shipped
apps while preserving tenant boundaries.

### K8S-001: Kubernetes namespaces SHALL NOT encode tenant boundaries

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** Tenant is a data boundary, not an operational namespace.

Kubernetes namespaces SHALL be used for operational grouping and SHALL NOT be treated as the primary
tenant isolation boundary.

### K8S-002: Public custom-domain ingress SHALL support wildcard tenant hosts

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** Public tenant hosts require wildcard host routing.

For public custom-domain mode, ingress configuration SHALL support wildcard host routing for
`*.<box-host>`.

### K8S-003: Shipped app workloads SHOULD use dedicated namespaces

**Status:** Draft  
**Testable:** false  
**Area:** k8s  
**Rationale:** Separates app operations while keeping tenant boundaries intact.

Shipped app workload bundles SHOULD run in their own Kubernetes namespaces to simplify operations
and isolation from platform services.

### K8S-010: Local-only ingress SHALL route HTTP tenant hosts

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** Local-only mode requires tenant-host routing without TLS assumptions.

For local-only mode, platform ingress SHALL route HTTP requests for tenant hosts matching
`<tenant_id>.local` and MAY expose reserved local landing host `ourbox.local`.

---

# SRS-0201: Gateway Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-01-31
**Status:** Draft

This specification defines the software requirements for the Gateway software item. It is a minimal scaffold; detailed requirements live in section records and the authoritative Glossary.

## Normative Language

Normative keywords (SHALL, SHALL NOT, SHOULD, SHOULD NOT, MAY) and OurBox OS product/architecture vocabulary are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

## Introduction

This SRS defines the requirements for the **Gateway** software item.

The Gateway is the **front door for HTTP(S) traffic** to an OurBox instance. It is responsible for tenant-scoped routing and policy enforcement, including exposing a stable same-origin replication surface for CouchDB while also routing app and API traffic under tenant origins.

This SRS intentionally remains a minimal scaffold, but it includes the Gateway requirements already established in:
- `[[spec:SyRS-0001]]` (system requirements allocated to the Gateway), and
- `[[arch_doc:AD-0001]]` (normative architecture invariants and routing posture).

## Referenced Documents

- `docs/00-Glossary/Terms-and-Definitions.md`
- [[spec:SyRS-0001]]
- [[arch_doc:AD-0001]]
- [[adr:ADR-0001]]
- [[adr:ADR-0002]]
- [[adr:ADR-0003]]
- [[adr:ADR-0004]]
- [[spec:SRS-0206]]

## Requirements

Gateway requirements are mode-aware:
- TLS requirements apply to public custom-domain mode.
- Local-only tenant-host access is HTTP-only.
- Host routing covers `<tenant_id>.local` and `*.<box-host>`.
- Same-origin `/db` mapping is provided in both modes.

### GW-006: Gateway path routing SHALL support app, replication, and API paths under the tenant origin

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Stable path routing is required for tenant-origin composition.

Path routing SHALL support:
- `/<app_slug>` for app assets
- `/db` for the replication endpoint
- `/api/...` for service APIs (when present)

**Trace:** [[arch_doc:AD-0001]] §5.4.2

### GW-008: CouchDB SHALL be exposed externally only through the tenant origin as a tenant-scoped surface

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Reduce exposed surface area while preserving CouchDB replication posture.

CouchDB is exposed externally only through the tenant origin as a tenant-scoped surface (same-origin), not as a raw CouchDB node endpoint.

**Trace:** [[arch_doc:AD-0001]] §4.5

### GW-009: Gateway SHALL treat hostname-derived tenant context as authoritative

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Prevent tenant confusion and parameter spoofing when hostname is present.

When hostname is present, `tenant_id` SHALL be derived from the request hostname and SHALL NOT be accepted from untrusted client parameters as the primary authority.

**Trace:** [[arch_doc:AD-0001]] §6.2

## External Interfaces

Gateway tenant-facing interfaces:
- local-only app route pattern: `http://<tenant_id>.local/<app_slug>`
- public app route pattern: `https://<tenant_id>.<box-host>/<app_slug>`
- local-only replication endpoint: `http://<tenant_id>.local/db`
- public replication endpoint: `https://<tenant_id>.<box-host>/db`
- replication path: `/db`

## Verification

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture for this SRS:
- **Inspection:** confirm Gateway configuration supports wildcard hosts and path routing shapes (K8S-002, GW-005, GW-006).
- **Test:** automated integration tests that validate hostname→tenant mapping and membership gating (GW-001..GW-003, GW-007..GW-009).
- Evidence artifacts (test outputs, config snapshots, and release manifests) will be linked here as they are produced.

---

# SRS-0202: CouchDB Service Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-01-31
**Status:** Draft

This specification defines the software requirements for the on-box **CouchDB service** (system-of-record for tenant DBs). It is a minimal scaffold; detailed requirements live in section records and the authoritative Glossary.

## Normative Language

Normative keywords (SHALL, SHALL NOT, SHOULD, SHOULD NOT, MAY) and OurBox OS product/architecture vocabulary are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

## Introduction

This SRS defines requirements for the **on-box CouchDB service**, which acts as the tenant-scoped system-of-record and replication target.

Scope includes:
- tenant DB creation and naming posture (`tenant_<tenant_id>`)
- partitioned database posture and `_id` scheme
- replication posture at the database level (tenant DB ↔ tenant DB)
- tenant storage contract boundaries for CouchDB usage

Out of scope:
- gateway routing, `/db` mapping, and host/path policy (see `[[spec:SRS-0201]]`)
- client local replicas and PouchDB behavior (see `[[spec:SRS-0204]]`)
- tenant blob store requirements (see `[[spec:SRS-0205]]`)

This SRS is intentionally a minimal scaffold, but it pulls in the already-established requirements from:
- `[[spec:SyRS-0001]]` (system requirements for data/replication), and
- `[[arch_doc:AD-0001]]` (architecture invariants for storage/replication posture).

## Referenced Documents

- `docs/00-Glossary/Terms-and-Definitions.md`
- [[spec:SyRS-0001]]
- [[arch_doc:AD-0001]]
- [[adr:ADR-0001]]
- [[adr:ADR-0002]]
- [[adr:ADR-0003]]
- [[adr:ADR-0004]]
- [[adr:ADR-0005]]
- [[adr:ADR-0006]]
- [[adr:ADR-0007]]
- [[spec:SRS-0201]]
- [[spec:SRS-0203]]
- [[spec:SRS-0205]]

## Requirements

Allocated system requirements from `[[spec:SyRS-0001]]` are included here for traceability; CouchDB-service-specific requirements follow.

### DATA-001: Each tenant SHALL have exactly one tenant DB

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Tenant DBs are the replication unit for data modeling and replication.

OurBox SHALL maintain one CouchDB database per tenant, named using the `tenant_<tenant_id>` pattern.

### DATA-002: Tenant DBs SHALL be partitioned databases

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Partitioning enforces doc-kind boundaries.

All tenant databases SHALL be created as CouchDB partitioned databases.

### DATA-003: Document IDs SHALL use the doc_kind:uuidv4 scheme

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Canonical IDs ensure consistent replication and conflict boundaries.

Application documents SHALL have `_id` values shaped as `<doc_kind>:<uuidv4>`.

### DATA-004: Doc kind SHALL be derived from _id only

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Avoids divergent sources of truth for document classification.

Applications and services SHALL derive `doc_kind` from the `_id` prefix and SHALL NOT store a separate
doc-type field as the authoritative source.

### DATA-005: Tenant replication SHALL be whole-DB

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Replication posture is tenant DB ↔ tenant DB.

Replication between client devices and the box SHALL use the tenant DB as the unit of replication and
SHALL NOT require selective partition replication.

### DATA-006: Blobs SHALL be stored outside CouchDB by default

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Large binary content should not be default CouchDB attachments; tenant-scoped blob stores enable legible tenant operations.

Large binary assets (photos/video/audio) SHALL be stored outside CouchDB by default in the tenant blob store (one blob store per tenant), with references stored in application documents.

### DATA-007: Each tenant SHALL have exactly one tenant blob store

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Tenant-scoped blob stores keep blob payload bytes legible for tenant operations and align with ADR-0006 storage roots.

OurBox SHALL maintain one tenant blob store per tenant for blob payload bytes stored outside CouchDB.

Each tenant blob store SHALL use a tenant-scoped storage root (ADR-0006).

### K8S-005: CouchDB SHALL run as a k3s workload

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** ADR-0007 establishes that CouchDB runs as a k3s workload for consistent appliance operations.

The CouchDB service SHALL be deployed and managed as a Kubernetes workload in the on-box k3s cluster and SHALL NOT be operated as an unmanaged host-level daemon.

**Trace:** [[adr:ADR-0007]]

### K8S-006: CouchDB data SHALL be stored on persistent volumes

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** CouchDB is the system-of-record; when deployed in k3s its data must survive pod restarts and rescheduling.

The CouchDB workload SHALL store CouchDB data files on persistent storage provided via Kubernetes PersistentVolumeClaim(s).

CouchDB SHALL NOT store system-of-record data only on ephemeral container filesystem storage.

**Trace:** [[adr:ADR-0007]]

### BOXDB-001: Replication SHALL use the standard CouchDB API and replication protocol

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Preserves interoperability across many clients and enables future peer replication without proprietary protocols.

Replication between clients and the box SHALL use the standard CouchDB HTTP API and replication protocol.

**Trace:** [[arch_doc:AD-0001]] §4.5

### BOXDB-002: Replication SHALL be treated as synchronization, not backup

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Replication can copy deletions and bad changes; backup must be point-in-time retention.

Replication SHALL be treated as availability/synchronization behavior and SHALL NOT be treated as backup.

**Trace:** [[arch_doc:AD-0001]] §7.1

## External Interfaces

The CouchDB service is treated as internal infrastructure.

Client-facing replication endpoints are presented via the Gateway on tenant origins (see `[[spec:SRS-0201]]`). Any direct CouchDB node/admin surface is intentionally out of scope for client access.

Concrete in-cluster service interfaces (Service names, ports, authentication material, internal URLs, and any network policy)
are defined by the versioned deployment baseline manifests and are discoverable via cluster inspection (ADR-0008).

Any additional protocol-level contracts introduced between services (beyond what the deployment baseline expresses) are defined
as machine-readable contract artifacts (OpenAPI/JSON schema) and verified by automated tests.

## Verification

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:
- **Inspection:** tenant DB naming, partitioned mode configuration, and blob-store posture.
- **Test:** replication between a client and the box using the tenant DB as the unit of replication.

---

# SRS-0203: k3s Platform Contract Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-01-31
**Status:** Draft

This specification defines the software requirements for the **k3s platform contract** shipped on an OurBox instance (workload topology, persistent data placement, operational defaults, governance, and verification posture). It is a minimal scaffold; detailed requirements live in section records and the authoritative Glossary.

## Normative Language

Normative keywords (SHALL, SHALL NOT, SHOULD, SHOULD NOT, MAY) and OurBox OS product/architecture vocabulary are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

## Introduction

This SRS defines requirements for the **k3s platform contract** used to deploy and operate OurBox OS workloads on an OurBox instance.

Scope includes:
- k3s as the Kubernetes distribution used on-box for OurBox OS workloads
- Kubernetes namespace posture (operational grouping; not tenant boundaries)
- **data placement** requirements for system-of-record data when deployed in k3s (persistent storage expectations)
- **defaults** required for out-of-box operation (e.g., default persistent volume provisioning, namespace conventions)
- **governance** posture for the deployment configuration baseline (how the deployed platform is defined and controlled)
- **verification** posture for confirming the running cluster satisfies the contract

Out of scope:
- gateway routing semantics and app/path policy (see `[[spec:SRS-0201]]`)
- on-box CouchDB data modeling posture (see `[[spec:SRS-0202]]`)
- tenant blob store semantics and CAS rules (see `[[spec:SRS-0205]]`)
- app-specific behavior and UI flows (see app SRSs)

## Referenced Documents

- `docs/00-Glossary/Terms-and-Definitions.md`
- [[spec:SyRS-0001]]
- [[arch_doc:AD-0001]]
- [[adr:ADR-0003]]
- [[adr:ADR-0007]]
- [[spec:SRS-0201]]
- [[spec:SRS-0202]]
- [[spec:SRS-0205]]

## Requirements

Allocated system requirements from `[[spec:SyRS-0001]]` are included here for traceability; k3s-platform-specific requirements follow.

### K8S-001: Kubernetes namespaces SHALL NOT encode tenant boundaries

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** Tenant is a data boundary, not an operational namespace.

Kubernetes namespaces SHALL be used for operational grouping and SHALL NOT be treated as the primary
tenant isolation boundary.

### K8S-002: Public custom-domain ingress SHALL support wildcard tenant hosts

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** Public tenant hosts require wildcard host routing.

For public custom-domain mode, ingress configuration SHALL support wildcard host routing for
`*.<box-host>`.

### K8S-003: Shipped app workloads SHOULD use dedicated namespaces

**Status:** Draft  
**Testable:** false  
**Area:** k8s  
**Rationale:** Separates app operations while keeping tenant boundaries intact.

Shipped app workload bundles SHOULD run in their own Kubernetes namespaces to simplify operations
and isolation from platform services.

### K8S-004: OurBox OS SHALL use k3s as the Kubernetes distribution

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** AD-0001 establishes OurBox as a k3s-based appliance deployment posture.

OurBox OS SHALL deploy and operate its Kubernetes workloads using k3s on each OurBox instance.

**Trace:** [[arch_doc:AD-0001]]

### K8S-005: CouchDB SHALL run as a k3s workload

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** ADR-0007 establishes that CouchDB runs as a k3s workload for consistent appliance operations.

The CouchDB service SHALL be deployed and managed as a Kubernetes workload in the on-box k3s cluster and SHALL NOT be operated as an unmanaged host-level daemon.

**Trace:** [[adr:ADR-0007]]

### K8S-006: CouchDB data SHALL be stored on persistent volumes

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** CouchDB is the system-of-record; when deployed in k3s its data must survive pod restarts and rescheduling.

The CouchDB workload SHALL store CouchDB data files on persistent storage provided via Kubernetes PersistentVolumeClaim(s).

CouchDB SHALL NOT store system-of-record data only on ephemeral container filesystem storage.

**Trace:** [[adr:ADR-0007]]

### K8S-007: k3s platform SHALL provide default persistent volume provisioning for system-of-record workloads

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** Operational simplicity: the appliance should provide durable storage without requiring manual PV provisioning.

The k3s platform deployment SHALL provide a default mechanism to provision persistent volumes suitable for system-of-record workloads (e.g., CouchDB) without requiring the operator to pre-create volumes.

**Trace:** [[arch_doc:AD-0001]] §2.1

### K8S-008: Platform workloads SHOULD use dedicated system namespaces

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** AD-0001 recommends a small set of namespaces for platform workloads and app workloads for operational legibility.

Shared multi-tenant platform workloads (e.g., gateway, CouchDB, platform services) SHOULD run in a small set of dedicated Kubernetes namespaces (e.g., `ourbox-system`, `ourbox-platform`).

Shipped app workload bundles SHOULD run in app-specific Kubernetes namespaces (e.g., `app-simplenote`, `app-richnote`).

**Trace:** [[arch_doc:AD-0001]] §5.4.1

### K8S-009: k3s platform deployment SHALL be governed by a versioned configuration baseline

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** A versioned baseline enables reproducible deployments and controlled changes consistent with requirements governance.

The Kubernetes resources that define the OurBox OS platform deployment (namespaces, workloads, ingress, and storage objects) SHALL be defined declaratively in version-controlled artifacts.

Changes to the deployment baseline SHALL follow controlled change procedures.

**Trace:** `docs/00-Glossary/Terms-and-Definitions.md` (Baseline, Change control)

## External Interfaces

The k3s platform is treated as internal infrastructure on the OurBox instance.

External interfaces include:
- Kubernetes deployment artifacts (manifests/charts) used to define the platform baseline
- operational inspection surfaces (e.g., `kubectl`-visible resources, logs, events)

Operational procedures and any operator-facing commands are documented as operational runbooks and validated by conformance tests
where feasible. The deployment baseline manifests are the authoritative definition of platform topology and configuration (ADR-0008).

## Verification

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:
- **Inspection:** confirm namespace posture (no tenant namespaces) and wildcard host ingress posture.
- **Inspection:** confirm CouchDB is deployed as a k3s workload and uses persistent storage (PVC/PV).
- **Test:** restart/reschedule the CouchDB pod and confirm tenant DB data remains intact.
- **Inspection:** confirm the deployment baseline is traceable to versioned artifacts (release manifests/config snapshots).

---

# SRS-0204: Local Tenant Replica Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-01-31
**Status:** Draft

This specification defines the software requirements for the **local tenant replica** on client devices (PouchDB/IndexedDB within a tenant origin). It is a minimal scaffold; detailed requirements live in section records and the authoritative Glossary.

## Normative Language

Normative keywords (SHALL, SHALL NOT, SHOULD, SHOULD NOT, MAY) and OurBox OS product/architecture vocabulary are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

## Introduction

The Local Tenant Replica stores tenant data in-browser per tenant origin.

Tenant origins include both mode patterns:
- `http://<tenant_id>.local`
- `https://<tenant_id>.<box-host>`

These are different origins and therefore different local tenant replicas.

## Referenced Documents

- `docs/00-Glossary/Terms-and-Definitions.md`
- [[spec:SyRS-0001]]
- [[arch_doc:AD-0001]]
- [[adr:ADR-0001]]
- [[adr:ADR-0002]]
- [[adr:ADR-0003]]
- [[adr:ADR-0004]]
- [[spec:SRS-0201]]
- [[spec:SRS-0202]]

## Requirements

Allocated system requirements from `[[spec:SyRS-0001]]` are included here for traceability; local-replica-specific requirements follow.

### APP-002: Shipped apps SHALL persist working data locally

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Offline writes depend on local persistence.

Shipped apps SHALL store working data locally in the tenant origin using PouchDB-backed IndexedDB.

### APP-003: Shipped apps SHALL sync opportunistically

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Supports sporadic connectivity while keeping data consistent.

Shipped apps SHALL initiate incremental replication with the tenant DB when connectivity is available.

### APP-005: Apps SHALL share one local tenant replica per origin

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Ensures apps share doc kinds offline.

All shipped apps under the same tenant origin SHALL read and write through a single local tenant
replica database on that device.

### DATA-005: Tenant replication SHALL be whole-DB

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Replication posture is tenant DB ↔ tenant DB.

Replication between client devices and the box SHALL use the tenant DB as the unit of replication and
SHALL NOT require selective partition replication.

### BOXDB-001: Replication SHALL use the standard CouchDB API and replication protocol

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Preserves interoperability across many clients and enables future peer replication without proprietary protocols.

Replication between clients and the box SHALL use the standard CouchDB HTTP API and replication protocol.

**Trace:** [[arch_doc:AD-0001]] §4.5

### LCR-001: Local tenant replica SHALL use the stable database name `tenant_local`

**Status:** Draft  
**Testable:** true  
**Area:** client  
**Rationale:** A stable local DB name enables multiple shipped apps under the same tenant origin to share the same working store.

Within a tenant origin, the local tenant replica SHALL use the stable PouchDB database name `tenant_local`.

**Trace:** [[arch_doc:AD-0001]] §5.2.2

## External Interfaces

Replication interfaces:
- local-only: `http://<tenant_id>.local/db`
- public custom-domain: `https://<tenant_id>.<box-host>/db`

Same tenant across these two origins uses distinct local replicas on the same browser profile.

## Verification

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:
- **Test:** offline write/read against the local tenant replica; then reconnect and replicate successfully.
- **Inspection:** confirm a single local tenant replica is used across shipped apps within the same tenant origin.

---

# SRS-0205: Tenant Blob Store Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-01-31
**Status:** Draft

This specification defines the software requirements for the on-box **tenant blob store** (tenant-scoped, content-addressed blob payload storage outside CouchDB). It is a minimal scaffold; detailed requirements live in section records and the authoritative Glossary.

## Normative Language

Normative keywords (SHALL, SHALL NOT, SHOULD, SHOULD NOT, MAY) and OurBox OS product/architecture vocabulary are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

## Introduction

This SRS defines requirements for the **tenant blob store**, which stores blob payload bytes outside CouchDB as part of the tenant storage contract.

Key posture (already established in architecture/decisions):
- each tenant has a tenant-scoped blob store
- application documents store references to blobs (payload bytes live outside CouchDB by default)
- blob storage is content-addressed and uses a deterministic path layout

Out of scope:
- gateway routing and external HTTP surfaces for blob access (see `[[spec:SRS-0201]]`)
- CouchDB tenant DB concerns (see `[[spec:SRS-0202]]`)
- client-local replica behavior (see `[[spec:SRS-0204]]`)

## Referenced Documents

- `docs/00-Glossary/Terms-and-Definitions.md`
- [[spec:SyRS-0001]]
- [[arch_doc:AD-0001]]
- [[adr:ADR-0002]]
- [[adr:ADR-0005]]
- [[adr:ADR-0006]]
- [[spec:SRS-0201]]
- [[spec:SRS-0202]]

## Requirements

Allocated system requirements from `[[spec:SyRS-0001]]` are included here for traceability; blob-store-specific requirements follow.

### DATA-006: Blobs SHALL be stored outside CouchDB by default

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Large binary content should not be default CouchDB attachments; tenant-scoped blob stores enable legible tenant operations.

Large binary assets (photos/video/audio) SHALL be stored outside CouchDB by default in the tenant blob store (one blob store per tenant), with references stored in application documents.

### DATA-007: Each tenant SHALL have exactly one tenant blob store

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Tenant-scoped blob stores keep blob payload bytes legible for tenant operations and align with ADR-0006 storage roots.

OurBox SHALL maintain one tenant blob store per tenant for blob payload bytes stored outside CouchDB.

Each tenant blob store SHALL use a tenant-scoped storage root (ADR-0006).

### BLOB-001: Tenant blob store SHALL be content-addressed by a canonical multihash key

**Status:** Draft  
**Testable:** true  
**Area:** blob  
**Rationale:** ADR-0005 establishes content-addressed blob storage keyed by a canonical multihash key.

The tenant blob store SHALL store blob payload bytes in a content-addressed manner keyed by a canonical multihash key.

**Trace:** [[adr:ADR-0005]]

### BLOB-002: Tenant blob store SHALL NOT chunk blob payload bytes

**Status:** Draft  
**Testable:** true  
**Area:** blob  
**Rationale:** ADR-0005 explicitly establishes a no-chunking posture for blob payload storage.

Blob payload bytes stored in the tenant blob store SHALL NOT be chunked; a blob key identifies the full payload bytes.

**Trace:** [[adr:ADR-0005]]

### BLOB-003: Blob payload bytes SHALL use a deterministic sharded path layout

**Status:** Draft  
**Testable:** true  
**Area:** blob  
**Rationale:** ADR-0006 establishes deterministic sharded path layout for blob payload bytes.

Blob payload bytes SHALL be stored using a deterministic sharded path layout under the tenant storage root.

**Trace:** [[adr:ADR-0006]]

## External Interfaces

The tenant blob store is treated as internal infrastructure.

Client-visible blob upload/download interfaces (if/when introduced) are defined as tenant-origin HTTP surfaces and described via
machine-readable API contracts (OpenAPI/JSON schema), with conformance tests. This SRS specifies blob-store invariants and on-box storage
posture; HTTP/API surfaces are mediated by the Gateway and/or platform services.

## Verification

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:
- **Inspection:** blob store layout under the tenant storage root follows the deterministic scheme.
- **Test:** write blob payload bytes, reference them from a document, and confirm retrieval under tenant context.

---

# SRS-0206: Identity and Tenant Membership Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-01-31
**Status:** Draft

This specification defines the software requirements for OurBox OS identity primitives and tenant membership (user_id, tenant_id, membership, roles/capabilities, and authorization inputs). It is a minimal scaffold; detailed requirements live in section records and the authoritative Glossary.

## Normative Language

Normative keywords (SHALL, SHALL NOT, SHOULD, SHOULD NOT, MAY) and OurBox OS product/architecture vocabulary are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

## Introduction

This SRS defines requirements for identity and tenant membership posture in OurBox OS.

Scope includes:
- identifier constraints for `tenant_id` and `user_id`
- tenant membership as the authorization gate at the tenant boundary
- authorization decision inputs (user identity + tenant context + membership + roles/capabilities)

Out of scope:
- gateway routing and ingress mechanics (see `[[spec:SRS-0201]]`)
- token formats, header names, and session mechanics (defined by contract artifacts and enforced by tests; not specified in this SRS)
- UI flows for login/tenant management (not specified here)

## Referenced Documents

- `docs/00-Glossary/Terms-and-Definitions.md`
- [[spec:SyRS-0001]]
- [[arch_doc:AD-0001]]
- [[adr:ADR-0003]]
- [[spec:SRS-0201]]

## Requirements

Identity requirements derive tenant context from the leftmost DNS label of the full host in both modes.
`tenant_id` constraints are DNS-label-safe and mode-neutral.

### ID-001: user_id SHALL be unique and stable within an OurBox instance

**Status:** Draft  
**Testable:** true  
**Area:** identity  
**Rationale:** Glossary defines `user_id` uniqueness and stability expectations for legible identity across tenants.

Within an OurBox instance, `user_id` SHALL be unique.

`user_id` SHOULD be treated as stable/immutable once created. Renaming a `user_id` is a migration and SHALL be explicit.

`user_id` values are not reusable by default.

`user_id` SHALL be safe for use in URLs, logs, and configuration.

**Trace:** `docs/00-Glossary/Terms-and-Definitions.md` (user_id)

### ID-003: display_name SHALL NOT be used as an identifier

**Status:** Draft  
**Testable:** true  
**Area:** identity  
**Rationale:** Glossary states display_name is presentation-only and must not be treated as identity.

`display_name` is presentation-only and SHALL NOT be used as an identifier.

**Trace:** `docs/00-Glossary/Terms-and-Definitions.md` (display_name)

### ID-004: Authorization SHALL consider user identity, tenant context, and tenant-scoped roles/capabilities

**Status:** Draft  
**Testable:** true  
**Area:** identity  
**Rationale:** AD-0001 defines the normative authorization decision inputs at the tenant boundary.

Authorization SHALL consider:
- authenticated user identity (`user_id`)
- tenant derived from hostname (`tenant_id`)
- membership and roles/capabilities within that tenant
- any doc-kind-specific rules where applicable

**Trace:** [[arch_doc:AD-0001]] §6.3

## External Interfaces

This SRS does not define token formats, cookie names, header names, or claim shapes.

Concrete identity/session wire formats and internal identity-context propagation are defined as versioned contract artifacts
(e.g., OpenAPI security schemes and/or JSON schemas) and are enforced by automated tests.

## Verification

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:
- **Inspection:** identifier rules for `tenant_id` and `user_id` are enforced consistently.
- **Test:** membership gating prevents cross-tenant access when hostnames differ.

---

# SRS-1001: SimpleNote Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-01-28
**Status:** Draft

This specification defines the software requirements for the SimpleNote application.

This is intentionally minimal scaffolding; requirements will be added iteratively.

## Normative Language

Normative keywords (SHALL, SHALL NOT, SHOULD, SHOULD NOT, MAY) are defined in
`docs/00-Glossary/Terms-and-Definitions.md`.

## Introduction

This SRS defines the requirements for the SimpleNote application software item.

SimpleNote is a user-facing application. Detailed requirements will be added iteratively.

## Referenced Documents

- `docs/00-Glossary/Terms-and-Definitions.md`
- [[spec:SyRS-0001]]
- [[arch_doc:AD-0001]]
- [[adr:ADR-0001]]
- [[adr:ADR-0002]]
- [[adr:ADR-0003]]
- [[adr:ADR-0004]]

## Requirements

This section will be populated with SimpleNote software requirements.

Typical groupings (to be filled in later):
- Allocated System Requirements (from SyRS)
- Functional Requirements
- Data Requirements
- Quality Requirements (NFRs)
- Constraints

## External Interfaces

- App route (local-only): `http://<tenant_id>.local/simplenote`
- App route (public custom-domain): `https://<tenant_id>.<box-host>/simplenote`
- Replication endpoint (local-only): `http://<tenant_id>.local/db`
- Replication endpoint (public custom-domain): `https://<tenant_id>.<box-host>/db` (same-origin, via Gateway)

## Verification

Verification provisions (methods, environments, and trace links to evidence) will be defined here.
Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

---

# SRS-1002: RichNote Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-01-28
**Status:** Draft

This specification defines the software requirements for the RichNote application.

This is intentionally minimal scaffolding; requirements will be added iteratively.

## Normative Language

Normative keywords (SHALL, SHALL NOT, SHOULD, SHOULD NOT, MAY) are defined in
`docs/00-Glossary/Terms-and-Definitions.md`.

## Introduction

This SRS defines the requirements for the RichNote application software item.

RichNote is a user-facing application. Detailed requirements will be added iteratively.

## Referenced Documents

- `docs/00-Glossary/Terms-and-Definitions.md`
- [[spec:SyRS-0001]]
- [[arch_doc:AD-0001]]
- [[adr:ADR-0001]]
- [[adr:ADR-0002]]
- [[adr:ADR-0003]]
- [[adr:ADR-0004]]

## Requirements

This section will be populated with RichNote software requirements.

Typical groupings (to be filled in later):
- Allocated System Requirements (from SyRS)
- Functional Requirements
- Data Requirements
- Quality Requirements (NFRs)
- Constraints

## External Interfaces

- App route (local-only): `http://<tenant_id>.local/richnote`
- App route (public custom-domain): `https://<tenant_id>.<box-host>/richnote`
- Replication endpoint (local-only): `http://<tenant_id>.local/db`
- Replication endpoint (public custom-domain): `https://<tenant_id>.<box-host>/db` (same-origin, via Gateway)

## Verification

Verification provisions (methods, environments, and trace links to evidence) will be defined here.
Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

---

# SRS-1003: Messager Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-02-25
**Status:** Draft

This specification defines the software requirements for the **Messager** application.

Messager is a shipped, tenant-scoped messaging experience for OurBox OS. It is designed for multi-user
communication within a tenant without introducing “private compartments” inside the tenant boundary,
aligning with the principle that the tenant is the social boundary.

## External Interfaces

- App route (local-only): `http://<tenant_id>.local/messager`
- App route (public custom-domain): `https://<tenant_id>.<box-host>/messager`
- Replication endpoint (local-only): `http://<tenant_id>.local/db`
- Replication endpoint (public custom-domain): `https://<tenant_id>.<box-host>/db` (same-origin, via Gateway)

## Normative Language

The key words **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, and **MAY** are to be interpreted as
requirements.

OurBox OS vocabulary and normative definitions are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

## Introduction

This SRS defines requirements for the **Messager** app experience.

Scope includes:
- tenant-scoped channels and messages
- offline-first behavior consistent with ADR-0001 posture
- shared local tenant replica usage (`tenant_local`)
- message document model and attachment handling using the tenant blob store
- optional voice/video calls within the tenant boundary
- optional bot/automation behavior within tenant membership semantics

Out of scope:
- interoperability with external messaging ecosystems (e.g., SMS, email, Matrix, ActivityPub)
- privacy compartments inside a tenant (DMs, secret channels) — use separate tenants instead

## Referenced Documents

- `docs/00-Glossary/Terms-and-Definitions.md`
- [[spec:SyRS-0001]]
- [[arch_doc:AD-0001]]
- [[adr:ADR-0001]]
- [[adr:ADR-0002]]
- [[adr:ADR-0003]]
- [[adr:ADR-0004]]
- [[adr:ADR-0005]]
- [[adr:ADR-0006]]
- [[spec:SRS-0201]]
- [[spec:SRS-0204]]
- [[spec:SRS-0205]]
- [[spec:SRS-0206]]

## Requirements

Allocated system requirements from `[[spec:SyRS-0001]]` are included here for traceability; Messager-specific requirements follow.

### Allocated System Requirements (from SyRS)

#### APP-001: Public custom-domain mode SHALL provide full installable-PWA posture

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Installability and reopen-offline guarantees depend on HTTPS secure-context behavior.

In public custom-domain mode, shipped OurBox apps SHALL support full installable-PWA behavior,
including service-worker-backed reopen-offline operation after first successful load.

#### APP-002: Shipped apps SHALL persist working data locally

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Offline writes depend on local persistence.

Shipped apps SHALL store working data locally in the tenant origin using PouchDB-backed IndexedDB.

#### APP-003: Shipped apps SHALL sync opportunistically

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Supports sporadic connectivity while keeping data consistent.

Shipped apps SHALL initiate incremental replication with the tenant DB when connectivity is available.

#### APP-004: Shipped apps SHALL use mode-aware tenant-origin route patterns

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Tenant routing is mode-aware and path identifies app in both modes.

Shipped apps SHALL be served at tenant origins using supported mode patterns: local-only mode
`http://<tenant_id>.local/<app_slug>` and public custom-domain mode
`https://<tenant_id>.<box-host>/<app_slug>`, where `tenant_id` is derived from the leftmost DNS
label of the full host.

#### APP-005: Apps SHALL share one local tenant replica per origin

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Ensures apps share doc kinds offline.

All shipped apps under the same tenant origin SHALL read and write through a single local tenant
replica database on that device.

#### APP-006: Apps SHALL honor doc-kind contracts

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Shared storage requires strict doc-kind boundaries.

Shipped apps SHALL only create and update documents whose `_id` prefixes match the stable doc-kind
vocabulary defined for OurBox OS.

### Functional and Data Requirements (Messager-specific)

#### MSG-003: Messager SHALL use mode-aware tenant routes

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Messager follows shared tenant-host/path routing model across both access modes.

Messager SHALL be served at `http://<tenant_id>.local/messager` in local-only mode and
`https://<tenant_id>.<box-host>/messager` in public custom-domain mode, deriving tenant context
from the leftmost DNS label of the full host.

#### MSG-001: Messager SHALL treat the tenant as the social boundary

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Avoid private compartments; tenant is the unit of social trust.

Messager SHALL treat the tenant boundary as the only privacy/social boundary.

All tenant members with `messager:read` capability SHALL be able to read all messages in the tenant.

If users require a private compartment, they SHALL create a separate tenant instead of creating DMs inside a tenant.

#### MSG-002: Messager SHALL NOT implement private compartments within a tenant

**Status:** Draft  
**Testable:** true  
**Area:** security  
**Rationale:** Private compartments inside a tenant are confusing and dangerous; use tenants instead.

Messager SHALL NOT implement:
- direct/private messages scoped to a subset of tenant members,
- “secret” channels with per-channel membership ACLs,
- per-message encryption keys that exclude some tenant members.

Any feature that materially restricts message visibility MUST be implemented by using a separate tenant.

#### MSG-004: Messager SHALL use the shared local tenant replica

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Shared local tenant replica is required for offline-first behavior and cross-app doc sharing (SyRS APP-005).

Messager SHALL read and write its documents through the shared local tenant replica `tenant_local` within the tenant origin.

#### MSG-005: Messager SHALL provide tenant-wide channels

**Status:** Draft  
**Testable:** true  
**Area:** messaging  
**Rationale:** Provide organization without introducing private compartments.

Messager SHALL provide one or more tenant-wide message channels.

Channel membership SHALL NOT be restricted within the tenant.

Messager SHALL provide a default channel (e.g., `general`).

#### MSG-006: Messager SHALL support real-time-ish updates via replication

**Status:** Draft  
**Testable:** true  
**Area:** messaging  
**Rationale:** Leverages CouchDB/PouchDB replication for incremental updates without custom protocols.

Messager SHOULD use live/continuous replication (or periodic incremental replication) to deliver near-real-time updates when the box is reachable.

Messager SHALL remain functional when the box is unreachable after first load.

#### MSG-007: Messager SHALL support end-to-end offline messaging

**Status:** Draft  
**Testable:** true  
**Area:** offline  
**Rationale:** Offline-first posture: messages must be creatable and viewable without connectivity.

Messages composed offline SHALL be persisted locally immediately and appear in the UI.

When connectivity returns, messages SHALL replicate automatically to the tenant DB via `/db` without user intervention.

#### MSG-008: Messager SHALL support file and media attachments

**Status:** Draft  
**Testable:** true  
**Area:** messaging  
**Rationale:** Messaging commonly includes images/audio/files; blob store is the canonical posture.

Messager SHALL support attaching files/media to messages.

Attachment metadata (filename, MIME type, size, and blob reference) SHALL be stored in message documents.

Attachment payload bytes SHALL be stored in the tenant blob store by default (see MSG-009).

#### MSG-009: Messager SHALL store attachment payload bytes in the tenant blob store by default

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Align with ADR-0002/ADR-0005 posture: blobs outside CouchDB, content-addressed, tenant-scoped.

Messager SHALL NOT store attachment payload bytes as CouchDB attachments by default.

Instead, Messager SHALL store attachment payload bytes in the tenant blob store and store only content-addressed references (e.g., multihash/CID) in message documents.

**Trace:** [[spec:SyRS-0001]] DATA-006, DATA-007; [[adr:ADR-0005]]; [[adr:ADR-0006]].

#### MSG-010: Messager SHOULD support offline staging of attachments

**Status:** Draft  
**Testable:** false  
**Area:** offline  
**Rationale:** Improves usability on unstable networks; staging may be complex due to blob-store APIs.

Messager SHOULD allow users to attach files while offline by staging payload bytes locally and uploading them to the tenant blob store when connectivity returns.

If offline staging is not supported, Messager SHALL communicate clearly that attachments require connectivity.

#### MSG-011: Messager SHALL support voice notes

**Status:** Draft  
**Testable:** true  
**Area:** messaging  
**Rationale:** Voice notes are a common low-friction messaging primitive.

Messager SHALL allow users to record and send voice notes.

Voice note audio payload bytes SHALL be stored as blobs in the tenant blob store, referenced from a message document.

#### MSG-012: Messager SHALL support sharing existing tenant documents by reference

**Status:** Draft  
**Testable:** true  
**Area:** integration  
**Rationale:** Apps share one local tenant replica; sharing should be references, not copies.

Messager SHALL allow messages to reference existing tenant documents by `_id`.

Example: a message may reference a `note:*` document or a `task:*` document.

Messager SHALL NOT duplicate the referenced document as a message payload.

#### MSG-013: Messager SHALL define messaging doc kinds and commit to stable doc-kind vocabulary tokens

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Shared storage requires stable doc kinds and clear contracts (AD-0001 §9.2).

Messager SHALL store its primary documents using doc kinds encoded in `_id`.

Messager SHALL introduce the following doc kinds (stable vocabulary tokens):
- `thread` — channel/thread metadata
- `msg` — message documents
- `call` — call history documents

Each doc kind SHALL be documented with:
- required and optional fields,
- indexing/query posture,
- conflict handling posture.

**Trace:** [[arch_doc:AD-0001]] §9.2 (Adding a new doc kind).

#### MSG-014: Messager message documents SHALL be immutable after creation

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Append-only messaging avoids conflicts and reduces complexity.

After a `msg:*` document is created, Messager SHALL treat it as immutable.

Edits and deletions of messages SHOULD NOT be supported in the v0 posture.

If redaction/moderation is required in future, it SHALL be implemented via additional documents (not in-place mutation).

#### MSG-015: Messager SHALL provide deterministic message ordering

**Status:** Draft  
**Testable:** true  
**Area:** messaging  
**Rationale:** Replication and intermittent connectivity require stable ordering for rendering.

Messager SHALL render messages in a deterministic order.

Recommended ordering (normative):
1) `created_at` timestamp ascending,
2) tie-break by `_id` ascending.

Messager SHALL tolerate clock skew across devices by not assuming timestamps are globally accurate.

#### MSG-016: Messager SHALL support voice and video calls between tenant members

**Status:** Draft  
**Testable:** true  
**Area:** calling  
**Rationale:** Calls are a canonical “phone-like OS” primitive; tenant boundary keeps it legible.

Messager SHALL support initiating and receiving real-time voice and video calls between tenant members.

Call participation SHALL be limited to tenant members (per membership enforced by the Gateway).

#### MSG-017: Messager call signaling SHALL be same-origin with the tenant

**Status:** Draft  
**Testable:** true  
**Area:** calling  
**Rationale:** Avoid CORS/topology coupling; align with tenant-origin routing posture.

Call signaling (offer/answer/ICE exchange) SHALL occur over a tenant-origin surface:
- `https://<tenant_id>.<box-host>/api/messager/call/...`

The Gateway SHALL enforce tenant membership on signaling endpoints.

(Exact signaling protocol is out of scope; WebRTC is assumed.)

#### MSG-018: Messager SHALL record durable call history in the tenant DB

**Status:** Draft  
**Testable:** true  
**Area:** calling  
**Rationale:** Call history is user-visible state and must replicate across devices.

Messager SHALL record call events (missed/received/placed, participants, start/end times) as durable documents in the tenant DB (doc kind `call`).

Call history SHALL be visible to all tenant members with `messager:read` capability.

#### MSG-019: Messager SHALL support bots as ordinary users

**Status:** Draft  
**Testable:** true  
**Area:** automation  
**Rationale:** Bots should be legible: they are users with memberships/capabilities.

Messager SHALL support bot accounts implemented as ordinary `user_id` identities with tenant membership.

Bots SHALL NOT bypass tenant membership enforcement.

Bots MAY post messages and attachments subject to the same capability checks as humans.

#### MSG-020: Messager SHALL NOT require external messaging networks or federation

**Status:** Draft  
**Testable:** true  
**Area:** constraint  
**Rationale:** Explicit product posture: no external interop requirement; keep implementation small and legible.

Messager SHALL NOT require interoperability with external messaging ecosystems.

Messager SHALL NOT implement federated identity, cross-instance message routing, or third-party network bridges in the v0 posture.

#### MSG-021: Messager SHOULD provide a tenant-scoped encryption mode without creating intra-tenant compartments

**Status:** Draft  
**Testable:** false  
**Area:** security  
**Rationale:** Encryption is desirable, but must not create intra-tenant compartments; operator truth still applies.

Messager SHOULD provide an encryption mode where message payloads are encrypted at rest in the tenant DB/blob store.

If implemented, encryption keys SHALL be tenant-scoped and available to all tenant members (subject to membership), not per-channel or per-DM.

This feature SHALL NOT claim confidentiality from the device operator (Operator Truth).

#### MSG-022: Messager SHOULD minimize client resource footprint

**Status:** Draft  
**Testable:** false  
**Area:** quality  
**Rationale:** Align with “low profile code” posture: minimal RAM/CPU and small bundle size.

Messager SHOULD minimize client resource usage by:
- using pagination/virtualized lists for long timelines,
- avoiding loading unbounded message history into memory,
- limiting background timers and watchers,
- keeping client bundle size small.

Resource budgets (exact numbers) are defined in performance test baselines, not in this SRS.

## Verification

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:
- **Test:** offline send/receive behavior using the local tenant replica; then reconnect and replicate successfully.
- **Inspection:** confirm no DM/private-channel UI or enforcement exists within a tenant.
- **Test:** attachment upload/download round-trip with blob references in message docs.
- **Test (optional):** voice/video call signaling and call-history persistence.

---

# SRS-1004: Scout Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-03-06
**Status:** Draft

This specification defines the software requirements for the **Scout** application.

Scout is a shipped, tenant-scoped civic intelligence experience for OurBox OS. It monitors user-chosen civic information sources and user-provided civic artifacts, then produces source-grounded briefings, extracted claims, issue tracking, and question-answering for the tenant.

## External Interfaces

- App route (local-only): `http://<tenant_id>.local/scout`
- App route (public custom-domain): `https://<tenant_id>.<box-host>/scout`
- Replication endpoint (local-only): `http://<tenant_id>.local/db`
- Replication endpoint (public custom-domain): `https://<tenant_id>.<box-host>/db` (same-origin, via Gateway)
- Optional service APIs (local-only): `http://<tenant_id>.local/api/scout/...`
- Optional service APIs (public custom-domain): `https://<tenant_id>.<box-host>/api/scout/...`

## Normative Language

The key words **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, and **MAY** are to be interpreted as requirements.

OurBox OS vocabulary and normative definitions are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

## Introduction

This SRS defines requirements for the **Scout** app experience.

Scope includes:

* user-chosen civic source monitoring
* user-provided civic artifact analysis (e.g., political mailers, flyers, public notices, PDFs, screenshots)
* source snapshotting and provenance tracking
* issue, claim, and civic event/proceeding extraction
* source-grounded briefings and question-answering
* change-over-time comparison across watched sources

Out of scope:

* value-to-candidate matching and ballot guidance
* adversarial/perspective-challenging dialogue behavior
* standalone long-form event recording and evidence workflows
* standalone anti-censorship archiving/version-history workflows
* interoperability with third-party social networks or box-to-box distribution in the v0 posture

## Referenced Documents

* `docs/00-Glossary/Terms-and-Definitions.md`
* [[spec:SyRS-0001]]
* [[arch_doc:AD-0001]]
* [[adr:ADR-0001]]
* [[adr:ADR-0002]]
* [[adr:ADR-0003]]
* [[adr:ADR-0004]]
* [[adr:ADR-0005]]
* [[adr:ADR-0006]]
* [[spec:SRS-0201]]
* [[spec:SRS-0204]]
* [[spec:SRS-0205]]
* [[spec:SRS-0206]]

## Requirements

Allocated system requirements from `[[spec:SyRS-0001]]` are included here for traceability; Scout-specific requirements follow.

### Allocated System Requirements (from SyRS)

#### APP-001: Public custom-domain mode SHALL provide full installable-PWA posture

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Installability and reopen-offline guarantees depend on HTTPS secure-context behavior.

In public custom-domain mode, shipped OurBox apps SHALL support full installable-PWA behavior,
including service-worker-backed reopen-offline operation after first successful load.

#### APP-002: Shipped apps SHALL persist working data locally

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Offline writes depend on local persistence.

Shipped apps SHALL store working data locally in the tenant origin using PouchDB-backed IndexedDB.

#### APP-003: Shipped apps SHALL sync opportunistically

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Supports sporadic connectivity while keeping data consistent.

Shipped apps SHALL initiate incremental replication with the tenant DB when connectivity is available.

#### APP-004: Shipped apps SHALL use mode-aware tenant-origin route patterns

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Tenant routing is mode-aware and path identifies app in both modes.

Shipped apps SHALL be served at tenant origins using supported mode patterns: local-only mode
`http://<tenant_id>.local/<app_slug>` and public custom-domain mode
`https://<tenant_id>.<box-host>/<app_slug>`, where `tenant_id` is derived from the leftmost DNS
label of the full host.

#### APP-005: Apps SHALL share one local tenant replica per origin

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Ensures apps share doc kinds offline.

All shipped apps under the same tenant origin SHALL read and write through a single local tenant
replica database on that device.

#### APP-006: Apps SHALL honor doc-kind contracts

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Shared storage requires strict doc-kind boundaries.

Shipped apps SHALL only create and update documents whose `_id` prefixes match the stable doc-kind
vocabulary defined for OurBox OS.

### Functional and Data Requirements (Scout-specific)

#### SCOUT-001: Scout SHALL monitor user-chosen civic information sources

**Status:** Draft  
**Testable:** true  
**Area:** scout  
**Rationale:** Scout is a civic intelligence app, not a generic feed; source selection must remain user-directed.

Scout SHALL allow the user to configure one or more watched civic information sources.

Watched sources SHALL be explicit tenant-visible configuration.

Scout SHALL support monitoring public internet sources selected by the user and SHALL NOT require a hidden platform-curated feed as the primary input to Scout coverage.

#### SCOUT-002: Scout SHALL accept user-provided civic artifacts for analysis

**Status:** Draft  
**Testable:** true  
**Area:** scout  
**Rationale:** Users often receive civic information outside normal web sources (e.g., political mailers, flyers, notices).

Scout SHALL accept user-provided civic artifacts for analysis.

At minimum, Scout SHALL accept:

* URL inputs,
* text/HTML inputs,
* image artifacts, and
* PDF artifacts.

Examples include political mailers, campaign flyers, candidate webpages, public notices, and issue handouts.

#### SCOUT-003: Scout SHALL preserve source snapshots and provenance

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Source-grounded civic analysis requires durable provenance and inspectable evidence.

For each fetched or uploaded artifact that Scout analyzes, Scout SHALL create or reference a `source:*` record and a `snapshot:*` record.

Each `snapshot:*` record SHALL include, at minimum:

* provenance (e.g., source URI or upload origin),
* observed/ingested timestamp,
* content hash/digest, and
* media type.

When source artifact payload bytes are binary or large, Scout SHALL store payload bytes in the tenant blob store by default and SHALL store only references in application documents.

**Trace:** [[spec:SyRS-0001]] DATA-006, DATA-007; [[spec:SRS-0205]]; [[adr:ADR-0005]]; [[adr:ADR-0006]]

#### SCOUT-004: Scout SHALL produce source-grounded briefings

**Status:** Draft  
**Testable:** true  
**Area:** scout  
**Rationale:** Scout’s primary user-visible value is turning civic source material into readable briefings without severing the link to evidence.

Scout SHALL generate plain-language briefings over watched sources, issues, and civic events/proceedings.

Each nontrivial factual assertion presented in a briefing SHALL be traceable to one or more underlying `snapshot:*` records available to the user.

Briefings SHALL present source links or references sufficient for user inspection.

#### SCOUT-005: Scout SHALL distinguish source material, extraction, and generation

**Status:** Draft  
**Testable:** true  
**Area:** transparency  
**Rationale:** Users must be able to tell what came from the source, what was extracted, and what was generated by AI.

Scout SHALL distinguish between:

* captured or quoted source material,
* extracted structured observations, and
* AI-generated summaries or synthesized briefings.

At minimum, Scout SHALL distinguish:

* source text/media,
* extracted issues, claims, names, dates, and actions,
* generated summaries, narratives, or explanations.

#### SCOUT-006: Scout SHALL extract issues, claims, and civic events/proceedings from sources

**Status:** Draft  
**Testable:** true  
**Area:** scout  
**Rationale:** Scout’s civic intelligence value depends on structured extraction rather than simple bookmarking.

Scout SHALL extract issue, claim, and civic event/proceeding information from analyzed sources when supported by source evidence.

Where Scout materializes a civic event or proceeding as a durable application document, Scout SHALL use the existing `event:*` doc kind.

Scout SHALL surface referenced public actors (e.g., candidates, committees, agencies, organizations) in briefings and query results when detected in source material.

#### SCOUT-007: Scout SHALL answer questions over the watched corpus with citations and explicit insufficiency

**Status:** Draft  
**Testable:** true  
**Area:** scout  
**Rationale:** Question-answering is only trustworthy when grounded in the watched corpus and honest about gaps.

Scout SHALL answer user questions over the watched corpus with citations to underlying `snapshot:*` records.

When sufficient evidence is not available in the watched corpus, Scout SHALL say so explicitly and SHALL NOT present unsupported certainty as established fact.

#### SCOUT-008: Scout SHALL support change-over-time comparison across watched sources

**Status:** Draft  
**Testable:** true  
**Area:** scout  
**Rationale:** Political webpages, issue statements, and campaign material change over time; users need “what changed?” as a first-class capability.

Where multiple `snapshot:*` records exist for the same source or materially related source chain, Scout SHALL support change-over-time comparison.

Scout SHALL be able to surface additions, removals, and materially changed claims when determinable from the available evidence.

#### SCOUT-009: Scout SHALL keep prioritization and following rules user-visible and user-controlled

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Scout is meant to strengthen citizen judgment, not to hide agenda-setting behind an opaque ranking system.

Scout SHALL present watched sources, followed issues, and prioritization/ranking rules as tenant-visible configuration.

Scout SHALL NOT use hidden engagement optimization as the primary method for deciding what civic information to surface to the user.

#### SCOUT-010: Scout SHALL define Scout doc kinds and commit to stable doc-kind vocabulary tokens

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Shared storage across apps requires stable civic doc kinds and explicit contracts.

Scout SHALL store its primary documents using doc kinds encoded in `_id`.

Scout SHALL introduce the following doc kinds (stable vocabulary tokens):

* `source` — watched source identity/configuration
* `snapshot` — captured source artifact at a point in time
* `issue` — canonical civic issue/topic record
* `claim` — extracted claim tied to one or more snapshots
* `brief` — user-facing briefing generated from source material
* `watch` — user watch/follow configuration

Each doc kind SHALL be documented with:

* required and optional fields,
* indexing/query posture,
* conflict handling posture.

**Trace:** [[arch_doc:AD-0001]] §9.2

#### SCOUT-011: Scout-generated briefings SHALL record generation provenance

**Status:** Draft  
**Testable:** true  
**Area:** transparency  
**Rationale:** Users need inspectable generation context for civic briefings.

Each `brief:*` document generated by Scout SHALL record generation provenance.

At minimum, a `brief:*` document SHALL record:

* input snapshot IDs,
* generation time,
* model/runtime identifier, and
* any user-selected briefing scope or watch criteria used.

#### SCOUT-012: Scout source snapshots SHALL be immutable after creation

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Provenance and change-over-time analysis depend on immutable historical capture records.

After a `snapshot:*` document is created, Scout SHALL treat it as immutable.

Corrections, annotations, or re-ingests SHALL be represented as new documents or linked documents rather than by overwriting the original snapshot.

#### SCOUT-013: Scout SHOULD support on-demand and scheduled briefings

**Status:** Draft  
**Testable:** false  
**Area:** scout  
**Rationale:** Users benefit from both pull-based research and push-style periodic summary.

Scout SHOULD support:

* on-demand briefings for watched issues,
* on-demand briefings for candidates or organizations referenced in the watched corpus, and
* scheduled digests covering recent changes across watched sources.

## Verification

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:

* **Test:** configure a watched public source, ingest content, and generate a source-grounded briefing with citations.
* **Test:** upload a political mailer image or PDF and confirm Scout extracts claims, issue references, and source-backed briefing output.
* **Test:** ingest two versions of the same source and confirm Scout surfaces change-over-time differences.
* **Test:** ask a question over the watched corpus and confirm the answer cites supporting `snapshot:*` records or explicitly states insufficient evidence.
* **Inspection:** confirm watched sources and prioritization rules are explicit tenant-visible configuration and that no hidden feed is the primary ranking mechanism.
* **Test:** confirm previously generated briefings and supporting source excerpts remain readable offline after first successful load.

---

# SRS-1005: Compass Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-03-06
**Status:** Draft

This specification defines the software requirements for the **Compass** application.

Compass is a shipped, tenant-scoped civic decision-support experience for OurBox OS. It helps users map explicit civic values, priorities, and red lines to source-grounded candidate positions within a user-selected contest scope.

## External Interfaces

- App route (local-only): `http://<tenant_id>.local/compass`
- App route (public custom-domain): `https://<tenant_id>.<box-host>/compass`
- Replication endpoint (local-only): `http://<tenant_id>.local/db`
- Replication endpoint (public custom-domain): `https://<tenant_id>.<box-host>/db` (same-origin, via Gateway)
- Optional service APIs (local-only): `http://<tenant_id>.local/api/compass/...`
- Optional service APIs (public custom-domain): `https://<tenant_id>.<box-host>/api/compass/...`

## Normative Language

The key words **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, and **MAY** are to be interpreted as requirements.

OurBox OS vocabulary and normative definitions are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

## Introduction

This SRS defines requirements for the **Compass** app experience.

Scope includes:

* explicit user civic values, priorities, red lines, and tradeoff capture
* user-selected contest scope and candidate-set evaluation
* candidate and contest material analysis
* source-grounded stance extraction
* transparent candidate-fit evaluation against explicit user values
* side-by-side candidate comparison within a contest

Out of scope:

* broad civic source monitoring and general-purpose issue reporting
* adversarial/perspective-challenging dialogue behavior
* standalone long-form event recording and evidence workflows
* standalone anti-censorship archiving/version-history workflows
* official election-administration guidance (e.g., registration deadlines, polling-place procedures)
* campaign persuasion optimization, voter targeting, or hidden behavioral ranking

## Referenced Documents

* `docs/00-Glossary/Terms-and-Definitions.md`
* [[spec:SyRS-0001]]
* [[arch_doc:AD-0001]]
* [[adr:ADR-0001]]
* [[adr:ADR-0002]]
* [[adr:ADR-0003]]
* [[adr:ADR-0004]]
* [[adr:ADR-0005]]
* [[adr:ADR-0006]]
* [[spec:SRS-0201]]
* [[spec:SRS-0204]]
* [[spec:SRS-0205]]
* [[spec:SRS-0206]]
* [[spec:SRS-1004]]

## Requirements

Allocated system requirements from `[[spec:SyRS-0001]]` are included here for traceability; Compass-specific requirements follow.

### Allocated System Requirements (from SyRS)

#### APP-001: Public custom-domain mode SHALL provide full installable-PWA posture

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Installability and reopen-offline guarantees depend on HTTPS secure-context behavior.

In public custom-domain mode, shipped OurBox apps SHALL support full installable-PWA behavior,
including service-worker-backed reopen-offline operation after first successful load.

#### APP-002: Shipped apps SHALL persist working data locally

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Offline writes depend on local persistence.

Shipped apps SHALL store working data locally in the tenant origin using PouchDB-backed IndexedDB.

#### APP-003: Shipped apps SHALL sync opportunistically

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Supports sporadic connectivity while keeping data consistent.

Shipped apps SHALL initiate incremental replication with the tenant DB when connectivity is available.

#### APP-004: Shipped apps SHALL use mode-aware tenant-origin route patterns

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Tenant routing is mode-aware and path identifies app in both modes.

Shipped apps SHALL be served at tenant origins using supported mode patterns: local-only mode
`http://<tenant_id>.local/<app_slug>` and public custom-domain mode
`https://<tenant_id>.<box-host>/<app_slug>`, where `tenant_id` is derived from the leftmost DNS
label of the full host.

#### APP-005: Apps SHALL share one local tenant replica per origin

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Ensures apps share doc kinds offline.

All shipped apps under the same tenant origin SHALL read and write through a single local tenant
replica database on that device.

#### APP-006: Apps SHALL honor doc-kind contracts

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Shared storage requires strict doc-kind boundaries.

Shipped apps SHALL only create and update documents whose `_id` prefixes match the stable doc-kind
vocabulary defined for OurBox OS.

### Functional and Data Requirements (Compass-specific)

#### COMPASS-001: Compass SHALL capture explicit user civic values and priorities

**Status:** Draft  
**Testable:** true  
**Area:** compass  
**Rationale:** Compass exists to help users apply their own values to civic choices; those values must be explicit rather than implicit.

Compass SHALL allow the user to create one or more explicit civic values profiles.

A civic values profile SHALL support, at minimum:

* named priorities,
* issue preferences,
* red lines or non-negotiable concerns, and
* relative weighting or tradeoff inputs sufficient for candidate-fit evaluation.

#### COMPASS-002: Compass SHALL treat the user values profile as user-visible, user-editable configuration

**Status:** Draft  
**Testable:** true  
**Area:** transparency  
**Rationale:** Compass should strengthen user agency, not replace it with hidden psychographic inference.

Compass SHALL present the active civic values profile as tenant-visible, user-editable configuration.

Compass SHALL NOT require hidden psychographic inference as the primary authority for candidate-fit evaluation when an explicit user profile is present.

#### COMPASS-003: Compass SHALL operate on a user-selected contest scope and candidate set

**Status:** Draft  
**Testable:** true  
**Area:** compass  
**Rationale:** Candidate matching is only meaningful within a contest scope the user can inspect and confirm.

Compass SHALL allow the user to select, confirm, or provide the contest scope and candidate set to be evaluated.

Any location-, district-, or ballot-scope derivation used by Compass SHALL remain user-visible and user-confirmable.

The user-confirmed contest scope SHALL be authoritative for Compass candidate-fit evaluation.

#### COMPASS-004: Compass SHALL accept candidate and contest materials for analysis

**Status:** Draft  
**Testable:** true  
**Area:** compass  
**Rationale:** Users need to evaluate candidates from real materials such as websites, mailers, debate transcripts, and handouts.

Compass SHALL accept candidate and contest materials for analysis.

At minimum, Compass SHALL accept:

* URL inputs,
* text/HTML inputs,
* image artifacts, and
* PDF artifacts.

Examples include candidate webpages, political mailers, debate transcripts, campaign flyers, voter guides, and issue handouts.

#### COMPASS-005: Compass SHALL preserve source provenance for candidate and contest materials

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Values-to-candidate matching must remain inspectable and tied back to evidence.

For each fetched or uploaded artifact that Compass analyzes, Compass SHALL create or reference a `source:*` record and a `snapshot:*` record.

Each referenced or created `snapshot:*` record SHALL include, at minimum:

* provenance (e.g., source URI or upload origin),
* observed/ingested timestamp,
* content hash/digest, and
* media type.

When source artifact payload bytes are binary or large, Compass SHALL store payload bytes in the tenant blob store by default and SHALL store only references in application documents.

**Trace:** [[spec:SyRS-0001]] DATA-006, DATA-007; [[spec:SRS-0205]]; [[adr:ADR-0005]]; [[adr:ADR-0006]]

#### COMPASS-006: Compass SHALL extract candidate stances tied to source evidence

**Status:** Draft  
**Testable:** true  
**Area:** compass  
**Rationale:** Candidate-fit evaluation depends on durable stance extraction rather than opaque free-form model impressions.

Compass SHALL extract candidate stances from analyzed materials when supported by source evidence.

Each durable `stance:*` record SHALL identify, at minimum:

* the candidate,
* the issue or issue reference,
* the extracted position, characterization, or stated uncertainty, and
* one or more supporting source references.

Where a relevant `issue:*` record exists in the tenant DB, Compass SHOULD link extracted stances to that `issue:*` record rather than duplicating issue identity.

#### COMPASS-007: Compass SHALL evaluate candidate fit against the explicit user profile using inspectable matching logic

**Status:** Draft  
**Testable:** true  
**Area:** compass  
**Rationale:** Compass should help users reason about fit, not hide a recommendation in opaque model behavior.

Compass SHALL evaluate each candidate against the active civic values profile using inspectable matching logic.

A candidate-fit evaluation SHALL be traceable to:

* explicit profile inputs,
* extracted candidate stance information, and
* underlying source references.

Compass MAY present summary scores or categories, but the explanation of candidate fit SHALL remain inspectable by the user.

#### COMPASS-008: Compass SHALL distinguish source material, extraction, and generation

**Status:** Draft  
**Testable:** true  
**Area:** transparency  
**Rationale:** Users need to tell the difference between candidate source material, extracted stance data, and generated evaluation.

Compass SHALL distinguish between:

* captured or quoted source material,
* extracted candidate stances and structured observations, and
* AI-generated fit explanations, summaries, or comparisons.

At minimum, Compass SHALL distinguish:

* source text/media,
* extracted issue and stance observations, and
* generated candidate-fit explanations.

#### COMPASS-009: Compass SHALL surface per-issue alignment, conflict, and insufficient evidence

**Status:** Draft  
**Testable:** true  
**Area:** compass  
**Rationale:** A useful civic match should show where a candidate aligns, where they conflict, and where the record is thin.

For each evaluated candidate, Compass SHALL surface per-issue results sufficient to distinguish:

* alignment with the active civic values profile,
* conflict with the active civic values profile, and
* insufficient evidence or unresolved ambiguity.

Compass SHALL NOT reduce the primary user-facing result to a single unexplained overall ranking.

#### COMPASS-010: Compass SHALL keep issue weighting and ranking rules user-visible and user-controlled

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Candidate ranking and issue prioritization are normative choices that should remain under user control.

Compass SHALL present issue weighting, red-line handling, and any ranking rules used in candidate-fit evaluation as tenant-visible configuration.

Compass SHALL allow the user to modify those controls before or after generating candidate-fit evaluations.

#### COMPASS-011: Compass SHALL surface uncertainty and missing information explicitly

**Status:** Draft  
**Testable:** true  
**Area:** transparency  
**Rationale:** Civic decision support is misleading if it hides weak evidence, ambiguity, or missing candidate positions.

When evidence is incomplete, ambiguous, contradictory, or absent, Compass SHALL say so explicitly.

Compass SHALL NOT present unsupported certainty about a candidate position, issue fit, or overall candidate-fit result as established fact.

#### COMPASS-012: Compass SHALL NOT use hidden persuasion optimization or covert recommendation as the primary output

**Status:** Draft  
**Testable:** true  
**Area:** constraint  
**Rationale:** Compass is for citizen decision support, not behavioral manipulation.

Compass SHALL NOT use hidden persuasion optimization, engagement optimization, or covert recommendation as the primary output mode.

Compass SHALL NOT treat undisclosed behavioral profiling as the primary basis for ranking candidates or emphasizing issues.

#### COMPASS-013: Compass SHALL define Compass doc kinds and commit to stable doc-kind vocabulary tokens

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Shared storage across apps requires stable civic doc kinds and explicit contracts.

Compass SHALL store its primary documents using doc kinds encoded in `_id`.

Compass SHALL introduce the following doc kinds (stable vocabulary tokens):

* `profile` — explicit user civic values/priorities profile
* `contest` — selected contest scope and candidate set
* `candidate` — candidate identity record within a contest
* `stance` — extracted candidate stance tied to one or more sources
* `fit` — generated comparison between a profile and candidate within a contest

Each doc kind SHALL be documented with:

* required and optional fields,
* indexing/query posture,
* conflict handling posture.

**Trace:** [[arch_doc:AD-0001]] §9.2

#### COMPASS-014: Compass-generated fit evaluations SHALL record generation provenance

**Status:** Draft  
**Testable:** true  
**Area:** transparency  
**Rationale:** Users need inspectable generation context for candidate-fit outputs.

Each `fit:*` document generated by Compass SHALL record generation provenance.

At minimum, a `fit:*` document SHALL record:

* input profile ID,
* contest ID,
* candidate ID,
* referenced stance and snapshot IDs,
* generation time,
* model/runtime identifier, and
* weighting or ranking configuration used.

#### COMPASS-015: Compass SHOULD support side-by-side candidate comparison within a contest

**Status:** Draft  
**Testable:** false  
**Area:** compass  
**Rationale:** Users benefit from comparing multiple candidates against the same explicit values profile and evidence base.

Compass SHOULD support side-by-side comparison of two or more candidates within the same contest.

A side-by-side comparison SHOULD highlight, at minimum:

* issue-by-issue differences,
* shared unknowns or missing evidence, and
* the profile inputs driving the comparison.

## Verification

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:

* **Test:** create an explicit user values profile and confirm the profile remains user-visible and editable.
* **Test:** configure a contest scope and candidate set, ingest candidate materials, and confirm Compass extracts source-grounded candidate stances.
* **Test:** generate candidate-fit evaluations and confirm each evaluation explains its reasoning with source references and explicit user-priority inputs.
* **Test:** change issue weighting or red-line configuration and confirm candidate-fit outputs update predictably.
* **Test:** confirm Compass surfaces insufficient evidence when candidate-position data is missing or ambiguous.
* **Inspection:** confirm Compass does not require hidden psychographic inference or hidden persuasion optimization as the primary basis for output.
* **Test:** confirm saved profiles, candidate-fit evaluations, and cited source excerpts remain readable offline after first successful load.

---

# SRS-1006: Spar Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-03-06
**Status:** Draft

This specification defines the software requirements for the **Spar** application.

Spar is a shipped, tenant-scoped civic dialogue experience for OurBox OS. It helps users challenge, refine, and test civic positions through source-grounded, user-controlled dialogue intended to reduce echo-chamber effects without hidden persuasion optimization or behavioral steering.

## External Interfaces

- App route (local-only): `http://<tenant_id>.local/spar`
- App route (public custom-domain): `https://<tenant_id>.<box-host>/spar`
- Replication endpoint (local-only): `http://<tenant_id>.local/db`
- Replication endpoint (public custom-domain): `https://<tenant_id>.<box-host>/db` (same-origin, via Gateway)
- Optional service APIs (local-only): `http://<tenant_id>.local/api/spar/...`
- Optional service APIs (public custom-domain): `https://<tenant_id>.<box-host>/api/spar/...`

## Normative Language

The key words **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, and **MAY** are to be interpreted as requirements.

OurBox OS vocabulary and normative definitions are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

## Introduction

This SRS defines requirements for the **Spar** app experience.

Scope includes:

* user-initiated civic dialogue over positions, claims, questions, and proposals
* user-selectable challenge modes such as steelmanning, reframing, and evidence testing
* source-grounded dialogue over user-provided materials and tenant-local civic records
* explicit separation of facts, value judgments, predictions, and tradeoffs
* uncertainty and evidence-gap surfacing
* reflection summaries over dialogue sessions

Out of scope:

* broad civic source monitoring and general-purpose issue reporting
* value-to-candidate matching and ballot guidance
* standalone long-form event recording and evidence workflows
* standalone anti-censorship archiving/version-history workflows
* social networking, box-to-box distribution, or public-feed mechanics in the v0 posture
* hidden persuasion optimization, behavioral targeting, or covert viewpoint steering

## Referenced Documents

* `docs/00-Glossary/Terms-and-Definitions.md`
* [[spec:SyRS-0001]]
* [[arch_doc:AD-0001]]
* [[adr:ADR-0001]]
* [[adr:ADR-0002]]
* [[adr:ADR-0003]]
* [[adr:ADR-0004]]
* [[adr:ADR-0005]]
* [[adr:ADR-0006]]
* [[spec:SRS-0201]]
* [[spec:SRS-0204]]
* [[spec:SRS-0205]]
* [[spec:SRS-0206]]
* [[spec:SRS-1004]]
* [[spec:SRS-1005]]

## Requirements

Allocated system requirements from `[[spec:SyRS-0001]]` are included here for traceability; Spar-specific requirements follow.

### Allocated System Requirements (from SyRS)

#### APP-001: Public custom-domain mode SHALL provide full installable-PWA posture

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Installability and reopen-offline guarantees depend on HTTPS secure-context behavior.

In public custom-domain mode, shipped OurBox apps SHALL support full installable-PWA behavior,
including service-worker-backed reopen-offline operation after first successful load.

#### APP-002: Shipped apps SHALL persist working data locally

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Offline writes depend on local persistence.

Shipped apps SHALL store working data locally in the tenant origin using PouchDB-backed IndexedDB.

#### APP-003: Shipped apps SHALL sync opportunistically

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Supports sporadic connectivity while keeping data consistent.

Shipped apps SHALL initiate incremental replication with the tenant DB when connectivity is available.

#### APP-004: Shipped apps SHALL use mode-aware tenant-origin route patterns

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Tenant routing is mode-aware and path identifies app in both modes.

Shipped apps SHALL be served at tenant origins using supported mode patterns: local-only mode
`http://<tenant_id>.local/<app_slug>` and public custom-domain mode
`https://<tenant_id>.<box-host>/<app_slug>`, where `tenant_id` is derived from the leftmost DNS
label of the full host.

#### APP-005: Apps SHALL share one local tenant replica per origin

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Ensures apps share doc kinds offline.

All shipped apps under the same tenant origin SHALL read and write through a single local tenant
replica database on that device.

#### APP-006: Apps SHALL honor doc-kind contracts

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Shared storage requires strict doc-kind boundaries.

Shipped apps SHALL only create and update documents whose `_id` prefixes match the stable doc-kind
vocabulary defined for OurBox OS.

### Functional and Data Requirements (Spar-specific)

#### SPAR-001: Spar SHALL support user-initiated civic dialogue over positions, claims, questions, and proposals

**Status:** Draft  
**Testable:** true  
**Area:** spar  
**Rationale:** Spar exists to help users actively test their own civic thinking rather than passively consume a feed.

Spar SHALL allow the user to start one or more dialogue sessions around a civic position, claim, question, or proposal.

A dialogue session SHALL support user turns and Spar-generated turns over a user-selected topic or issue scope.

#### SPAR-002: Spar SHALL provide user-selectable challenge modes

**Status:** Draft  
**Testable:** true  
**Area:** spar  
**Rationale:** Users should be able to choose how they want their thinking challenged rather than receive a single opaque style of response.

Spar SHALL provide user-selectable challenge modes.

At minimum, Spar SHALL support modes sufficient to:

* steelman an opposing or alternative view,
* identify assumptions or tradeoffs,
* separate facts, value judgments, and predictions, and
* explore what evidence would change the conclusion.

#### SPAR-003: Spar SHALL accept user-provided positions, claims, questions, and supporting materials

**Status:** Draft  
**Testable:** true  
**Area:** spar  
**Rationale:** Users need to challenge their thinking using both their own statements and civic materials already in their possession.

Spar SHALL accept user-provided positions, claims, questions, and supporting materials for analysis.

At minimum, Spar SHALL accept:

* free-text inputs,
* URL inputs,
* image artifacts,
* PDF artifacts, and
* references to tenant-local civic records already present in the shared local tenant replica.

Examples include user-written opinions, screenshots, political mailers, candidate materials, issue briefs, and Scout-generated records.

#### SPAR-004: Spar SHALL preserve source provenance for fetched or uploaded supporting materials

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Source-grounded civic dialogue must remain inspectable and tied back to evidence.

For each fetched or uploaded artifact that Spar analyzes, Spar SHALL create or reference a `source:*` record and a `snapshot:*` record.

Each referenced or created `snapshot:*` record SHALL include, at minimum:

* provenance (e.g., source URI or upload origin),
* observed/ingested timestamp,
* content hash/digest, and
* media type.

When source artifact payload bytes are binary or large, Spar SHALL store payload bytes in the tenant blob store by default and SHALL store only references in application documents.

**Trace:** [[spec:SyRS-0001]] DATA-006, DATA-007; [[spec:SRS-0205]]; [[adr:ADR-0005]]; [[adr:ADR-0006]]

#### SPAR-005: Spar SHALL distinguish source material, extraction, and generation

**Status:** Draft  
**Testable:** true  
**Area:** transparency  
**Rationale:** Users need to know what came from source material, what was extracted or structured, and what was generated by AI.

Spar SHALL distinguish between:

* captured or quoted source material,
* extracted positions, claims, issue observations, or other structured observations, and
* AI-generated challenge responses, reflections, or dialogue summaries.

At minimum, Spar SHALL distinguish:

* source text/media,
* extracted claim or issue observations, and
* generated challenge or reflection output.

#### SPAR-006: Spar SHALL support steelmanned opposing arguments and alternative civic framings

**Status:** Draft  
**Testable:** true  
**Area:** spar  
**Rationale:** Spar should help users become less trapped in echo chambers by presenting materially different viewpoints and framings.

When the user selects an opposing-view or reframing challenge mode, Spar SHALL produce one or more challenge responses that present a materially different position, concern, or policy framing.

Where supporting source material is available, Spar SHALL cite that material in the generated challenge response.

#### SPAR-007: Spar SHALL distinguish facts, value judgments, predictions, and policy tradeoffs when requested

**Status:** Draft  
**Testable:** true  
**Area:** spar  
**Rationale:** Civic disagreement often becomes less confusing when factual claims, moral commitments, and predictions are separated.

When the user requests analytical separation, Spar SHALL be able to distinguish:

* factual claims,
* value judgments or normative commitments,
* predictions or causal expectations, and
* policy tradeoffs or opportunity costs.

#### SPAR-008: Spar SHALL identify assumptions, uncertainties, and evidence gaps in the position under examination

**Status:** Draft  
**Testable:** true  
**Area:** spar  
**Rationale:** A useful challenge process should reveal what is being assumed and where the evidence is weak.

Spar SHALL be able to identify assumptions, uncertainties, and evidence gaps in the position, claim, or proposal under examination.

Where supporting source material is available, Spar SHALL link identified evidence gaps or contradictions back to relevant source references.

#### SPAR-009: Spar SHALL articulate what evidence would strengthen, weaken, or change a conclusion when determinable

**Status:** Draft  
**Testable:** true  
**Area:** spar  
**Rationale:** Users need help understanding what would actually move a civic judgment rather than only hearing abstract disagreement.

When determinable from the available material, Spar SHALL articulate one or more evidence conditions, observations, or questions that would strengthen, weaken, or change the current conclusion or position under examination.

#### SPAR-010: Spar SHALL keep dialogue goals, challenge modes, and explicit conversation constraints user-visible and user-controlled

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Spar should help users think better without hiding the rules of engagement.

Spar SHALL present the active dialogue goal, selected challenge mode, and any explicit conversation constraints as tenant-visible, user-editable configuration.

Examples of conversation constraints MAY include source scope, response style, or challenge intensity.

#### SPAR-011: Spar SHALL NOT use hidden persuasion optimization or covert behavioral steering as the primary output

**Status:** Draft  
**Testable:** true  
**Area:** constraint  
**Rationale:** Spar is for citizen self-reflection and intellectual resilience, not behavioral manipulation.

Spar SHALL NOT use hidden persuasion optimization, engagement optimization, or covert behavioral steering as the primary output mode.

Spar SHALL NOT treat undisclosed behavioral profiling as the primary basis for determining which arguments, framings, or challenges to present.

#### SPAR-012: Spar SHALL surface uncertainty and insufficient evidence explicitly

**Status:** Draft  
**Testable:** true  
**Area:** transparency  
**Rationale:** Civic dialogue is misleading if it hides weak evidence, ambiguity, or unresolved uncertainty.

When evidence is incomplete, ambiguous, contradictory, or absent, Spar SHALL say so explicitly.

Spar SHALL NOT present unsupported certainty about a claim, challenge response, or reflection summary as established fact.

#### SPAR-013: Spar dialogue turns and generated outputs SHALL record provenance and remain append-only

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Users need a durable, inspectable record of what was said, what was generated, and how the dialogue evolved over time.

Each `turn:*` document SHALL record, at minimum:

* turn author type (e.g., user or Spar),
* created timestamp,
* parent dialog ID, and
* referenced source, claim, or generation inputs sufficient to reconstruct turn provenance when applicable.

After a `turn:*`, `challenge:*`, or `reflection:*` document is created, Spar SHALL treat it as immutable.

Corrections or follow-on elaborations SHALL be represented as new linked documents rather than by overwriting the original record.

#### SPAR-014: Spar SHALL define Spar doc kinds and commit to stable doc-kind vocabulary tokens

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Shared storage across apps requires stable civic doc kinds and explicit contracts.

Spar SHALL store its primary documents using doc kinds encoded in `_id`.

Spar SHALL introduce the following doc kinds (stable vocabulary tokens):

* `dialog` — user-controlled Spar dialogue session
* `turn` — immutable user or Spar dialogue turn
* `position` — explicit civic position, question, claim, or proposal under examination
* `challenge` — generated counterargument, reframing, or evidence challenge tied to dialogue context
* `reflection` — generated summary of strongest counterarguments, uncertainties, and next evidence questions

Each doc kind SHALL be documented with:

* required and optional fields,
* indexing/query posture,
* conflict handling posture.

**Trace:** [[arch_doc:AD-0001]] §9.2

#### SPAR-015: Spar SHOULD support reflection summaries and resumable dialogue

**Status:** Draft  
**Testable:** false  
**Area:** spar  
**Rationale:** Users benefit from returning to a civic question later with a clear summary of what was learned and what remains unresolved.

Spar SHOULD support generated reflection summaries that capture, at minimum:

* strongest opposing arguments surfaced,
* unresolved uncertainties or evidence gaps, and
* next questions or evidence to seek.

Previously saved dialogues SHOULD be resumable by the user within the same tenant origin.

## Verification

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:

* **Test:** start a dialogue session around a user-provided civic claim, question, or proposal and confirm that user-selected challenge modes change the output type appropriately.
* **Test:** attach or select source materials and confirm Spar cites relevant supporting or opposing source records when source-grounded responses are available.
* **Test:** request separation of facts, value judgments, predictions, and tradeoffs and confirm Spar distinguishes those categories in its output.
* **Test:** ask what evidence would strengthen, weaken, or change a conclusion and confirm Spar returns explicit evidence conditions or states that the available evidence is insufficient.
* **Inspection:** confirm dialogue goals, challenge modes, and explicit conversation constraints are tenant-visible configuration and that hidden persuasion optimization is not the primary basis for output.
* **Test:** confirm generated turns record authorship and provenance and remain append-only after creation.
* **Test:** confirm saved dialogues and reflection summaries remain readable offline after first successful load.

---
