# ADR-0005: Standardize on Tenant as the OurBox OS Data Boundary Term

## Status
Accepted (Updated)

## Date
2026-01-25

## Deciders
Founder (initial); future Board + Members (ratification/amendment per `docs/policies/founding/CONSTITUTION.md`)

## Context

OurBox OS is an offline-first, browser-first system (ADR-0003). We have adopted CouchDB + PouchDB as
the primary data store for shipped apps and standardized data modeling around tenant DBs and partitions (ADR-0004, ADR-0006).

We need a single, canonical word for the top-level boundary that:

- scopes data (which tenant DB are we operating on?)
- scopes access rules (who/app can read/write in this tenant?)
- scopes replication targets (what replicates where?)
- appears across the stack:
  - app code (PWAs)
  - gateway identity context
  - CouchDB tenant DB naming
  - k3s service configuration and logs

We will not maintain separate “internal” and “user-facing” terms for the same concept. One concept
gets one word.

### Naming constraints (non-negotiable)

- **“Namespace” is reserved for k3s/Kubernetes.**
  Kubernetes namespaces are already a fundamental operational concept. Reusing “namespace” for our
  data boundary would create constant ambiguity in code, docs, and tooling.

- We are **not** using “profile” or “account” for this boundary.
  Those words commonly refer to identity/login concepts and blur the line between:
  - who you are (user identity), and
  - which tenant DB you are operating on (data boundary).

- We prioritize **legacy, industry-understood words** over inventing new terms.
  Our codebase and docs must be understandable to database designers, systems engineers, and
  automated assistants.

This ADR records the choice of word and its meaning inside OurBox OS.

---

## Decision

### We will use the word **tenant** as the single canonical term for the top-level data boundary in OurBox OS.

#### Definition (normative)

A **tenant** is the top-level data boundary that scopes:

- **Data**
  - All application data belongs to exactly one tenant.
  - Each tenant has exactly one **tenant DB** (ADR-0004).

- **Access rules**
  - Access checks are evaluated in a tenant context.

- **Replication targets**
  - Replication targets are tenant DBs (tenant DB ↔ tenant DB).

A **tenancy** is the set of one or more tenants hosted on a single OurBox instance.

#### Clarification (Operator Truth)

Tenant boundaries are not a claim of confidentiality from the device operator.

- The device operator (physical/root/update control) can access anything on the device if they choose to.
- Tenant boundaries exist to keep normal product behavior correct and legible.
- Tenants are an everyday boundary, not a hostile-admin security boundary.

---

## Normative design rules

1) **Use tenant everywhere**
   - In code, docs, APIs, and user-facing UI strings, the boundary is called tenant.
   - Do not introduce alternate terms for this boundary.

2) **Reserved words**
   - “Namespace” refers only to k3s/Kubernetes namespaces.
   - “Profile” and “account” are not used for the tenant boundary.

3) **Identifiers**
   - The canonical identifier is `tenant_id`.
   - User identity is `user_id`.
   - Membership and roles are defined in the Terms doc and enforced by the gateway.

4) **Tenant origin (hostname)**
   - Tenant context is derived from hostname:
     - `https://<tenant_id>.<box-host>/...`
   - Tenant origins are distinct browser origins and provide storage/cache isolation on shared devices.

5) **Tenant DB naming**
   - Each tenant has one CouchDB database:
     - `tenant_<tenant_id>`
   - `tenant_id` tokens used in database names must be lowercase and safe for CouchDB database naming.

6) **k3s services**
   - OurBox app workloads may use one Kubernetes namespace per app (operational hygiene).
   - Tenants are not expressed as Kubernetes namespaces.
   - Tenant context is carried via gateway-injected identity context and enforced by platform services.

---

## Rationale

- Tenant is the industry-standard term for the primary boundary for scoping data and isolation policy.
- Namespace already has a strong meaning in k3s/Kubernetes; reusing it would cause constant ambiguity.
- Stable vocabulary reduces implementation mistakes, documentation drift, and debugging friction.
- Tenant-in-hostname aligns tenant boundaries with the web’s native origin boundary.

## Consequences

### Positive
- One word, one concept, everywhere.
- Clear mental model for tenant DB replication and access control.
- Reduced confusion in a k3s-based system where namespace already has a strong meaning.

### Negative
- Tenant can sound enterprise/SaaS-flavored to some users.

### Mitigation
- Provide a one-sentence plain-language explanation wherever UI introduces the term:
  - “A tenant is the data boundary that your apps sync with on this box.”

## References
- ADR-0003: Purpose-build Offline‑First PWAs for All Shipped OurBox Apps
- ADR-0004: Adopt CouchDB + PouchDB and Standardize OurBox Data Modeling (Tenant DBs + Partitions)
- ADR-0006: OurBox Document IDs
- `docs/policies/founding/VALUES.md`
- `docs/policies/founding/CONSTITUTION.md`
- `docs/architecture/OurBox-OS-Terms-and-Definitions.md`
