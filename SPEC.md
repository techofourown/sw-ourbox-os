# OurBox OS Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-01-27
**Status:** Draft

This specification is an early, intentionally small set of normative requirements derived from:
- architecture docs ([[arch_doc:SAD-0001]])
- decisions ([[adr:ADR-0001]]..[[adr:ADR-0004]])

It is compiled from GraphMD records into `SPEC.md`.

## 0 Normative Language

This document uses RFC 2119-style keywords. The terms MUST, MUST NOT, SHOULD, SHOULD NOT, and MAY are to be interpreted as described in RFC 2119.

## 1 Application Requirements

These requirements define the baseline behavior for shipped OurBox apps (PWAs) in tenant contexts.

### APP-001: Shipped apps MUST be offline-first PWAs

**Requirement ID:** APP-001
**Status:** Draft
**Area:** app
**Rationale:** ADR-0001 posture requires offline-first PWA behavior.

Shipped OurBox apps MUST be installable PWAs and remain usable after the first successful load without requiring network connectivity.

### APP-002: Shipped apps MUST use the local tenant replica

**Requirement ID:** APP-002
**Status:** Draft
**Area:** app
**Rationale:** Shared tenant-local storage enables cross-app composition.

Within a tenant origin, shipped apps MUST read/write through the single local tenant replica (PouchDB/IndexedDB).

### APP-003: Shipped apps MUST support offline writes for their doc kinds

**Requirement ID:** APP-003
**Status:** Draft
**Area:** app
**Rationale:** Offline-first posture requires local persistence without connectivity.

Each shipped app MUST support create, update, and delete operations for its document kinds while offline.

### APP-004: Shipped apps MUST replicate opportunistically

**Requirement ID:** APP-004
**Status:** Draft
**Area:** app
**Rationale:** Replication must tolerate intermittent connectivity.

Shipped apps MUST attempt incremental, resumable replication when connectivity is available, without requiring manual triggers.

### APP-005: Shipped apps MUST use tenant-origin endpoints

**Requirement ID:** APP-005
**Status:** Draft
**Area:** app
**Rationale:** Tenant isolation is enforced via origins and gateway routing.

Shipped apps MUST access replication and APIs through same-origin endpoints under https://<tenant_id>.<box-host>/.

### APP-006: Shipped apps SHOULD cache core assets for offline use

**Requirement ID:** APP-006
**Status:** Draft
**Area:** app
**Rationale:** Offline usage requires cached assets and service worker support.

Shipped apps SHOULD pre-cache essential assets via service workers to enable offline startup after first load.

## 2 Data and Replication

These requirements define the canonical data modeling and replication posture for OurBox OS.

### DATA-001: Each tenant MUST have exactly one tenant DB

**Requirement ID:** DATA-001
**Status:** Draft
**Area:** data
**Rationale:** Tenant DBs are the replication unit for the platform.

OurBox OS MUST provision exactly one CouchDB tenant DB per tenant and use it as the system-of-record.

### DATA-002: Tenant DBs MUST be partitioned databases

**Requirement ID:** DATA-002
**Status:** Draft
**Area:** data
**Rationale:** Partitioned DBs enforce doc-kind vocabulary and access patterns.

Each tenant DB MUST be created in CouchDB partitioned mode, with doc kind as the partition key.

### DATA-003: Document kind MUST be derived from _id only

**Requirement ID:** DATA-003
**Status:** Draft
**Area:** data
**Rationale:** Doc kind is single-source-of-truth in the ID structure.

Applications MUST derive doc kind from the _id prefix and MUST NOT store a separate doc type field.

### DATA-004: Document IDs MUST use UUIDv4 suffixes

**Requirement ID:** DATA-004
**Status:** Draft
**Area:** data
**Rationale:** UUIDv4 enables offline-safe ID creation.

Application documents MUST use _id = "<doc_kind>:<uuidv4>" with UUIDv4 identifiers.

### DATA-005: Large blobs MUST NOT be stored as CouchDB attachments by default

**Requirement ID:** DATA-005
**Status:** Draft
**Area:** data
**Rationale:** Blob storage is external to CouchDB in the default posture.

Large binary content MUST be stored outside CouchDB by default, with documents referencing blobs by hash or ID.

### DATA-006: Replication MUST be tenant DB to tenant DB

**Requirement ID:** DATA-006
**Status:** Draft
**Area:** data
**Rationale:** Whole-DB replication is the default posture.

Replication MUST operate on the full tenant DB between local tenant replicas and CouchDB.

## 3 Gateway and Identity

These requirements define how tenant context and identity are derived and enforced at the gateway.

### GW-001: Gateway MUST derive tenant context from hostname

**Requirement ID:** GW-001
**Status:** Draft
**Area:** gateway
**Rationale:** Tenant isolation relies on hostname-derived origins.

The gateway MUST derive tenant_id from the request hostname and enforce membership before granting access.

### GW-002: Gateway MUST map /db to the tenant DB

**Requirement ID:** GW-002
**Status:** Draft
**Area:** gateway
**Rationale:** Clients should not need internal CouchDB topology.

The gateway MUST map https://<tenant_id>.<box-host>/db to CouchDB database tenant_<tenant_id>.

### GW-003: Gateway MUST expose tenant-scoped CouchDB endpoints only

**Requirement ID:** GW-003
**Status:** Draft
**Area:** gateway
**Rationale:** CouchDB admin surfaces should not be exposed to clients.

The gateway MUST expose CouchDB replication endpoints only through tenant-scoped same-origin routes.

## 4 Kubernetes and Deployment

These requirements define the baseline k3s/ingress posture needed for OurBox OS.

### K8S-001: Kubernetes namespaces MUST NOT be treated as tenants

**Requirement ID:** K8S-001
**Status:** Draft
**Area:** k8s
**Rationale:** Tenant boundaries are data boundaries, not operational namespaces.

Kubernetes namespaces MUST be used for operational partitioning and MUST NOT define tenant boundaries.

### K8S-002: Ingress MUST support wildcard tenant hosts

**Requirement ID:** K8S-002
**Status:** Draft
**Area:** k8s
**Rationale:** Tenant routing depends on wildcard hostnames.

Ingress/gateway configuration MUST support wildcard host routing for *.<box-host> tenant subdomains.

### K8S-003: Gateway MUST terminate TLS for tenant subdomains

**Requirement ID:** K8S-003
**Status:** Draft
**Area:** k8s
**Rationale:** TLS termination at the gateway is required for tenant origins.

The gateway MUST terminate TLS for tenant subdomains before routing to internal services.
