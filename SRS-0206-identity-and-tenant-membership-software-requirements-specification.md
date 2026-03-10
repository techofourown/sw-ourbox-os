# SRS-0206: Identity and Tenant Membership Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-01-31
**Status:** Draft

This specification defines the software requirements for OurBox OS identity primitives and tenant membership (user_id, tenant_id, membership, roles/capabilities, and authorization inputs). It is a minimal scaffold; detailed requirements live in section records and the authoritative Glossary.

## Normative Language

Normative keywords (SHALL, SHALL NOT, SHOULD, SHOULD NOT, MAY) and OurBox OS product/architecture vocabulary are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

## Introduction

This SRS defines requirements for identity and tenant membership posture in OurBox OS.

Scope includes:
- identifier constraints for `tenant_id` and `user_id`
- tenant membership as the authorization gate at the tenant boundary
- authorization decision inputs (user identity + tenant context + membership + roles/capabilities)

Out of scope:
- gateway routing and ingress mechanics (see `[[spec:SRS-0201]]`)
- token formats, header names, and session mechanics (defined by contract artifacts and enforced by tests; not specified in this SRS)
- UI flows for login/tenant management (not specified here)

## Referenced Documents

- `docs/00-Glossary/Terms-and-Definitions.md`
- [[spec:SyRS-0001]]
- [[arch_doc:AD-0001]]
- [[adr:ADR-0003]]
- [[spec:SRS-0201]]

## Requirements

Identity requirements derive tenant context from the leftmost DNS label of the full host in both modes.
`tenant_id` constraints are DNS-label-safe and mode-neutral.

### ID-001: user_id SHALL be unique and stable within an OurBox instance

**Status:** Draft  
**Testable:** true  
**Area:** identity  
**Rationale:** Glossary defines `user_id` uniqueness and stability expectations for legible identity across tenants.

Within an OurBox instance, `user_id` SHALL be unique.

`user_id` SHOULD be treated as stable/immutable once created. Renaming a `user_id` is a migration and SHALL be explicit.

`user_id` values are not reusable by default.

`user_id` SHALL be safe for use in URLs, logs, and configuration.

**Trace:** `docs/00-Glossary/Terms-and-Definitions.md` (user_id)

### ID-003: display_name SHALL NOT be used as an identifier

**Status:** Draft  
**Testable:** true  
**Area:** identity  
**Rationale:** Glossary states display_name is presentation-only and must not be treated as identity.

`display_name` is presentation-only and SHALL NOT be used as an identifier.

**Trace:** `docs/00-Glossary/Terms-and-Definitions.md` (display_name)

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

This SRS does not define token formats, cookie names, header names, or claim shapes.

Concrete identity/session wire formats and internal identity-context propagation are defined as versioned contract artifacts
(e.g., OpenAPI security schemes and/or JSON schemas) and are enforced by automated tests.

## Verification

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:
- **Inspection:** identifier rules for `tenant_id` and `user_id` are enforced consistently.
- **Test:** membership gating prevents cross-tenant access when hostnames differ.
