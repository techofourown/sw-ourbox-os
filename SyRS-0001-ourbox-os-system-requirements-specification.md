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

### APP-001: Shipped apps SHALL provide full installable-PWA posture in public custom-domain mode

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Public custom-domain mode is the canonical full-PWA posture.

In public custom-domain mode, shipped OurBox apps SHALL be installable PWAs with service-worker-backed assets and reopen-offline behavior after first successful load.

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

### APP-004: Apps SHALL operate within mode-aware tenant origins

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Tenant origins define storage isolation and routing in both access modes.

Shipped apps SHALL be served under mode-aware tenant origins:
- `http://<tenant_id>.local/<app_slug>` in local-only mode
- `https://<tenant_id>.<box-host>/<app_slug>` in public custom-domain mode

Across both modes, tenant context is derived from the leftmost DNS label of the full host.

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

### APP-007: Local-only mode documentation SHALL NOT claim equivalent full installable-PWA behavior

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Local-only mode is HTTP-only and does not guarantee public-mode installability/reopen-offline behavior.

OurBox documentation and app-facing requirement text for local-only mode SHALL NOT claim full installable-PWA or reopen-offline guarantees equivalent to public custom-domain mode.

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

### DATA-008: Local tenant replicas SHALL be origin-split across access modes

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Browser origin rules isolate local storage by scheme+host+port.

For the same tenant and browser, `http://<tenant_id>.local` and `https://<tenant_id>.<box-host>` SHALL be treated as different origins and therefore different local tenant replicas.

## Gateway and Identity

These requirements define tenant routing, identity enforcement, and the gateway surface used by
clients and shipped apps.

### GW-001: Gateway SHALL derive tenant context from the full host

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Tenant host is the canonical routing and identity boundary.

The gateway SHALL derive `tenant_id` from the leftmost DNS label of the full host and treat that tenant context as authoritative.

### GW-002: Gateway SHALL enforce tenant membership

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Ensures user access is scoped to the tenant origin.

The gateway SHALL enforce that authenticated users are members of the tenant implied by the hostname
before allowing access to tenant-scoped services.

### GW-003: Replication endpoints SHALL be same-origin in both access modes

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Browser clients replicate without CORS or topology leakage.

The gateway SHALL expose same-origin replication at `/db` on the tenant origin in both modes:
- `http://<tenant_id>.local/db`
- `https://<tenant_id>.<box-host>/db`

Clients SHALL NOT require internal CouchDB endpoints.

### GW-010: Gateway SHALL support HTTP tenant-host routing in local-only mode

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Local-only mode requires tenant-host routing without TLS.

In local-only mode, the gateway SHALL serve HTTP tenant hosts using `<tenant_id>.local` routing and same-origin path surfaces.

### GW-011: Local-only tenant hosts SHALL be HTTP-only

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Local-only access mode is intentionally HTTP-only.

In local-only mode, tenant hosts (`<tenant_id>.local`) SHALL be served over HTTP and SHALL NOT be documented as TLS/HTTPS transport endpoints.

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

### K8S-002: Gateway ingress SHALL support public custom-domain wildcard routing

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** Public custom-domain tenant hosts rely on wildcard routing.

For public custom-domain mode, ingress configuration SHALL support wildcard host routing for `*.<box-host>`.

### K8S-003: Shipped app workloads SHOULD use dedicated namespaces

**Status:** Draft  
**Testable:** false  
**Area:** k8s  
**Rationale:** Separates app operations while keeping tenant boundaries intact.

Shipped app workload bundles SHOULD run in their own Kubernetes namespaces to simplify operations
and isolation from platform services.

### K8S-010: Ingress SHALL support local-only tenant-host routing

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** Local-only mode requires mode-specific host routing.

Ingress/gateway configuration SHALL support local-only HTTP tenant-host routing for `<tenant_id>.local` and MAY expose reserved local landing host `ourbox.local`.
