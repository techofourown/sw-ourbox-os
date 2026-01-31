# SRS-0201: Gateway Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-01-31
**Status:** Draft

This specification defines the software requirements for the Gateway software item. It is a minimal scaffold; detailed requirements live in section records and the authoritative Glossary.

## Normative Language

Normative keywords (SHALL, SHALL NOT, SHOULD, SHOULD NOT, MAY) are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Product and architecture terms used in this SRS (including **Gateway**, **tenant**, **tenant_id**, **tenant origin**, and **tenant DB**) are defined in the OurBox OS Glossary.

- Vocabulary authority: `docs/architecture/Glossary.md` (normative for terminology)
- Normative keywords (SHALL/SHOULD/MAY): `docs/00-Glossary/Terms-and-Definitions.md`

## Introduction

This SRS defines the requirements for the **Gateway** software item.

The Gateway is the **front door for HTTP(S) traffic** to an OurBox instance. It is responsible for tenant-scoped routing and policy enforcement, including exposing a stable same-origin replication surface for CouchDB while also routing app and API traffic under tenant origins.

This SRS intentionally remains a minimal scaffold, but it includes the Gateway requirements already established in:
- `[[spec:SyRS-0001]]` (system requirements allocated to the Gateway), and
- `[[arch_doc:AD-0001]]` (normative architecture invariants and routing posture).

## Referenced Documents

- `docs/00-Glossary/Terms-and-Definitions.md`
- `docs/architecture/Glossary.md`
- [[spec:SyRS-0001]]
- [[arch_doc:AD-0001]]
- [[adr:ADR-0001]]
- [[adr:ADR-0002]]
- [[adr:ADR-0003]]
- [[adr:ADR-0004]]
- [[spec:SRS-0206]]

## Requirements

Allocated system requirements from `[[spec:SyRS-0001]]` are included here for traceability; Gateway-specific requirements follow.

### GW-001: Gateway SHALL derive tenant context from hostname

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Tenant origins are the canonical boundary.

The gateway SHALL derive `tenant_id` from the request hostname and treat it as the authoritative
tenant context.

### GW-002: Gateway SHALL enforce tenant membership

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Ensures user access is scoped to the tenant origin.

The gateway SHALL enforce that authenticated users are members of the tenant implied by the hostname
before allowing access to tenant-scoped services.

### GW-003: Replication endpoints SHALL be same-origin

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Browser clients must replicate without CORS or topology leakage.

The gateway SHALL expose replication at `/db` on the tenant origin and SHALL NOT require clients to
know internal CouchDB endpoints.

### GW-004: Gateway ingress SHALL support wildcard tenant hosts

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Tenant origins rely on hostname routing.

Ingress/gateway SHALL support wildcard host routing for `*.<box-host>` to enable tenant subdomains.

**Trace:** [[arch_doc:AD-0001]] §5.4.2

### GW-005: TLS SHALL be terminated at the gateway for tenant subdomains

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Tenant origins are HTTPS surfaces; clients should not depend on internal service TLS topologies.

TLS SHALL be terminated at the gateway for tenant subdomains.

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

### GW-007: Gateway SHALL map `/db` on the tenant origin to the tenant DB in CouchDB

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Clients replicate same-origin without knowing CouchDB topology or database names.

The gateway/reverse proxy maps:

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

### GW-009: Gateway SHALL treat hostname-derived tenant context as authoritative

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Prevent tenant confusion and parameter spoofing when hostname is present.

When hostname is present, `tenant_id` SHALL be derived from the request hostname and SHALL NOT be accepted from untrusted client parameters as the primary authority.

**Trace:** [[arch_doc:AD-0001]] §6.2

## External Interfaces

Gateway external interfaces are HTTP(S) surfaces on tenant origins, including:
- wildcard tenant hosts: `*.<box-host>`
- app paths: `/<app_slug>`
- replication path: `/db`
- API paths: `/api/...` (when present)

Identity context propagation to internal services (headers/claims/etc.) SHALL be specified in a future Interface Control Document (ICD). This SRS does not define header names or token formats.

## Verification

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture for this SRS:
- **Inspection:** confirm Gateway configuration supports wildcard hosts and path routing shapes (GW-004..GW-006).
- **Test:** automated integration tests that validate hostname→tenant mapping and membership gating (GW-001..GW-003, GW-007..GW-009).
- Evidence artifacts (test outputs, config snapshots, and release manifests) will be linked here as they are produced.
