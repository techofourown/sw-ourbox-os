# ADR-0004: OurBox Document IDs

## Status
Accepted

## Date
2026-01-25

## Deciders
Founder (initial); future Board + Members (ratification/amendment per `docs/policies/founding/CONSTITUTION.md`)

## Context

OurBox OS shipped apps are offline-first PWAs (ADR-0001) that persist locally in the browser
(PouchDB/IndexedDB) and sync to the box (CouchDB) via replication (ADR-0002).

ADR-0002 establishes a “CouchDB way” posture:

- **DB per tenant** (a single tenant DB per tenant)
- tenant DBs are **partitioned databases** (CouchDB partitions feature)
- each user-editable entity is **one document per entity**
- the **document kind** is derived from `_id` only (no separate `doc_type` field)
- multiple apps may operate on the same document kinds (e.g., SimpleNote + RichNote both operate on notes)

This ADR defines the **canonical, forever** scheme for OurBox application document identifiers.

### Why an explicit document-id scheme matters

In CouchDB/PouchDB, the unit of read/write, replication, and conflict is the **document revision**.
The `_id` is the document’s identity across all devices and replicas. If `_id` structure is not
standardized, the system quickly becomes inconsistent, hard to debug, and hard to compose across apps.

We explicitly reject time-encoding identifiers (e.g., ULIDs) as an implicit sort key. If ordering
matters, it must be represented explicitly in document fields—never smuggled into IDs.

## Decision

OurBox application documents use a canonical `_id` scheme:

_id = "<doc_kind>:<doc_uuid>"

Where:

- `doc_kind` is the **CouchDB partition key** and the canonical document kind identifier
- `doc_uuid` is a **UUIDv4** string

ULIDs are prohibited as document identifiers.

## Normative design rules

### 1) Scope
1. This ADR applies to **OurBox application documents** stored and replicated via PouchDB ↔ CouchDB.
2. CouchDB system documents are not governed by this scheme:
   - design documents: `_design/...`
   - local (non-replicated) documents: `_local/...`

### 2) Tenant DBs are partitioned databases
1. Each tenant has exactly one CouchDB database: the **tenant DB** (ADR-0002).
2. Each tenant DB SHALL be created as a **partitioned database**.
3. Every application document SHALL have a partition key in `_id` (i.e., SHALL match `<doc_kind>:<doc_uuid>`).

### 3) `doc_kind` is canonical and lives only in `_id`
1. `doc_kind` SHALL be derived only from `_id` (the substring before the first `:`).
2. Apps and services SHALL NOT store a second “doc kind/type” source of truth (no `doc_type` field).
3. `doc_kind` SHALL be stable vocabulary. Renaming a `doc_kind` token is a migration.

#### `doc_kind` grammar (normative)
- `doc_kind` SHALL match: `^[a-z][a-z0-9_-]*$`
- `doc_kind` SHALL NOT start with `_` (reserved by CouchDB conventions)
- `doc_kind` SHALL NOT contain `:` (colon is the separator)

#### Initial stable doc-kind vocabulary (normative for shipped apps)
- `note`
- `task`
- `contact`
- `event`
- `meta`

### 4) `doc_uuid` SHALL be UUIDv4
1. `doc_uuid` SHALL be a UUID **version 4** string (RFC 4122).
2. UUID string representation SHALL be canonical:
   - lowercase hex
   - 8-4-4-4-12 with hyphens
3. `doc_uuid` SHALL be generated without coordination and SHALL work offline (browser-first).

### 5) ULIDs are prohibited as document identifiers
1. ULIDs SHALL NOT be used as `doc_uuid`.
2. ULIDs SHALL NOT be used as a primary identifier for OurBox application documents.
3. If ULIDs appear in imported external data fields, they are treated as opaque external values only and SHALL NOT become `_id`.

### 6) Meta documents
1. `meta` is a doc kind, not a special escape hatch.
2. Meta documents are application documents and SHALL follow the same `_id` scheme:
   - `_id = "meta:<uuidv4>"`
3. If a specific meta document needs to be uniquely retrievable by purpose (e.g., “settings”, “schema version”),
   that purpose SHALL be represented as explicit document fields and/or indexes.
   - Example pattern (informative): `{ meta_key: "settings", ... }`

### 7) Replication ramifications (normative posture)
1. Replication is **whole tenant DB ↔ whole tenant DB** (ADR-0002). OurBox does not require selective replication by partition.
2. Partitions are used to:
   - enforce doc-kind vocabulary via `_id`
   - keep doc kinds legible and queryable
   - support partition-scoped access patterns where useful
3. Because replication and conflict resolution are document-based, the One-Document-Per-Entity rule (ADR-0002) remains critical:
   - document boundary = conflict boundary

### 8) Ordering and “implicit meaning” rules
1. Applications SHALL NOT use `_id` ordering as a proxy for time ordering.
2. If ordering matters (recent notes, tasks by due date), ordering SHALL be represented explicitly in fields and indexed appropriately.
3. IDs remain semantically opaque aside from `doc_kind`.

## Examples

### Tenant DBs
- `tenant_bob` (partitioned database)
- `tenant_alice` (partitioned database)

### Documents inside Bob’s tenant DB
- Notes (shared by SimpleNote + RichNote):
  - `note:550e8400-e29b-41d4-a716-446655440000`
  - `note:2b6f2c6d-8f0f-4b79-bc58-2e6c2d277a2b`
- Tasks:
  - `task:3f1b3a92-947f-4f0d-9baf-72a3dfcb4a3c`
- Contacts:
  - `contact:4d21aa0f-2c6a-4e2a-a89b-f1dcf2b73df0`
- Events:
  - `event:aa01b3c0-10ad-4c61-9ac7-4bb9f2e70c2f`
- Meta:
  - `meta:9b6b4b1a-4ff5-4b38-83a7-8d6c2f1dd6aa` with `meta_key: "settings"`

### How two apps share the same notes
- `/simplenote` and `/richnote` both operate on documents with `_id` prefix `note:`
- Neither app “owns” the notes; the doc kind does.

## Rationale

- CouchDB/PouchDB identity and replication revolve around `_id`. Standardizing it early eliminates ambiguity.
- Using CouchDB partitioned databases makes `doc_kind` first-class and enforceable.
- UUIDv4 provides offline-safe uniqueness without embedding time semantics.
- ULIDs invite accidental coupling between “identifier” and “sort key,” which conflicts with OurBox’s “explicit fields for semantics” posture.
- The scheme is legible, stable, and composes across apps (SimpleNote/RichNote sharing notes).

## Consequences

### Positive
- One canonical, enforceable document-id structure across all shipped apps.
- Doc kind is single-source-of-truth (no duplicated type fields).
- IDs do not encode time semantics; ordering is explicit and inspectable.
- Shared doc kinds across apps become straightforward and robust.

### Negative
- Renaming doc kinds is a migration (new `_id`s).
- “Singleton” meta concepts require a query/index strategy rather than a named `_id`.

### Mitigation
- Keep the initial doc-kind vocabulary intentionally stable.
- Define doc-kind-specific indexing/query posture where needed (Mango and/or views are allowed by ADR-0002).
- Keep meta usage narrow and explicit.

## References
- ADR-0001: Purpose-build Offline‑First PWAs for All Shipped OurBox Apps
- ADR-0002: Adopt CouchDB + PouchDB and Standardize OurBox Data Modeling (Tenant DBs + Partitions)
- ADR-0003: Standardize on Tenant as the OurBox OS Data Boundary Term
- `docs/architecture/Glossary.md`
