# SRS-0206: Identity and Tenant Membership Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-01-31
**Status:** Draft

This specification defines the software requirements for OurBox OS identity primitives and tenant membership (user_id, tenant_id, membership, roles/capabilities, and authorization inputs). It is a minimal scaffold; detailed requirements live in section records and the authoritative Glossary.

## Normative Language

Normative keywords (SHALL, SHALL NOT, SHOULD, SHOULD NOT, MAY) are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Product and architecture terms used in this SRS (including **Tenant**, **tenant_id**, **User**, **user_id**, **tenant membership**, **role**, and **capability**) are defined in the OurBox OS Glossary.

- Vocabulary authority: `docs/architecture/Glossary.md` (normative for terminology)
- Normative keywords (SHALL/SHOULD/MAY): `docs/00-Glossary/Terms-and-Definitions.md`

## Introduction

This SRS defines requirements for identity and tenant membership posture in OurBox OS.

Scope includes:
- identifier constraints for `tenant_id` and `user_id`
- tenant membership as the authorization gate at the tenant boundary
- authorization decision inputs (user identity + tenant context + membership + roles/capabilities)

Out of scope:
- gateway routing and ingress mechanics (see `[[spec:SRS-0201]]`)
- token formats, header names, and session mechanics (future ICDs)
- UI flows for login/tenant management (not specified here)

## Referenced Documents

- `docs/00-Glossary/Terms-and-Definitions.md`
- `docs/architecture/Glossary.md`
- [[spec:SyRS-0001]]
- [[arch_doc:AD-0001]]
- [[adr:ADR-0003]]
- [[spec:SRS-0201]]

## Requirements

Allocated requirements are included here for traceability; identity- and membership-specific requirements follow.

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

### GW-009: Gateway SHALL treat hostname-derived tenant context as authoritative

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Prevent tenant confusion and parameter spoofing when hostname is present.

When hostname is present, `tenant_id` SHALL be derived from the request hostname and SHALL NOT be accepted from untrusted client parameters as the primary authority.

**Trace:** [[arch_doc:AD-0001]] §6.2

### ID-001: user_id SHALL be unique and stable within an OurBox instance

**Status:** Draft  
**Testable:** true  
**Area:** identity  
**Rationale:** Glossary defines `user_id` uniqueness and stability expectations for legible identity across tenants.

Within an OurBox instance, `user_id` SHALL be unique.

`user_id` SHOULD be treated as stable/immutable once created. Renaming a `user_id` is a migration and SHALL be explicit.

`user_id` values are not reusable by default.

`user_id` SHALL be safe for use in URLs, logs, and configuration.

**Trace:** `docs/architecture/Glossary.md` (user_id)

### ID-002: tenant_id SHALL satisfy hostname and CouchDB naming constraints

**Status:** Draft  
**Testable:** true  
**Area:** identity  
**Rationale:** Glossary defines tenant_id constraints required for tenant origins and tenant DB naming.

`tenant_id` SHALL be lowercase.

`tenant_id` SHALL be safe for use in DNS labels (tenant subdomains).

`tenant_id` SHALL be safe for use in CouchDB database names.

**Trace:** `docs/architecture/Glossary.md` (tenant_id)

### ID-003: display_name SHALL NOT be used as an identifier

**Status:** Draft  
**Testable:** true  
**Area:** identity  
**Rationale:** Glossary states display_name is presentation-only and must not be treated as identity.

`display_name` is presentation-only and SHALL NOT be used as an identifier.

**Trace:** `docs/architecture/Glossary.md` (display_name)

### ID-004: Authorization SHALL consider user identity, tenant context, and tenant-scoped roles/capabilities

**Status:** Draft  
**Testable:** true  
**Area:** identity  
**Rationale:** AD-0001 defines the normative authorization decision inputs at the tenant boundary.

Authorization SHALL consider:
- authenticated user identity (`user_id`)
- tenant derived from hostname (`tenant_id`)
- membership and roles/capabilities within that tenant
- any doc-kind-specific rules where applicable

**Trace:** [[arch_doc:AD-0001]] §6.3

## External Interfaces

External interfaces for identity/session/token propagation will be specified via future ICDs.

This SRS does not define token formats, cookie names, header names, or claim shapes.

## Verification

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:
- **Inspection:** identifier rules for `tenant_id` and `user_id` are enforced consistently.
- **Test:** membership gating prevents cross-tenant access when hostnames differ.
