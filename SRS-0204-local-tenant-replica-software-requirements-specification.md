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
