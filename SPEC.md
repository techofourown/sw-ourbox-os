# OurBox OS Specification
**Version:** 0.1 (Draft)
**Last Updated:** 2026-01-27
**Status:** Draft

This specification is an early, intentionally small set of normative requirements derived from:
- architecture docs ([[arch_doc:SAD-0001]])
- decisions ([[adr:ADR-0001]]..[[adr:ADR-0004]])

It is compiled from GraphMD records into `SPEC.md`.

# 0. Normative Language

The key words **MUST**, **MUST NOT**, **REQUIRED**, **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**,
**RECOMMENDED**, **MAY**, and **OPTIONAL** are to be interpreted as described in RFC 2119.

Unless explicitly marked “informative,” all requirements in this specification are normative.

# 1. Application Requirements

This section defines application-level requirements for shipped OurBox OS apps and their offline-first posture.

## APP-001: Shipped apps are offline-first PWAs

**Status:** Draft
**Testable:** true
**Area:** app
**Rationale:** Offline-first posture is core to OurBox OS (ADR-0001).

Shipped OurBox OS apps MUST be installable Progressive Web Apps that continue to run from cached
assets after the first successful load.

## APP-002: Apps persist working data locally

**Status:** Draft
**Testable:** true
**Area:** app
**Rationale:** Offline-first behavior requires durable local storage.

Shipped apps MUST persist working data locally using IndexedDB-backed storage (PouchDB by default).

## APP-003: Apps replicate opportunistically

**Status:** Draft
**Testable:** true
**Area:** app
**Rationale:** Replication is incremental and tolerant of intermittent connectivity.

Shipped apps MUST attempt incremental, resumable replication with the tenant database whenever
connectivity is available.

## APP-004: Apps are served under tenant origins

**Status:** Draft
**Testable:** true
**Area:** app
**Rationale:** Tenant origins provide the web storage boundary.

Shipped apps MUST be served under a tenant origin and addressed as a path beneath that origin
(e.g., `https://<tenant_id>.<box-host>/<app_slug>`).

## APP-005: Apps share a local tenant replica

**Status:** Draft
**Testable:** true
**Area:** app
**Rationale:** Shared local data enables multi-app workflows offline.

All shipped apps served under the same tenant origin MUST use the same local tenant replica on a
client device.

## APP-006: Offline writes are supported for core doc kinds

**Status:** Draft
**Testable:** true
**Area:** app
**Rationale:** Shipped apps must support offline creation, updates, and deletion.

Every shipped app MUST support offline create, update, and delete flows for the document kinds it
writes on day one.

# 2. Data and Replication

This section defines requirements for tenant databases, document identifiers, and replication behavior.

## DATA-001: One tenant DB per tenant

**Status:** Draft
**Testable:** true
**Area:** data
**Rationale:** Tenant DBs are the primary data boundary.

Each tenant MUST have exactly one CouchDB tenant database on the box.

## DATA-002: Tenant DBs are partitioned

**Status:** Draft
**Testable:** true
**Area:** data
**Rationale:** Partitioned DBs make doc kind a first-class invariant.

All tenant databases MUST be created as CouchDB partitioned databases.

## DATA-003: Document IDs follow doc_kind:uuidv4

**Status:** Draft
**Testable:** true
**Area:** data
**Rationale:** Stable identifiers are required for replication and conflict handling.

Application documents MUST use `_id = "<doc_kind>:<uuidv4>"` and MUST NOT use ULIDs.

## DATA-004: Document kind is derived only from _id

**Status:** Draft
**Testable:** true
**Area:** data
**Rationale:** Avoid multiple sources of truth for doc kind.

Apps and services MUST derive `doc_kind` exclusively from the `_id` prefix and MUST NOT store a
secondary doc kind field.

## DATA-005: Replication is tenant DB ↔ tenant DB

**Status:** Draft
**Testable:** true
**Area:** data
**Rationale:** Whole-DB replication is the default sync unit.

Replication MUST operate on whole tenant databases (local tenant replica ↔ tenant DB) rather than
selective partition replication.

## DATA-006: Large blobs are stored outside CouchDB

**Status:** Draft
**Testable:** true
**Area:** data
**Rationale:** Large binaries should not be CouchDB attachments by default.

Large binary content MUST be stored outside CouchDB by default, with documents referencing blobs
via metadata or content hashes.

# 3. Gateway and Identity

This section defines requirements for tenant-origin routing, gateway enforcement, and identity context.

## GW-001: Gateway derives tenant context from hostname

**Status:** Draft
**Testable:** true
**Area:** gateway
**Rationale:** Hostname-derived tenant context enforces origin isolation.

The gateway MUST derive `tenant_id` from the request hostname and MUST treat that value as the
authoritative tenant context.

## GW-002: Gateway enforces tenant membership

**Status:** Draft
**Testable:** true
**Area:** gateway
**Rationale:** Tenant access requires membership checks.

The gateway MUST enforce that authenticated users are members of the tenant implied by the request
hostname before granting access to tenant-scoped resources.

## GW-003: Replication is exposed at /db

**Status:** Draft
**Testable:** true
**Area:** gateway
**Rationale:** Clients should not need CouchDB topology details.

The gateway MUST expose tenant replication at `/db` on the tenant origin and map it to the tenant
CouchDB database.

# 4. Kubernetes and Deployment

This section defines requirements for k3s deployment boundaries and ingress behavior.

## K8S-001: Kubernetes namespaces are not tenant boundaries

**Status:** Draft
**Testable:** true
**Area:** k8s
**Rationale:** Tenant is the canonical data boundary, not a k8s namespace.

Kubernetes namespaces MUST NOT be used as the primary representation of tenant boundaries.

## K8S-002: Ingress supports wildcard tenant routing

**Status:** Draft
**Testable:** true
**Area:** k8s
**Rationale:** Tenant subdomains require wildcard host routing.

Ingress/gateway infrastructure MUST support wildcard host routing for `*.<box-host>`.

## K8S-003: TLS terminates at the gateway

**Status:** Draft
**Testable:** true
**Area:** k8s
**Rationale:** Tenant origins require TLS termination at the edge.

TLS for tenant subdomains MUST terminate at the gateway or ingress layer before routing requests
internally.
