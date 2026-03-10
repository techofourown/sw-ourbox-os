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

RichNote external interfaces are tenant-origin app/replication surfaces in both access modes.

- App route (local-only mode): `http://<tenant_id>.local/richnote`
- App route (public custom-domain mode): `https://<tenant_id>.<box-host>/richnote`
- Replication endpoint (local-only mode): `http://<tenant_id>.local/db`
- Replication endpoint (public custom-domain mode): `https://<tenant_id>.<box-host>/db`
- Local storage: shared local tenant replica `tenant_local` within the current tenant origin

Public custom-domain mode is the full installable-PWA posture. Local-only mode remains HTTP local mode with local data continuity and opportunistic sync, without equivalent full installability/reopen-offline guarantees.

## Verification

Verification provisions (methods, environments, and trace links to evidence) will be defined here.
Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.
