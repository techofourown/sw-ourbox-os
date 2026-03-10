# SRS-0201: Gateway Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-01-31
**Status:** Draft

This specification defines the software requirements for the Gateway software item. It is a minimal scaffold; detailed requirements live in section records and the authoritative Glossary.

## Normative Language

Normative keywords (SHALL, SHALL NOT, SHOULD, SHOULD NOT, MAY) and OurBox OS product/architecture vocabulary are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

## Introduction

This SRS defines the requirements for the **Gateway** software item.

The Gateway is the **front door for HTTP(S) traffic** to an OurBox instance. It is responsible for tenant-scoped routing and policy enforcement, including exposing a stable same-origin replication surface for CouchDB while also routing app and API traffic under tenant origins.

This SRS intentionally remains a minimal scaffold, but it includes the Gateway requirements already established in:
- `[[spec:SyRS-0001]]` (system requirements allocated to the Gateway), and
- `[[arch_doc:AD-0001]]` (normative architecture invariants and routing posture).

## Referenced Documents

- `docs/00-Glossary/Terms-and-Definitions.md`
- [[spec:SyRS-0001]]
- [[arch_doc:AD-0001]]
- [[adr:ADR-0001]]
- [[adr:ADR-0002]]
- [[adr:ADR-0003]]
- [[adr:ADR-0004]]
- [[spec:SRS-0206]]

## Requirements

Gateway requirements are mode-aware:
- TLS requirements apply to public custom-domain mode.
- Local-only tenant-host access is HTTP-only.
- Host routing covers `<tenant_id>.local` and `*.<box-host>`.
- Same-origin `/db` mapping is provided in both modes.

### GW-006: Gateway path routing SHALL support app, replication, and API paths under the tenant origin

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Stable path routing is required for tenant-origin composition.

Path routing SHALL support:
- `/<app_slug>` for app assets
- `/db` for the replication endpoint
- `/api/...` for service APIs (when present)

**Trace:** [[arch_doc:AD-0001]] §5.4.2

### GW-008: CouchDB SHALL be exposed externally only through the tenant origin as a tenant-scoped surface

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Reduce exposed surface area while preserving CouchDB replication posture.

CouchDB is exposed externally only through the tenant origin as a tenant-scoped surface (same-origin), not as a raw CouchDB node endpoint.

**Trace:** [[arch_doc:AD-0001]] §4.5

### GW-009: Gateway SHALL treat hostname-derived tenant context as authoritative

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Prevent tenant confusion and parameter spoofing when hostname is present.

When hostname is present, `tenant_id` SHALL be derived from the request hostname and SHALL NOT be accepted from untrusted client parameters as the primary authority.

**Trace:** [[arch_doc:AD-0001]] §6.2

## External Interfaces

Gateway tenant-facing interfaces:
- local-only app route pattern: `http://<tenant_id>.local/<app_slug>`
- public app route pattern: `https://<tenant_id>.<box-host>/<app_slug>`
- local-only replication endpoint: `http://<tenant_id>.local/db`
- public replication endpoint: `https://<tenant_id>.<box-host>/db`
- replication path: `/db`

## Verification

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture for this SRS:
- **Inspection:** confirm Gateway configuration supports wildcard hosts and path routing shapes (K8S-002, GW-005, GW-006).
- **Test:** automated integration tests that validate hostname→tenant mapping and membership gating (GW-001..GW-003, GW-007..GW-009).
- Evidence artifacts (test outputs, config snapshots, and release manifests) will be linked here as they are produced.
