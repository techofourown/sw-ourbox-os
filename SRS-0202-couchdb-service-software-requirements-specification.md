# SRS-0202: CouchDB Service Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-01-31
**Status:** Draft

This specification defines the software requirements for the on-box **CouchDB service** (system-of-record for tenant DBs). It is a minimal scaffold; detailed requirements live in section records and the authoritative Glossary.

## Normative Language

Normative keywords (SHALL, SHALL NOT, SHOULD, SHOULD NOT, MAY) are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Product and architecture terms used in this SRS (including **CouchDB**, **tenant**, **tenant_id**, **tenant DB**, **tenant blob store**, and **replication**) are defined in the OurBox OS Glossary.

- Vocabulary authority: `docs/architecture/Glossary.md` (normative for terminology)
- Normative keywords (SHALL/SHOULD/MAY): `docs/00-Glossary/Terms-and-Definitions.md`

## Introduction

This SRS defines requirements for the **on-box CouchDB service**, which acts as the tenant-scoped system-of-record and replication target.

Scope includes:
- tenant DB creation and naming posture (`tenant_<tenant_id>`)
- partitioned database posture and `_id` scheme
- replication posture at the database level (tenant DB ↔ tenant DB)
- on-box blob-store posture insofar as it is part of the tenant storage contract

Out of scope:
- gateway routing, `/db` mapping, and host/path policy (see `[[spec:SRS-0201]]`)
- client local replicas and PouchDB behavior (see `[[spec:SRS-0204]]`)

This SRS is intentionally a minimal scaffold, but it pulls in the already-established requirements from:
- `[[spec:SyRS-0001]]` (system requirements for data/replication), and
- `[[arch_doc:AD-0001]]` (architecture invariants for storage/replication posture).

## Referenced Documents

- `docs/00-Glossary/Terms-and-Definitions.md`
- `docs/architecture/Glossary.md`
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

## Requirements

Allocated system requirements from `[[spec:SyRS-0001]]` are included here for traceability; CouchDB-service-specific requirements follow.

### DATA-001: Each tenant SHALL have exactly one tenant DB and one tenant blob store

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Tenant DBs are the replication unit; tenant blob stores provide tenant-scoped blob payload storage.

OurBox SHALL maintain one CouchDB database per tenant, named using the `tenant_<tenant_id>` pattern.

OurBox SHALL maintain one tenant blob store per tenant for blob payload bytes stored outside CouchDB. The tenant blob store uses a tenant-scoped storage root (ADR-0006).

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

Precise service-to-service interface details (ports, auth, internal URLs) will be specified via future ICDs.

## Verification

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:
- **Inspection:** tenant DB naming, partitioned mode configuration, and blob-store posture.
- **Test:** replication between a client and the box using the tenant DB as the unit of replication.
