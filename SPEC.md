# OurBox OS Specification

- Version: 0.1 (Draft)
- Last Updated: 2026-01-27
- Status: Draft

This specification is an early, intentionally small set of normative requirements derived from:
- architecture docs ([[arch_doc:SAD-0001]])
- decisions ([[adr:ADR-0001]]..[[adr:ADR-0004]])

It is compiled from GraphMD records into `SPEC.md`.

## Normative Language

This specification uses **MUST**, **SHOULD**, and **MAY** as defined in RFC 2119.
Requirements are grouped by application behavior, data and replication, gateway/identity,
and Kubernetes/deployment posture.

## Application Requirements

This section defines requirements for shipped OurBox applications, including offline-first
behavior, tenant origin usage, and shared local data posture.

### APP-001: Shipped apps MUST be offline-first PWAs

Shipped OurBox apps MUST be installable PWAs that remain functional after the first successful load
when the box is unreachable.

- Testable: Yes
- Status: Draft
- Rationale: ADR-0001 defines the offline-first posture for shipped apps.

### APP-002: Shipped apps MUST persist working data locally

Shipped OurBox apps MUST persist working data locally in the browser using PouchDB/IndexedDB.

- Testable: Yes
- Status: Draft
- Rationale: Local persistence is required for offline-first behavior.

### APP-003: Apps under a tenant origin MUST share the local tenant replica

All shipped apps served under the same tenant origin MUST read and write through the same local
PouchDB database for that tenant origin on a given device.

- Testable: Yes
- Status: Draft
- Rationale: ADR-0002 requires one local tenant replica per device + tenant origin.

### APP-004: Shipped apps MUST run under tenant origins

Shipped OurBox apps MUST be served from tenant-scoped origins of the form
`https://<tenant_id>.<box-host>/<app_slug>`.

- Testable: Yes
- Status: Draft
- Rationale: Tenant origin isolation is the primary browser boundary.

### APP-005: Shipped apps MUST replicate via the tenant-scoped /db endpoint

Shipped OurBox apps MUST replicate with the tenant database using the same-origin `/db` endpoint
for their tenant origin.

- Testable: Yes
- Status: Draft
- Rationale: Replication is same-origin and tenant-scoped per SAD-0001.

### APP-006: Shipped apps MUST support offline writes for core doc kinds

Each shipped OurBox app MUST support offline create/update/delete for the doc kinds it owns on day one.

- Testable: Yes
- Status: Draft
- Rationale: ADR-0001 requires offline create/update/delete for shipped apps.

## Data and Replication

This section defines requirements for tenant databases, document identity, replication, and
storage of large blobs.

### DATA-001: Each tenant MUST have exactly one tenant DB

Each tenant MUST have exactly one CouchDB tenant database named using the `tenant_<tenant_id>`
pattern.

- Testable: Yes
- Status: Draft
- Rationale: ADR-0002 defines DB-per-tenant.

### DATA-002: Tenant DBs MUST be partitioned

All tenant databases MUST be created as CouchDB partitioned databases.

- Testable: Yes
- Status: Draft
- Rationale: Partitioned DBs enforce doc kind boundaries.

### DATA-003: Document kinds MUST be encoded in _id

Application documents MUST use `_id = "<doc_kind>:<doc_uuid>"` and derive `doc_kind` from `_id` only.

- Testable: Yes
- Status: Draft
- Rationale: ADR-0004 defines doc kind as the partition key.

### DATA-004: Document UUIDs MUST be UUIDv4

Document UUIDs MUST be UUIDv4 strings; ULIDs are prohibited as OurBox document identifiers.

- Testable: Yes
- Status: Draft
- Rationale: ADR-0004 prohibits ULIDs and requires UUIDv4.

### DATA-005: Replication MUST be whole tenant DB

Replication MUST be performed as whole tenant DB replication between the local tenant replica and
the tenant CouchDB database.

- Testable: Yes
- Status: Draft
- Rationale: ADR-0002 defines tenant DB replication as the default unit.

### DATA-006: Large blobs MUST NOT be stored as CouchDB attachments by default

Large binary blobs (photos, video, audio) MUST be stored outside CouchDB by default, with documents
storing references or hashes to the blob content.

- Testable: Partial
- Status: Draft
- Rationale: ADR-0002 requires blobs stored outside CouchDB by default.

## Gateway and Identity

This section defines requirements for tenant routing, gateway enforcement, and identity context.

### GW-001: Gateway MUST derive tenant context from hostname

The gateway MUST derive tenant context from the request hostname and enforce tenant membership for
authenticated users.

- Testable: Yes
- Status: Draft
- Rationale: Tenant context is derived from hostname per SAD-0001.

### GW-002: Gateway MUST map /db to the tenant CouchDB database

The gateway MUST map `https://<tenant_id>.<box-host>/db` to the corresponding tenant database and
MUST NOT require clients to know internal CouchDB ports or database names.

- Testable: Yes
- Status: Draft
- Rationale: Replication must remain same-origin and tenant-scoped.

### GW-003: Gateway MUST present stable tenant-scoped endpoints

The gateway MUST provide stable tenant-scoped endpoints for app assets, replication, and APIs.

- Testable: Yes
- Status: Draft
- Rationale: Stable endpoints reduce client coupling to internal topology.

## Kubernetes and Deployment

This section defines requirements for k3s namespace usage, ingress posture, and deployment routing.

### K8S-001: Tenants MUST NOT be represented as Kubernetes namespaces

Tenants MUST NOT be represented as Kubernetes namespaces; namespaces are reserved for operational
workload grouping only.

- Testable: Yes
- Status: Draft
- Rationale: ADR-0003 reserves namespace for Kubernetes only.

### K8S-002: Ingress MUST support wildcard tenant host routing

Ingress/gateway routing MUST support wildcard host routing for `*.<box-host>`.

- Testable: Yes
- Status: Draft
- Rationale: Tenant routing requires host-based wildcard support.

### K8S-003: Ingress MUST route app, db, and api paths

Ingress/gateway routing MUST support paths for app assets (`/<app_slug>`), replication (`/db`), and
service APIs (`/api/...`).

- Testable: Yes
- Status: Draft
- Rationale: Path routing is required for apps, replication, and APIs.
