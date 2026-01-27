# OurBox OS Specification
*Version:* 0.1 (Draft)
*Status:* Draft
*Last Updated:* 2026-01-27

This specification is an early, intentionally small set of normative requirements derived from:
- architecture docs ([[arch_doc:SAD-0001]])
- decisions ([[adr:ADR-0001]]..[[adr:ADR-0004]])

It is compiled from GraphMD records into `SPEC.md`.

## Normative language

Keywords **MUST**, **MUST NOT**, **SHOULD**, **SHOULD NOT**, and **MAY** are interpreted in the usual RFC sense.

## Application requirements (offline-first PWAs)

Applies to shipped first-party OurBox apps.

### APP-001 — Shipped apps MUST be offline-first PWAs

Shipped apps MUST be installable PWAs and MUST remain usable when the box is unreachable after first successful load.

Derived from [[adr:ADR-0001]].

### APP-002 — Apps MUST persist working data locally via the local tenant replica

Apps MUST read/write user data against the per-origin local tenant replica (PouchDB/IndexedDB) and MUST support offline create/update/delete for the doc kinds they own.

Derived from [[adr:ADR-0001]] and [[adr:ADR-0002]].

### APP-003 — Apps under the same tenant origin MUST share one local tenant replica

All shipped apps served under the same tenant origin MUST use the same local tenant replica so they see the same documents offline.

Derived from [[adr:ADR-0001]] and [[arch_doc:SAD-0001]].

### APP-004 — Apps MUST replicate opportunistically using the tenant’s same-origin /db endpoint

Apps MUST replicate opportunistically and incrementally with `https://<tenant_id>.<box-host>/db` and MUST NOT require knowledge of CouchDB ports or internal topology.

Derived from [[arch_doc:SAD-0001]].

### APP-005 — Apps MUST treat doc kinds as shared contracts and MUST NOT write outside intended doc kinds

Because apps share a tenant-local store, shipped apps MUST treat doc kinds as shared contracts and MUST NOT perform accidental cross-doc-kind writes. Enforcement is by engineering discipline and testing, not browser sandboxing.

Derived from [[adr:ADR-0001]].

### APP-006 — Apps MUST NOT rely on _id ordering as time ordering

Apps MUST NOT use document `_id` ordering as a proxy for time ordering. If ordering matters, apps MUST store explicit fields and index accordingly.

Derived from [[adr:ADR-0004]].

## Data and replication requirements (CouchDB/PouchDB)

Applies to tenant DBs, local tenant replicas, and document modeling.

### DATA-001 — Each tenant MUST have exactly one CouchDB tenant DB

Each tenant MUST map to exactly one CouchDB database (the tenant DB). Replication is whole tenant DB ↔ tenant DB.

Derived from [[adr:ADR-0002]] and [[arch_doc:SAD-0001]].

### DATA-002 — Tenant DBs MUST be partitioned databases

All tenant DBs MUST be created in partitioned mode, and the partition key MUST be the doc kind.

Derived from [[adr:ADR-0002]].

### DATA-003 — Application documents MUST use _id = <doc_kind>:<uuidv4>

Application documents MUST use `_id = "<doc_kind>:<uuidv4>"`. `doc_kind` MUST be derived from `_id` only. ULIDs MUST NOT be used as document identifiers.

Derived from [[adr:ADR-0004]].

### DATA-004 — Shipped apps MUST model user entities as one document per entity

Shipped apps MUST use one document per user-editable entity (note/task/contact/event/etc.). Aggregating many independent entities into one giant document is forbidden.

Derived from [[adr:ADR-0002]].

### DATA-005 — Large blobs MUST NOT be stored as CouchDB attachments by default

Large blobs (photos/video/audio/etc.) MUST be stored outside CouchDB by default, and documents MUST store references/hashes to those blobs.

Derived from [[adr:ADR-0002]].

### DATA-006 — Replication MUST be treated as sync, not backup

Replication MUST be treated as availability/synchronization, not backup. Operational backup/retention is a separate concern.

Derived from [[arch_doc:SAD-0001]] and [[adr:ADR-0002]].

## Gateway and identity requirements

Applies to tenant-origin routing, authn/z, and replication endpoint mediation.

### GW-001 — Tenant context MUST be derived from hostname (tenant origin)

Tenant context MUST be derived from the request hostname using tenant-in-hostname:
`https://<tenant_id>.<box-host>/...`

Derived from [[adr:ADR-0003]] and [[arch_doc:SAD-0001]].

### GW-002 — Gateway MUST mediate CouchDB access via same-origin /db mapping

Gateway MUST expose the tenant replication endpoint as `/db` on the tenant origin and MUST map it to the correct tenant DB internally. Clients MUST NOT select arbitrary CouchDB database names directly.

Derived from [[arch_doc:SAD-0001]].

### GW-003 — Gateway MUST enforce tenant membership and authorization per request

Gateway MUST enforce that the authenticated user is a member of the tenant implied by hostname and MUST enforce authorization (roles/capabilities) for the requested action.

Derived from [[arch_doc:SAD-0001]] and [[adr:ADR-0003]].

## Kubernetes and deployment requirements

Applies to k3s/kubernetes operational partitioning and ingress requirements.

### K8S-001 — Kubernetes namespaces MUST NOT be used as tenant boundaries

Tenants are data boundaries and MUST NOT be modeled primarily as Kubernetes namespaces. Kubernetes namespaces are operational partitions only.

Derived from [[adr:ADR-0003]] and [[arch_doc:SAD-0001]].

### K8S-002 — Ingress MUST support wildcard host routing for *.<box-host>

Ingress/gateway MUST support wildcard host routing for `*.<box-host>` so tenant origins route correctly.

Derived from [[arch_doc:SAD-0001]].

### K8S-003 — TLS MUST be terminated at the gateway for tenant subdomains

TLS MUST be terminated at the gateway for tenant subdomains. Tenant origins MUST be served over HTTPS in production posture.

Derived from [[arch_doc:SAD-0001]].
