# SRS-0205: Tenant Blob Store Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-01-31
**Status:** Draft

This specification defines the software requirements for the on-box **tenant blob store** (tenant-scoped, content-addressed blob payload storage outside CouchDB). It is a minimal scaffold; detailed requirements live in section records and the authoritative Glossary.

## Normative Language

Normative keywords (SHALL, SHALL NOT, SHOULD, SHOULD NOT, MAY) are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Product and architecture terms used in this SRS (including **blob**, **tenant blob store**, **tenant storage root**, and **content-addressed storage (CAS)**) are defined in the OurBox OS Glossary.

- Vocabulary authority: `docs/architecture/Glossary.md` (normative for terminology)
- Normative keywords (SHALL/SHOULD/MAY): `docs/00-Glossary/Terms-and-Definitions.md`

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
- `docs/architecture/Glossary.md`
- [[spec:SyRS-0001]]
- [[arch_doc:AD-0001]]
- [[adr:ADR-0002]]
- [[adr:ADR-0005]]
- [[adr:ADR-0006]]
- [[spec:SRS-0201]]
- [[spec:SRS-0202]]

## Requirements

Allocated system requirements from `[[spec:SyRS-0001]]` are included here for traceability; blob-store-specific requirements follow.

### DATA-001: Each tenant SHALL have exactly one tenant DB and one tenant blob store

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Tenant DBs are the replication unit; tenant blob stores provide tenant-scoped blob payload storage.

OurBox SHALL maintain one CouchDB database per tenant, named using the `tenant_<tenant_id>` pattern.

OurBox SHALL maintain one tenant blob store per tenant for blob payload bytes stored outside CouchDB. The tenant blob store uses a tenant-scoped storage root (ADR-0006).

### DATA-006: Blobs SHALL be stored outside CouchDB by default

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Large binary content should not be default CouchDB attachments; tenant-scoped blob stores enable legible tenant operations.

Large binary assets (photos/video/audio) SHALL be stored outside CouchDB by default in the tenant blob store (one blob store per tenant), with references stored in application documents.

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

Client-visible interfaces for blob upload/download (if any) will be specified via future ICDs and mediated by the Gateway and/or platform services.

## Verification

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:
- **Inspection:** blob store layout under the tenant storage root follows the deterministic scheme.
- **Test:** write blob payload bytes, reference them from a document, and confirm retrieval under tenant context.
