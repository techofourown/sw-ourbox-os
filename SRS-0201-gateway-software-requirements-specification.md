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
**Rationale:** Tenant origins are the canonical boundary.

The gateway SHALL derive `tenant_id` from the leftmost DNS label of the request full host and treat it as the authoritative tenant context.

### GW-002: Gateway SHALL enforce tenant membership

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Ensures user access is scoped to the tenant origin.

The gateway SHALL enforce that authenticated users are members of the tenant implied by the full host
before allowing access to tenant-scoped services.

### GW-003: Replication endpoints SHALL be same-origin and mode-aware

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Browser clients must replicate without CORS or topology leakage.

The gateway SHALL expose same-origin replication at `/db` on tenant origins in both modes:
- local-only mode: `http://<tenant_id>.local/db`
- public custom-domain mode: `https://<tenant_id>.<box-host>/db`

Clients SHALL NOT be required to know internal CouchDB endpoints.

### K8S-002: Gateway ingress SHALL support public custom-domain wildcard tenant hosts

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** Public custom-domain tenant hosts rely on wildcard routing.

Ingress configuration for public custom-domain mode SHALL support wildcard host routing for `*.<box-host>`.

### K8S-010: Gateway routing SHALL support local-only tenant hosts over HTTP

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** Local-only mode requires explicit HTTP host routing for tenant hosts.

Gateway routing configuration SHALL support local-only tenant hosts `<tenant_id>.local` over HTTP.

Gateway routing MAY also expose a reserved local landing host such as `ourbox.local`.

### GW-005: Gateway SHALL terminate TLS for public custom-domain tenant hosts

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Public custom-domain mode is HTTPS/TLS while local-only mode remains HTTP-only.

For public custom-domain mode tenant hosts (`<tenant_id>.<box-host>`), TLS SHALL be terminated at the gateway.

**Trace:** [[arch_doc:AD-0001]] §5.4.2

### GW-010: Gateway SHALL serve local-only tenant hosts over HTTP

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Local-only mode requires explicit HTTP tenant-host service posture.

For local-only mode tenant hosts (`<tenant_id>.local`), the gateway SHALL serve tenant-origin traffic over HTTP.

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

### GW-007: Gateway SHALL map `/db` on tenant origins to tenant DBs

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Clients replicate same-origin without knowing CouchDB topology or database names.

The gateway/reverse proxy maps tenant-origin replication endpoints to CouchDB database `tenant_<tenant_id>`:

- local-only mode: `http://<tenant_id>.local/db` → `tenant_<tenant_id>`
- public custom-domain mode: `https://<tenant_id>.<box-host>/db` → `tenant_<tenant_id>`

Clients SHALL NOT select arbitrary CouchDB database names directly.

**Trace:** [[arch_doc:AD-0001]] §4.5–§4.6

### GW-008: CouchDB SHALL be exposed externally only through the tenant origin as a tenant-scoped surface

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Reduce exposed surface area while preserving CouchDB replication posture.

CouchDB is exposed externally only through the tenant origin as a tenant-scoped surface (same-origin), not as a raw CouchDB node endpoint.

**Trace:** [[arch_doc:AD-0001]] §4.5

### GW-009: Gateway SHALL treat full-host-derived tenant context as authoritative

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Prevent tenant confusion and parameter spoofing when full host is present.

When full host is present, `tenant_id` SHALL be derived from the leftmost DNS label of the request full host and SHALL NOT be accepted from untrusted client parameters as the primary authority.

**Trace:** [[arch_doc:AD-0001]] §6.2

## External Interfaces

Gateway external interfaces are tenant-origin HTTP/HTTPS surfaces in two access modes:
- local-only mode tenant hosts: `<tenant_id>.local` over HTTP
- optional local landing host: `ourbox.local` over HTTP
- public custom-domain tenant hosts: `*.<box-host>` over HTTPS/TLS
- app paths: `/<app_slug>`
- replication path: `/db`
- API paths: `/api/...` (when present)

Same-origin replication endpoints are:
- `http://<tenant_id>.local/db`
- `https://<tenant_id>.<box-host>/db`

The authoritative definition of these external surfaces (host routing, paths, routing objects, and service bindings)
is the versioned deployment baseline (rendered Kubernetes manifests) and the running cluster state, verified by
conformance/integration tests (see ADR-0008).

## Verification

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture for this SRS:
- **Inspection:** confirm Gateway configuration supports wildcard hosts and path routing shapes (K8S-002, GW-005, GW-006).
- **Test:** automated integration tests that validate hostname→tenant mapping and membership gating (GW-001..GW-003, GW-007..GW-009).
- Evidence artifacts (test outputs, config snapshots, and release manifests) will be linked here as they are produced.
