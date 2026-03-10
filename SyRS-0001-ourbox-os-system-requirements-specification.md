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

These requirements describe shipped OurBox application posture across both tenant-origin access modes, including mode-scoped offline/PWA behavior and doc-kind handling.

### APP-001: Public custom-domain mode SHALL provide full installable-PWA posture for shipped apps

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Full installability and reopen-offline guarantees are mode-scoped to public HTTPS tenant origins.

In public custom-domain mode, shipped OurBox apps SHALL be installable PWAs and SHALL be capable of reopen-offline behavior after first successful load via service-worker-backed cached assets.

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

### APP-004: Apps SHALL operate within a tenant origin in both access modes

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Tenant origins define storage isolation and routing in both local-only and public custom-domain modes.

Shipped apps SHALL be served under tenant origins in both supported patterns:
- local-only mode: `http://<tenant_id>.local/<app_slug>`
- public custom-domain mode: `https://<tenant_id>.<box-host>/<app_slug>`

The full host SHALL carry tenant context, `tenant_id` SHALL be derived from the leftmost DNS label of the full host, and path SHALL identify app.

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

### APP-007: Local-only mode SHALL be HTTP-only

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Local-only mode is intentionally plain-HTTP local access.

Local-only mode SHALL use HTTP tenant hosts (`http://<tenant_id>.local/...`) and SHALL NOT require or imply HTTPS/TLS.

### APP-008: Local-only mode documentation SHALL NOT promise public-mode-equivalent full PWA posture

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Prevent overclaiming installability/reopen-offline equivalence for HTTP local mode.

Documentation and requirements for local-only mode SHALL NOT guarantee installability or reopen-offline behavior equivalent to public custom-domain mode.

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

## Gateway and Identity

These requirements define mode-aware tenant host routing, identity enforcement, and the gateway surface used by
clients and shipped apps.

### GW-001: Gateway SHALL derive tenant context from the full host

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Tenant routing is host-derived across both access modes.

The gateway SHALL derive `tenant_id` from the leftmost DNS label of the request full host and treat it as authoritative tenant context.

### GW-002: Gateway SHALL enforce tenant membership

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Ensures user access is scoped to the tenant origin.

The gateway SHALL enforce that authenticated users are members of the tenant implied by the full host
before allowing access to tenant-scoped services.

### GW-003: Replication endpoints SHALL be same-origin in both access modes

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Browser clients replicate without CORS/topology leakage in local-only and public custom-domain modes.

The gateway SHALL expose replication at `/db` on the tenant origin in both modes:
- `http://<tenant_id>.local/db`
- `https://<tenant_id>.<box-host>/db`

Clients SHALL NOT require internal CouchDB endpoints.

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
**Rationale:** Public tenant-host routing relies on wildcard full-host matching.

For public custom-domain mode, ingress configuration SHALL support wildcard host routing for `*.<box-host>`.

### K8S-003: Shipped app workloads SHOULD use dedicated namespaces

**Status:** Draft  
**Testable:** false  
**Area:** k8s  
**Rationale:** Separates app operations while keeping tenant boundaries intact.

Shipped app workload bundles SHOULD run in their own Kubernetes namespaces to simplify operations
and isolation from platform services.

### K8S-010: Local-only ingress SHALL support HTTP tenant hosts

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** Local-only mode requires `<tenant_id>.local` HTTP routing.

Ingress and service routing for local-only mode SHALL support HTTP tenant hosts matching `<tenant_id>.local` and MAY include `ourbox.local` for landing/setup flows.
