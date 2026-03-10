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

Allocated system requirements from `[[spec:SyRS-0001]]` are included here for traceability; Gateway-specific requirements follow.

### GW-001: Gateway SHALL derive tenant context from the full host

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Tenant routing is host-derived across both access modes.

The gateway SHALL derive `tenant_id` from the leftmost DNS label of the request full host and treat it as authoritative tenant context.

### GW-002: Gateway SHALL enforce tenant membership

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Ensures user access is scoped to the tenant origin.

The gateway SHALL enforce that authenticated users are members of the tenant implied by the full host
before allowing access to tenant-scoped services.

### GW-003: Replication endpoints SHALL be same-origin in both access modes

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Browser clients replicate without CORS/topology leakage in local-only and public custom-domain modes.

The gateway SHALL expose replication at `/db` on the tenant origin in both modes:
- `http://<tenant_id>.local/db`
- `https://<tenant_id>.<box-host>/db`

Clients SHALL NOT require internal CouchDB endpoints.

### K8S-002: Public custom-domain ingress SHALL support wildcard tenant hosts

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** Public tenant-host routing relies on wildcard full-host matching.

For public custom-domain mode, ingress configuration SHALL support wildcard host routing for `*.<box-host>`.

### GW-005: Gateway SHALL terminate TLS in public custom-domain mode

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Public tenant hosts are HTTPS/TLS surfaces.

In public custom-domain mode, TLS SHALL be terminated at the gateway for `*.<box-host>` tenant hosts.

**Trace:** [[arch_doc:AD-0001]] §5.4.2

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

### GW-007: Gateway SHALL map `/db` on tenant origins to tenant DBs in both modes

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Clients replicate same-origin without knowing CouchDB topology or database names.

The gateway/reverse proxy maps:
- `http://<tenant_id>.local/db` → CouchDB database `tenant_<tenant_id>`
- `https://<tenant_id>.<box-host>/db` → CouchDB database `tenant_<tenant_id>`

Clients SHALL NOT select arbitrary CouchDB database names directly.

**Trace:** [[arch_doc:AD-0001]] §4.5–§4.6

### GW-008: CouchDB SHALL be exposed externally only through the tenant origin as a tenant-scoped surface

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Reduce exposed surface area while preserving CouchDB replication posture.

CouchDB is exposed externally only through the tenant origin as a tenant-scoped surface (same-origin), not as a raw CouchDB node endpoint.

**Trace:** [[arch_doc:AD-0001]] §4.5

### GW-009: Gateway SHALL treat full host-derived tenant context as authoritative

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Prevent tenant confusion and parameter spoofing when full host is present.

When full host is present, `tenant_id` SHALL be derived from the request full host and SHALL NOT be accepted from untrusted client parameters as the primary authority.

**Trace:** [[arch_doc:AD-0001]] §6.2

### GW-010: Gateway SHALL serve HTTP tenant hosts in local-only mode

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Local-only mode requires HTTP routing for `<tenant_id>.local`.

In local-only mode, the gateway SHALL route HTTP requests for tenant hosts matching `<tenant_id>.local` and MAY expose `ourbox.local` for local landing flows.

## External Interfaces

Gateway external interfaces are mode-aware tenant-origin surfaces:
- local-only mode tenant hosts: `<tenant_id>.local` over HTTP
- optional local landing host: `ourbox.local` over HTTP
- public custom-domain tenant hosts: `*.<box-host>` over HTTPS/TLS
- app paths: `/<app_slug>`
- replication path: `/db`
- API paths: `/api/...` (when present)

## Verification

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture for this SRS:
- **Inspection:** confirm Gateway configuration supports wildcard hosts and path routing shapes (K8S-002, GW-005, GW-006).
- **Test:** automated integration tests that validate full host→tenant mapping and membership gating (GW-001..GW-003, GW-007..GW-009).
- Evidence artifacts (test outputs, config snapshots, and release manifests) will be linked here as they are produced.
