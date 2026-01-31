# OurBox OS Requirements Omnibus


## Included Specifications
- SyRS-0001-ourbox-os-system-requirements-specification.md (source: spec:SyRS-0001)
- SRS-0201-gateway-software-requirements-specification.md (source: spec:SRS-0201)
- SRS-0202-couchdb-service-software-requirements-specification.md (source: spec:SRS-0202)
- SRS-0203-k3s-platform-contract-software-requirements-specification.md (source: spec:SRS-0203)
- SRS-0204-local-tenant-replica-software-requirements-specification.md (source: spec:SRS-0204)
- SRS-0205-tenant-blob-store-software-requirements-specification.md (source: spec:SRS-0205)
- SRS-0206-identity-and-tenant-membership-software-requirements-specification.md (source: spec:SRS-0206)
- SRS-1001-simplenote-software-requirements-specification.md (source: spec:SRS-1001)
- SRS-1002-richnote-software-requirements-specification.md (source: spec:SRS-1002)

---

# Terms and Definitions

## Purpose
This document defines standard systems and software engineering terms and acronyms used across
requirements, architecture, design, and verification artifacts.

**Rule:** one concept gets one term. Avoid ambiguous synonyms.

---

## Normative keywords
The following keywords indicate requirement strength when used in requirements specifications:

- **SHALL**: mandatory requirement.
- **SHALL NOT**: mandatory prohibition.
- **SHOULD**: recommended; valid reasons may exist to deviate, but the reasons must be understood and documented.
- **SHOULD NOT**: recommended prohibition; valid reasons may exist to deviate, but the reasons must be understood and documented.
- **MAY**: optional; permitted but not required.

---

## Acronyms
| Acronym | Term |
|---|---|
| AD | Architecture Description |
| ADR | Architecture Decision Record |
| API | Application Programming Interface |
| BRS | Business Requirements Specification |
| ConOps | Concept of Operations |
| COTS | Commercial Off-The-Shelf |
| DoD | Department of Defense |
| E2E | End-to-End |
| FMEA | Failure Modes and Effects Analysis |
| FTA | Fault Tree Analysis |
| HLR | High-Level Requirement |
| ICD | Interface Control Document |
| IDD | Interface Design Description |
| I/O | Input/Output |
| KPI | Key Performance Indicator |
| LLR | Low-Level Requirement |
| MBSE | Model-Based Systems Engineering |
| NFR | Non-Functional Requirement |
| QA | Quality Attribute |
| RAM | Reliability, Availability, Maintainability |
| RFC | Request for Comments |
| RTM | Requirements Traceability Matrix |
| SDD | Software Design Description |
| SDR | System Design Review |
| SRS | Software Requirements Specification |
| StRS | Stakeholder Requirements Specification |
| SyRS | System Requirements Specification |
| T&E | Test and Evaluation |
| TBD | To Be Determined |
| TBR | To Be Reviewed |
| TRR | Test Readiness Review |
| V&V | Verification and Validation |
| VCD | Verification Cross-Reference (or Compliance) Document |
| VVP | Verification and Validation Plan |
| VVTR | Verification and Validation Test Report |

---

## Definitions

### Acceptance criteria
Objective, measurable conditions that must be satisfied for a deliverable, feature, or requirement
to be considered complete and acceptable.

### Allocation
Assignment of a system-level requirement to one or more system elements (e.g., subsystems,
components, software items) responsible for satisfying it.

### Assumption
A statement accepted as true for planning or design purposes. Assumptions should be explicitly
identified because they can become risks if invalid.

### Architecture
The fundamental concepts or properties of a system in its environment embodied in its elements,
relationships, and the principles of its design and evolution.

### Architecture Description (AD)
A work product that expresses an architecture for specific stakeholders and concerns using one or
more views (and associated viewpoints).

### Architecture Decision Record (ADR)
A lightweight record of a significant architectural decision, including context, decision, and
consequences.

### Baseline
A formally agreed set of configuration items (including documents, code, and other artifacts) that
serves as the basis for further development and can be changed only through controlled change
procedures.

### Business requirement
A statement of a business objective, outcome, or value the system is intended to deliver.

### Business Requirements Specification (BRS)
A specification of business requirements and business-level constraints and objectives.

### Capability
A named ability or function the system provides, typically described at an operational level.

### Change control
A defined process for proposing, evaluating, approving, implementing, and documenting changes to
baselined artifacts.

### Component
An identifiable part of a system that encapsulates behavior and may be independently replaceable
within a defined architecture. (Also commonly used as “software component.”)

### Concept of Operations (ConOps)
A description of how the system will be used in its operational environment, including operational
scenarios, stakeholders, roles, and constraints.

### Constraint
A restriction that limits design or implementation choices (e.g., mandated technologies, standards,
interfaces, safety rules, performance ceilings/floors).

### Derived requirement
A requirement that results from analysis, decomposition, or design decisions, and is traceable back
to a parent requirement or stakeholder need.

### Design
The representation of a system element that shows how requirements will be realized, including
structures, interfaces, behaviors, and implementation choices.

### Document identifier
A unique identifier assigned to a document or record to support traceability, configuration
management, and referencing.

### Functional requirement
A requirement that specifies a function, behavior, or capability the system or system element shall
provide.

### Hazard
A system state or set of conditions that, together with a particular set of worst-case environmental
conditions, will lead to an accident or loss event.

### High-Level Requirement (HLR)
A requirement stated at a system or major subsystem level, often emphasizing “what” over detailed
implementation.

### Interface
A shared boundary across which information, control, or physical interaction occurs between system
elements.

### Interface Control Document (ICD)
A controlled document that defines an interface between system elements, including interface
characteristics, constraints, and responsibilities.

### Interface Design Description (IDD)
A design-level description of interfaces, including data structures, protocols, and interaction
details.

### Low-Level Requirement (LLR)
A detailed requirement typically allocated to a specific component or software unit, suitable for
direct implementation and unit verification.

### Non-Functional Requirement (NFR)
A requirement that specifies a quality attribute or constraint (e.g., performance, security,
usability, availability, maintainability, portability) rather than a function.

### Quality attribute (QA)
A measurable or assessable property of a system that affects its quality (e.g., reliability,
usability, performance, security).

### Requirement
A statement that translates or expresses a need and its associated constraints and conditions.
Requirements should be necessary, unambiguous, verifiable, and traceable.

### Requirements Traceability Matrix (RTM)
A matrix (or structured dataset) that links requirements to their sources, allocations, and
verification evidence (e.g., test cases, analyses, inspections).

### Risk
An uncertain event or condition that, if it occurs, has a positive or negative effect on objectives.
Typically characterized by likelihood and consequence (impact).

### Stakeholder
An individual or organization that has a right, share, or interest in the system, or is affected by
the system.

### Stakeholder Requirements Specification (StRS)
A specification capturing stakeholder needs and expectations, including operational scenarios and
constraints, typically preceding or informing system requirements.

### Subsystem
A system element composed of multiple components that together provide a set of capabilities within
the larger system.

### System
A combination of interacting elements organized to achieve one or more stated purposes.

### System element
A member of the set of elements that constitute a system (e.g., subsystem, component, software item,
hardware item, process).

### System Requirements Specification (SyRS)
A specification of system requirements, including functional requirements, quality requirements, and
constraints, with defined verification provisions.

### Software Requirements Specification (SRS)
A specification of software requirements for a software item, including functional requirements,
interfaces, performance, and constraints, with defined verification provisions.

### Software Design Description (SDD)
A description of the software design that defines how software requirements are realized, including
architecture, components, interfaces, data, and key algorithms.

### Traceability
The ability to follow the life of a requirement in both forward and backward directions (from
origins through implementation and verification, and back).

### Validation
Confirmation that the system, as delivered, fulfills stakeholder needs and intended use in the
operational environment (“Are we building the right thing?”).

### Verification
Confirmation that a system element fulfills specified requirements (“Are we building the thing
right?”).

### Verification and Validation (V&V)
The set of activities and artifacts that establish verification (requirements met) and validation
(stakeholder needs met).

### Verification and Validation Plan (VVP)
A plan that defines the V&V approach, responsibilities, environments, methods, and evidence required
to verify and validate requirements.

### Verification methods
Common methods used to verify requirements:
- **Test**: exercising the item with defined procedures and measuring results.
- **Analysis**: using mathematical or logical reasoning, modeling, or simulation.
- **Inspection**: examining artifacts (code, documents, configurations) for correctness.
- **Demonstration**: showing functionality in operation without exhaustive measurement.

### Verification evidence
Artifacts that demonstrate a requirement has been verified (e.g., test results, analysis reports,
inspection records, review minutes).

### View
A representation of an architecture from the perspective of a defined set of concerns.

### Viewpoint
A specification of the conventions for constructing and using a view (e.g., notations, modeling
techniques, analysis methods, and stakeholder concerns addressed).

---

---

# Glossary

## Purpose

This document defines canonical terms used across OurBox OS architecture, ADRs, code, and docs.

**Rule:** one concept gets one term. Avoid overloaded words. In particular:
- “Dataset” is reserved for GraphMD conversations and is not used as an OurBox OS storage term.
- “Domain” is avoided (confusable with DNS domains).
- “Namespace” is reserved for Kubernetes namespaces.

If anything conflicts with this document’s vocabulary, this document wins (for terminology).

## Core terms

### OurBox instance
A single physical/logical OurBox device running OurBox OS.

### OurBox OS
The operating system + platform services shipped on an OurBox instance.

### box-host
The base host name used to address an OurBox instance on a network.

Examples (informative):
- local network name: `ourbox.local` (mDNS-style)
- user-chosen home DNS name: `ourbox.home`
- user-chosen public DNS name: `box.example.com`

OurBox may be deployed on a LAN only or exposed via port forwarding / reverse proxy. This document
does not mandate a deployment posture; it standardizes how names are used.

### origin
A web security boundary defined by `(scheme, host, port)`. Origins isolate:
- IndexedDB and related browser storage,
- Cache Storage,
- service workers.

OurBox uses tenant-in-hostname so each tenant is a distinct origin.

### Operator Truth
The posture that the device operator (physical/root/update control) can access anything on the box
if they choose to, and may be able to exfiltrate content from clients (e.g., from browser storage).
Our boundaries are for correct product behavior and legibility, not hostile-admin confidentiality.

## Identity and boundary terms

### Tenant
The top-level data boundary in OurBox OS (ADR-0003).

- Tenant context scopes data, access checks, and replication targets.
- Each tenant has exactly one **tenant DB** (ADR-0002).

### Tenancy
The set of one or more tenants hosted on a single OurBox instance.

### tenant_id
Stable identifier for a tenant.

Constraints (normative):
- SHALL be lowercase.
- SHALL be safe for use in DNS labels (tenant subdomains).
- SHALL be safe for use in CouchDB database names.

Examples: `bob`, `alice`, `family`, `roommates-2026`

### Tenant origin
A tenant-scoped browser origin derived from hostname:

- `https://<tenant_id>.<box-host>/...`

Tenant origins are distinct web origins and therefore isolate:
- IndexedDB (PouchDB storage)
- Cache Storage (service worker caches)
- service worker scope

This isolation is a core mechanism for safe multi-tenant use on shared devices.

### User
An authenticated actor identity (“who is making this request?”).

- Users may be members of one or more tenants.
- Users and tenants are distinct concepts even if there is a 1:1 personal-tenant default.

### user_id
The canonical identifier for a user identity.

In OurBox OS, `user_id` is a **human-readable handle**.

Normative rules:
- `user_id` SHALL be unique within an OurBox instance.
- `user_id` SHOULD be treated as stable/immutable once created.
  - Renaming a `user_id` is a migration and SHALL be explicit.
- `user_id` values are not reusable by default.
  - If user `joe` leaves a shared box, a future different person must choose a different `user_id`
    (e.g., `joe2`, `joe-smith`).
- `user_id` SHALL be safe for use in URLs, logs, and configuration.
  - Recommended pattern: lowercase DNS-label-ish tokens (letters, numbers, hyphen/underscore), no spaces.

### display_name (optional)
A user-facing string that may contain spaces, capitalization, etc.
`display_name` is presentation-only and SHALL NOT be used as an identifier.

### Tenant membership
A relationship between a user and a tenant that grants capabilities within that tenant context.

### role
A named grouping of capabilities used to evaluate authorization within a tenant context.

Examples (informative): `owner`, `editor`, `viewer`.

### capability
A fine-grained permission used to evaluate authorization within a tenant context.

Examples (informative): `notes:read`, `notes:write`, `tasks:write`.

(OurBox may implement roles as bundles of capabilities.)

## App and deployment terms

### App
A user-facing browser experience (a shipped OurBox PWA) reachable under a tenant origin at an app route.

Apps are experiences. Apps are replaceable. Apps do not define data boundaries.

### shipped app
A first-party OurBox app distributed as part of OurBox OS that SHALL conform to ADR-0001 posture.

### app_slug
The path portion that identifies an app experience under a tenant origin.

Examples: `/simplenote`, `/richnote`, `/tasks`, `/calendar`

### Kubernetes namespace
A Kubernetes/k3s operational partition.

Reserved word (normative): “namespace” refers only to Kubernetes namespaces in OurBox OS documentation.

### App namespace (Kubernetes)
A Kubernetes namespace used for operational grouping of an app’s workloads.

- Recommended: one Kubernetes namespace per shipped app workload bundle.
- Not all Kubernetes namespaces correspond to apps (platform/system namespaces exist).
- Tenants are not Kubernetes namespaces.

## Storage and sync terms

### CouchDB
The document database running on the box, acting as the system-of-record and replication target for shipped apps.

### PouchDB
The document database running in the browser, backed by IndexedDB, acting as the local working store for offline-first apps.

### Tenant DB
A CouchDB database that stores all application documents for one tenant (ADR-0002).

- Recommended naming: `tenant_<tenant_id>` (e.g., `tenant_bob`)
- Replication unit: tenant DB ↔ tenant DB (whole-DB replication is the norm).
- Each tenant also has exactly one tenant blob store used for blob payload bytes outside CouchDB.

### Local tenant replica
The single PouchDB database within a tenant origin that acts as the local replica of the tenant DB.

All shipped apps under the same tenant origin SHALL use the same local tenant replica so they share doc kinds offline.

### Partitioned database (CouchDB partitions)
A CouchDB database created in partitioned mode. In a partitioned database:
- Application document `_id` SHALL be shaped as: `<partitionKey>:<docId>`

### Partition key
The prefix of a partitioned document `_id` before the first `:`.

In OurBox OS, the partition key is the **doc kind**.

### Document
A single JSON object stored in CouchDB/PouchDB. Documents are the atomic unit of:
- read/write
- replication
- conflicts (concurrent edits on the same doc)

### _id
The immutable primary identifier of an application document.

In OurBox OS tenant DBs (ADR-0004):
- `_id = "<doc_kind>:<doc_uuid>"`
- Example: `note:550e8400-e29b-41d4-a716-446655440000`

### doc kind
The canonical document classification used by OurBox OS. It is derived from `_id` only.

Initial stable vocabulary (normative for shipped apps):
- `note`, `task`, `contact`, `event`, `meta`

### doc_uuid
The UUIDv4 portion of `_id` after `<doc_kind>:`.

### _rev (revision)
CouchDB/PouchDB revision identifier for a specific version of a document. Each update produces a new revision.

### conflict
A situation where concurrent edits produce multiple revisions that must be resolved according to policy.

### replication
Incremental, resumable synchronization of documents and revisions between two databases that support the CouchDB replication protocol.

### replication source
The database endpoint from which changes are read during a replication run.

### replication target
The database endpoint to which changes are written during a replication run.

Note: replication targets are not “backups.” Replication can copy deletions and bad changes.

### backup (distinct from replication)
Point-in-time retention (snapshots/archives). Replication is not backup.

## Blob and storage terms

### blob
Large binary content (photos/video/audio/etc.) stored outside CouchDB by default in the **tenant blob store** (one blob store per tenant) (ADR-0002, ADR-0005). Documents store references (e.g., CIDs); the tenant blob store stores payload bytes.

### content-addressed storage (CAS)
A storage approach where blob identifiers are derived from the content (e.g., a hash) rather than a mutable name.

### tenant blob store
A tenant-scoped content-addressed blob store used to store blob payload bytes outside CouchDB.

Normative:
- Each tenant has exactly one tenant blob store on an OurBox instance.
- Blob payload bytes belong to exactly one tenant and are stored in that tenant's blob store.

### tenant storage root
An implementation-chosen filesystem directory or object-store prefix that serves as the root of a tenant's blob store. Blob Paths (ADR-0006) are relative to this root.

## Web platform terms

### Progressive Web App (PWA)
A web application that can be installed and can provide offline capability using web platform features
(e.g., service worker, Cache Storage, IndexedDB).

### service worker
A background script registered by a web app that can intercept network requests and manage offline
caches for an origin/scope.

### IndexedDB
The browser storage API used by PouchDB for local persistence.

## Routing and enforcement

### Gateway
The front door for HTTP(S) traffic to the box, responsible for:
- routing (host + path)
- authentication and authorization enforcement
- deriving tenant context from hostname
- presenting stable endpoints for apps and replication
- injecting validated identity context to internal services

---

## Cross-document rule
All ADRs and architecture docs SHALL use these terms and avoid:
- “dataset” (unless explicitly discussing GraphMD)
- “domain” (unqualified)
- “namespace” for anything other than Kubernetes namespaces

---

# AD-0001: OurBox OS Architecture Description

## Status
Draft (normative unless explicitly marked “informative”)

## Date
2026-01-25

## Related decisions
- ADR-0001: Purpose-build Offline‑First PWAs for All Shipped OurBox Apps
- ADR-0002: Adopt CouchDB + PouchDB and Standardize OurBox Data Modeling (Tenant DBs + Partitions)
- ADR-0003: Standardize on Tenant as the OurBox OS Data Boundary Term
- ADR-0004: OurBox Document IDs
- ADR-0005: Store blobs in a content-addressed blob store keyed by a canonical multihash key (no chunking)
- ADR-0006: Deterministic sharded path layout for blob payloads

## Terminology
- `docs/architecture/Glossary.md` is normative for vocabulary.

---

## 1 Introduction

### 1.1 Purpose
This document defines the high-level system architecture of OurBox OS, including:
- multi-tenant routing and isolation,
- offline-first client architecture,
- tenant DB replication,
- service boundaries,
- deployment and operational constraints for a k3s-based appliance.

It is intended to be a stable reference for implementers, maintainers, and contributors.

### 1.2 Scope
This AD covers:
- shipped first-party apps posture (offline-first PWAs),
- tenant/user/app relationships and how they map to the web platform, CouchDB/PouchDB, and k3s,
- the canonical routing and storage invariants that make multi-tenancy legible.

It does not specify UI flows or user-facing terminology.

### 1.3 Architectural constraints (from ADRs)
- Shipped apps SHALL be offline-first PWAs (ADR-0001).
- CouchDB on the box and PouchDB in the browser SHALL be the primary data store stack for shipped apps (ADR-0002).
- Tenant SHALL be the canonical top-level data boundary term (ADR-0003).
- Kubernetes "namespace" is reserved for Kubernetes; it SHALL NOT be used as a synonym for tenant (ADR-0003).
- Tenant DBs SHALL be partitioned databases; doc kind SHALL be encoded in `_id` (ADR-0002, ADR-0004).
- OurBox application documents SHALL use `_id = "<doc_kind>:<uuidv4>"` (ADR-0004).
- Large blobs SHALL NOT be stored as CouchDB attachments by default (ADR-0002).
- Each tenant SHALL have a tenant-scoped blob store (one blob store per tenant) with a tenant-scoped storage root; blob payload layout is deterministic per ADR-0006.

---

## 2 Architectural drivers

### 2.1 Key quality attributes
- **Offline-first**: apps remain functional when the box is unreachable after first load.
- **Sporadic sync**: sync tolerates intermittent connectivity and resumes incrementally.
- **Mobile-first**: the web experience is the primary distribution mechanism.
- **Multi-tenant correctness**: Bob and Alice can share the same physical devices without accidental tenant mixing.
- **Legibility**: boundaries must be obvious in URLs, logs, and database names.
- **Operational simplicity**: avoid carrying two primary database stacks; avoid custom sync protocols for the v0 posture.

### 2.2 Security posture (Operator Truth)
OurBox does not claim tenant confidentiality from the device operator. Tenants exist to make normal
product behavior correct and understandable.

---

## 3 System context (informative)

### 3.1 Actors
- **User**: authenticates and performs actions.
- **Device operator**: has physical/root/update control over the box (Operator Truth).
- **Client device**: phone/tablet/laptop browser running PWAs, sometimes shared.
- **OurBox instance**: local server hosting gateway, services, CouchDB, and blob/file storage.

### 3.2 Context diagram (informative)

+----------------------+ HTTPS +-------------------------------+
| Browser (PWA) | <----------------> | Gateway (Ingress/Auth/Router) |
| - tenant origin | | - tenant routing by hostname |
| - local tenant | | - membership enforcement |
| replica (PouchDB) | | - stable endpoints |
+----------+-----------+ +-----------+-------------------+
| |
| replication (tenant DB) | internal
v v
+----------------------+ +--------------------------+
| CouchDB | | Platform Services |
| - tenant DBs | | - APIs/workflows |
| - partitioned DBs | | - authz, invariants |
+----------------------+ +--------------------------+
|
v
+----------------------+
| Blob/File Store |
| - CAS blobs outside |
| CouchDB by default |
+----------------------+

---

## 4 Architectural model and invariants (normative)

This section defines “how the system works together” as invariants.

### 4.1 Tenants are addressed as web origins
In web platform terms, an **origin** is the browser security boundary defined by:

- `origin = (scheme, host, port)`

Browsers isolate storage by origin, including:
- IndexedDB (used by PouchDB)
- Cache Storage (used by service workers for offline assets)
- service worker registrations

OurBox encodes `tenant_id` in the hostname so that each tenant is a distinct origin:

- **Canonical pattern:** `https://<tenant_id>.<box-host>/...`

We call this the **tenant origin**.

Rationale:
- Origin-level storage isolation is the web platform’s native boundary.
- Tenant-in-hostname ensures Bob and Alice do not share offline caches or local databases by accident, even on the same physical device.

### 4.2 Apps are addressed as paths under a tenant origin
Apps SHALL live under a path on the tenant origin:

- `https://<tenant_id>.<box-host>/<app_slug>`

Examples:
- `https://bob.<box-host>/simplenote`
- `https://bob.<box-host>/richnote`
- `https://alice.<box-host>/tasks`

Apps are not a data boundary; apps are experiences.

### 4.3 Tenant DBs are the replication unit
Each tenant has exactly one tenant DB on the box:

- CouchDB DB name: `tenant_<tenant_id>`

Each tenant also has exactly one **tenant blob store** for blob payload bytes stored outside CouchDB. The blob store is resolved in tenant context (derived from hostname) and uses a tenant-scoped storage root.

Within that tenant DB:
- the DB is a **partitioned database**
- `doc_kind` is the partition key
- `_id = "<doc_kind>:<uuidv4>"` for application documents

Replication posture:
- replicate tenant DB ↔ tenant DB (whole DB)
- do not require selective replication by partition

### 4.4 Local data is per tenant origin and shared across apps
On each **client device** (phone/tablet/laptop browser), within a given **tenant origin**
(e.g., `https://bob.<box-host>`), the browser SHALL have exactly one PouchDB database that acts as
the tenant’s local working store on that device.

We call this database the **local tenant replica**:

- it is local to that device (IndexedDB-backed via PouchDB)
- it accepts reads/writes while offline
- it replicates opportunistically with the tenant’s CouchDB database on the box (`tenant_<tenant_id>`)

**Scope clarification:** “exactly one” is per *device + browser + tenant origin*.
Bob will therefore have multiple local tenant replicas across his devices:
- one on Bob’s phone for `https://bob.<box-host>`
- one on Bob’s laptop for `https://bob.<box-host>`
- etc.

**Shared-across-apps rule:** All shipped apps served under the same tenant origin SHALL use the same
local tenant replica on that device.

Example (single device, Bob tenant origin):
- `https://bob.<box-host>/simplenote` and `https://bob.<box-host>/richnote` must both read/write
  through the same local tenant replica so they see the same `note:*` documents while offline.

- Because apps share a tenant origin and a single local tenant replica, app boundaries are not a hard isolation boundary in the browser; preventing cross-doc-kind writes is enforced by discipline and tests (ADR-0001).

Rationale:
- If each app maintained its own local PouchDB database, then apps would not see each other’s changes offline,
  breaking the “multiple apps share doc kinds” architecture and creating multiple local sources of truth.

### 4.5 Gateway mediates tenant-scoped CouchDB access
Normative posture:
- Shipped apps and clients access CouchDB over HTTP using the standard CouchDB API and replication protocol.
- CouchDB is exposed externally only through the tenant origin as a tenant-scoped surface (same-origin),
  not as a raw CouchDB node endpoint.
- The gateway/reverse proxy maps:
  - `https://<tenant_id>.<box-host>/db` → CouchDB database `tenant_<tenant_id>`
- The gateway SHALL NOT require clients to know CouchDB ports or internal database topology.

Rationale:
- Browser correctness: same-origin access avoids CORS/mixed-content/auth pitfalls for PWAs.
- Tenant correctness: tenant context is derived from hostname and mapped to the correct tenant DB.
- Surface-area control: we avoid exposing CouchDB node/admin surfaces to the LAN/WAN by default while still using CouchDB “the CouchDB way.”

Rationale:
- tenant context is derived from hostname
- membership/authorization is enforced at the gateway
- stable endpoints reduce client coupling to internal topology

### 4.6 Replication endpoint shape (normative)
Replication SHALL be same-origin with the tenant and SHALL NOT require clients to know CouchDB database names.

- Replication endpoint (recommended): `https://<tenant_id>.<box-host>/db`

Gateway mapping:
- `/db` on tenant origin maps to CouchDB database `tenant_<tenant_id>`

Clients SHALL NOT select arbitrary CouchDB database names directly.

### 4.7 Users are actors; tenant membership gates access
Requests are evaluated in both:
- **actor context:** `user_id` (who)
- **tenant context:** `tenant_id` (which tenant DB/origin)

The gateway SHALL enforce that the authenticated user is a member of the tenant implied by the hostname,
and that their role/capabilities allow the requested action.

---

## 5 Architecture views

### 5.1 Logical view (components and responsibilities)

#### 5.1.1 Gateway (edge router + auth)
Responsibilities:
- terminate TLS
- route by hostname (`<tenant_id>.<box-host>`) and path (`/<app_slug>`, `/db`, `/api/...`)
- authenticate users and establish sessions/tokens
- authorize access based on tenant membership and roles/capabilities
- present stable, tenant-scoped endpoints for replication and APIs
- inject/propagate validated identity context to internal services

#### 5.1.2 Static app hosting (PWA assets)
Responsibilities:
- serve PWA bundles for apps under their paths
- support installable offline-first behavior via service workers and cached assets

Normative requirement:
- Shipped apps SHALL be installable and capable of running from browser cache after first successful load (ADR-0001).

#### 5.1.3 Platform services (optional but expected)
Responsibilities:
- provide higher-level APIs and workflows beyond raw replication
- mediate cross-doc-kind workflows (e.g., “task mentions contact”) where needed
- implement additional authorization beyond coarse membership (when required)
- implement invariants and validation rules that are not purely “client convention”

Note:
- Shipped apps replicate via CouchDB protocol for primary sync (ADR-0002). Platform services are not a required hop for replication.

#### 5.1.4 CouchDB (tenant DB store + replication)
Responsibilities:
- store application documents per tenant DB
- support replication protocol endpoint (internally), surfaced to clients through gateway mapping
- support change feeds and conflict representation
- enforce partitioned database constraints on `_id`

Operational requirement (informative):
- compaction and revision growth management are required operational hygiene.

#### 5.1.5 Blob/file store
Responsibilities:
- maintain one tenant blob store per tenant (tenant-scoped storage roots) so tenant operations (delete/export/accounting) are self-contained and legible
- store large binary content outside CouchDB by default (ADR-0002)
- provide stable content-addressed references/hashes stored in CouchDB docs
- support "what is taking storage?" accounting

### 5.2 Data view (partitioning, IDs, and references)

#### 5.2.1 Partitioning model (normative)
- Primary partition: **tenant** (tenant DB per tenant)
- Within tenant DB: **doc kinds** via CouchDB partitions
- Apps do not define data partitions.

#### 5.2.2 Naming summary (normative)
- Hostname: `<tenant_id>.<box-host>`
- App path: `/<app_slug>`
- CouchDB tenant DB: `tenant_<tenant_id>`
- Replication endpoint: `/db` on tenant origin
- Local PouchDB DB (within origin): `tenant_local`
- Tenant blob store: tenant-scoped storage root (one per tenant); Blob Paths are derived per ADR-0006

#### 5.2.3 Document IDs (normative)
- `_id = "<doc_kind>:<uuidv4>"` (ADR-0004)
- `doc_kind` is derived only from `_id`

#### 5.2.4 Blobs and references (normative)
- Documents MAY reference blobs by content hash/CID.
- Blob payload bytes SHALL be stored outside CouchDB by default in the **tenant blob store** under the tenant's storage root.

### 5.3 Runtime/process view (request and sync flows)

#### 5.3.1 Typical app session (informative)
1) User navigates to `https://family.<box-host>/tasks`
2) Gateway authenticates user and verifies membership in tenant `family`
3) PWA loads and uses service worker for offline asset caching
4) App reads/writes local tenant replica first (`tenant_local`)
5) When connectivity allows, app replicates with `https://family.<box-host>/db`
6) Gateway maps to `tenant_family` and enforces authorization

#### 5.3.2 Offline-first requirement (normative)
Shipped apps SHALL:
- be functional when the box is unreachable (after first successful load),
- persist working data locally (PouchDB/IndexedDB),
- attempt opportunistic, incremental replication when available (ADR-0001, ADR-0002).

### 5.4 Deployment view (k3s mapping)

#### 5.4.1 Kubernetes namespaces
- Kubernetes namespaces are operational partitions only.
- Tenant boundaries SHALL NOT be implemented primarily as Kubernetes namespaces (ADR-0003).

Recommended posture:
- run shared multi-tenant services (gateway, platform services, CouchDB) in a small number of k3s namespaces (e.g., `ourbox-system`, `ourbox-platform`).
- run each shipped app workload bundle in its own Kubernetes namespace (e.g., `app-simplenote`, `app-richnote`).

#### 5.4.2 Ingress and routing requirements (normative)
- Ingress/gateway SHALL support wildcard host routing for `*.<box-host>`.
- TLS SHALL be terminated at the gateway for tenant subdomains.
- Path routing SHALL support:
  - `/<app_slug>` for app assets
  - `/db` for replication endpoint
  - `/api/...` for service APIs (when present)

---

## 6 Identity and access (normative)

### 6.1 Separation of concerns
- Tenant DBs represent tenant-scoped storage and replication units.
- User identity and membership are enforced by the gateway and platform services.
- CouchDB SHOULD be treated as internal infrastructure and not exposed directly.

### 6.2 Tenant context derivation
- `tenant_id` SHALL be derived from the request hostname.
- Services SHALL treat tenant context as required input and SHALL NOT accept `tenant_id` from untrusted client parameters as the primary authority when hostname is present.

### 6.3 Authorization
Authorization SHALL consider:
- authenticated user identity (`user_id`)
- tenant derived from hostname (`tenant_id`)
- membership and roles/capabilities within that tenant
- any doc-kind-specific rules where applicable

---

## 7 Replication, conflicts, and policy (normative)

### 7.1 Replication is not backup
Replication SHALL be treated as availability/synchronization, not as backup (ADR-0002).

### 7.2 Conflict policy
Each shipped app (and/or platform service) SHALL define conflict handling policy for the doc kinds it writes, including:
- merge strategy or conflict surfacing
- delete/tombstone semantics
- “last write wins” vs explicit merges (if applicable)

(Exact policies are doc-kind specific and out of scope for this AD.)

---

## 8 Operational considerations (informative)

### 8.1 CouchDB maintenance
Operational hygiene includes:
- compaction schedules
- monitoring revision growth and storage use
- clear reporting of “what is taking storage?”

### 8.2 Browser storage eviction risks
Browsers may evict cached assets or IndexedDB under storage pressure or policy. Shipped apps should
be resilient and should communicate degraded states appropriately (UI not specified in this AD).

---

## 9 Extensibility (normative posture)

### 9.1 Multiple apps sharing doc kinds
The architecture SHALL support multiple apps using the same doc kinds by ensuring:
- local storage is shared per tenant origin (local tenant replica)
- doc kinds are defined by `_id` structure (ADR-0004)
- apps are replaceable experiences over stable documents

### 9.2 Adding a new doc kind
A new doc kind introduction SHALL include:
- name (stable vocabulary token)
- `_id` prefix commitment
- indexing/query posture
- conflict handling posture

---

## 10 Examples (informative)

### 10.1 URLs
- `https://bob.<box-host>/simplenote`
- `https://bob.<box-host>/richnote`
- `https://alice.<box-host>/calendar`

### 10.2 CouchDB tenant DBs
- `tenant_bob`
- `tenant_alice`
- `tenant_family`

### 10.3 Replication endpoints
- `https://bob.<box-host>/db`
- `https://family.<box-host>/db`

---

# SyRS-0001: OurBox OS System Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-01-27
**Status:** Draft

This specification is an early, intentionally small set of normative requirements derived from:
- architecture docs ([[arch_doc:AD-0001]])
- decisions ([[adr:ADR-0001]]..[[adr:ADR-0006]])

It is compiled from GraphMD records into `SyRS-0001-ourbox-os-system-requirements-specification.md`.

## Normative Language

The key words **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, and **MAY** are to be interpreted as
requirements. When a requirement references a record, that record is part of the normative context.

## Application Requirements

These requirements describe the baseline posture for shipped OurBox applications operating within a
single tenant origin, including offline-first behavior and doc-kind handling.

### APP-001: Shipped apps SHALL be offline-first PWAs

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Aligns shipped apps with ADR-0001 posture.

Shipped OurBox apps SHALL be installable PWAs that can load from cache after the first successful
online session.

### APP-002: Shipped apps SHALL persist working data locally

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Offline writes depend on local persistence.

Shipped apps SHALL store working data locally in the tenant origin using PouchDB-backed IndexedDB.

### APP-003: Shipped apps SHALL sync opportunistically

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Supports sporadic connectivity while keeping data consistent.

Shipped apps SHALL initiate incremental replication with the tenant DB when connectivity is available.

### APP-004: Apps SHALL operate within a tenant origin

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Tenant origins define storage isolation and routing.

Shipped apps SHALL be served under `https://<tenant_id>.<box-host>/<app_slug>` and derive tenant
context from the hostname.

### APP-005: Apps SHALL share one local tenant replica per origin

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Ensures apps share doc kinds offline.

All shipped apps under the same tenant origin SHALL read and write through a single local tenant
replica database on that device.

### APP-006: Apps SHALL honor doc-kind contracts

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Shared storage requires strict doc-kind boundaries.

Shipped apps SHALL only create and update documents whose `_id` prefixes match the stable doc-kind
vocabulary defined for OurBox OS.

## Data and Replication

These requirements capture the canonical data modeling and replication posture for tenant databases
and local replicas.

### DATA-001: Each tenant SHALL have exactly one tenant DB

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Tenant DBs are the replication unit for data modeling and replication.

OurBox SHALL maintain one CouchDB database per tenant, named using the `tenant_<tenant_id>` pattern.

### DATA-002: Tenant DBs SHALL be partitioned databases

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Partitioning enforces doc-kind boundaries.

All tenant databases SHALL be created as CouchDB partitioned databases.

### DATA-003: Document IDs SHALL use the doc_kind:uuidv4 scheme

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Canonical IDs ensure consistent replication and conflict boundaries.

Application documents SHALL have `_id` values shaped as `<doc_kind>:<uuidv4>`.

### DATA-004: Doc kind SHALL be derived from _id only

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Avoids divergent sources of truth for document classification.

Applications and services SHALL derive `doc_kind` from the `_id` prefix and SHALL NOT store a separate
doc-type field as the authoritative source.

### DATA-005: Tenant replication SHALL be whole-DB

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Replication posture is tenant DB ↔ tenant DB.

Replication between client devices and the box SHALL use the tenant DB as the unit of replication and
SHALL NOT require selective partition replication.

### DATA-006: Blobs SHALL be stored outside CouchDB by default

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Large binary content should not be default CouchDB attachments; tenant-scoped blob stores enable legible tenant operations.

Large binary assets (photos/video/audio) SHALL be stored outside CouchDB by default in the tenant blob store (one blob store per tenant), with references stored in application documents.

### DATA-007: Each tenant SHALL have exactly one tenant blob store

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Tenant-scoped blob stores keep blob payload bytes legible for tenant operations and align with ADR-0006 storage roots.

OurBox SHALL maintain one tenant blob store per tenant for blob payload bytes stored outside CouchDB.

Each tenant blob store SHALL use a tenant-scoped storage root (ADR-0006).

## Gateway and Identity

These requirements define tenant routing, identity enforcement, and the gateway surface used by
clients and shipped apps.

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

## Kubernetes and Deployment

These requirements describe the k3s/Kubernetes posture for deploying OurBox OS services and shipped
apps while preserving tenant boundaries.

### K8S-001: Kubernetes namespaces SHALL NOT encode tenant boundaries

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** Tenant is a data boundary, not an operational namespace.

Kubernetes namespaces SHALL be used for operational grouping and SHALL NOT be treated as the primary
tenant isolation boundary.

### K8S-002: Gateway ingress SHALL support wildcard tenant hosts

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** Tenant origins rely on hostname routing.

Ingress configuration SHALL support wildcard host routing for `*.<box-host>` to enable tenant
subdomains.

### K8S-003: Shipped app workloads SHOULD use dedicated namespaces

**Status:** Draft  
**Testable:** false  
**Area:** k8s  
**Rationale:** Separates app operations while keeping tenant boundaries intact.

Shipped app workload bundles SHOULD run in their own Kubernetes namespaces to simplify operations
and isolation from platform services.

---

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

---

# SRS-0202: CouchDB Service Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-01-31
**Status:** Draft

This specification defines the software requirements for the on-box **CouchDB service** (system-of-record for tenant DBs). It is a minimal scaffold; detailed requirements live in section records and the authoritative Glossary.

## Normative Language

Normative keywords (SHALL, SHALL NOT, SHOULD, SHOULD NOT, MAY) are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Product and architecture terms used in this SRS (including **CouchDB**, **tenant**, **tenant_id**, **tenant DB**, **tenant blob store**, and **replication**) are defined in the OurBox OS Glossary.

- Vocabulary authority: `docs/architecture/Glossary.md` (normative for terminology)
- Normative keywords (SHALL/SHOULD/MAY): `docs/00-Glossary/Terms-and-Definitions.md`

## Introduction

This SRS defines requirements for the **on-box CouchDB service**, which acts as the tenant-scoped system-of-record and replication target.

Scope includes:
- tenant DB creation and naming posture (`tenant_<tenant_id>`)
- partitioned database posture and `_id` scheme
- replication posture at the database level (tenant DB ↔ tenant DB)
- tenant storage contract boundaries for CouchDB usage

Out of scope:
- gateway routing, `/db` mapping, and host/path policy (see `[[spec:SRS-0201]]`)
- client local replicas and PouchDB behavior (see `[[spec:SRS-0204]]`)
- tenant blob store requirements (see `[[spec:SRS-0205]]`)

This SRS is intentionally a minimal scaffold, but it pulls in the already-established requirements from:
- `[[spec:SyRS-0001]]` (system requirements for data/replication), and
- `[[arch_doc:AD-0001]]` (architecture invariants for storage/replication posture).

## Referenced Documents

- `docs/00-Glossary/Terms-and-Definitions.md`
- `docs/architecture/Glossary.md`
- [[spec:SyRS-0001]]
- [[arch_doc:AD-0001]]
- [[adr:ADR-0001]]
- [[adr:ADR-0002]]
- [[adr:ADR-0003]]
- [[adr:ADR-0004]]
- [[adr:ADR-0005]]
- [[adr:ADR-0006]]
- [[adr:ADR-0007]]
- [[spec:SRS-0201]]
- [[spec:SRS-0205]]

## Requirements

Allocated system requirements from `[[spec:SyRS-0001]]` are included here for traceability; CouchDB-service-specific requirements follow.

### DATA-001: Each tenant SHALL have exactly one tenant DB

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Tenant DBs are the replication unit for data modeling and replication.

OurBox SHALL maintain one CouchDB database per tenant, named using the `tenant_<tenant_id>` pattern.

### DATA-002: Tenant DBs SHALL be partitioned databases

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Partitioning enforces doc-kind boundaries.

All tenant databases SHALL be created as CouchDB partitioned databases.

### DATA-003: Document IDs SHALL use the doc_kind:uuidv4 scheme

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Canonical IDs ensure consistent replication and conflict boundaries.

Application documents SHALL have `_id` values shaped as `<doc_kind>:<uuidv4>`.

### DATA-004: Doc kind SHALL be derived from _id only

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Avoids divergent sources of truth for document classification.

Applications and services SHALL derive `doc_kind` from the `_id` prefix and SHALL NOT store a separate
doc-type field as the authoritative source.

### DATA-005: Tenant replication SHALL be whole-DB

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Replication posture is tenant DB ↔ tenant DB.

Replication between client devices and the box SHALL use the tenant DB as the unit of replication and
SHALL NOT require selective partition replication.

### DATA-006: Blobs SHALL be stored outside CouchDB by default

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Large binary content should not be default CouchDB attachments; tenant-scoped blob stores enable legible tenant operations.

Large binary assets (photos/video/audio) SHALL be stored outside CouchDB by default in the tenant blob store (one blob store per tenant), with references stored in application documents.

### DATA-007: Each tenant SHALL have exactly one tenant blob store

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Tenant-scoped blob stores keep blob payload bytes legible for tenant operations and align with ADR-0006 storage roots.

OurBox SHALL maintain one tenant blob store per tenant for blob payload bytes stored outside CouchDB.

Each tenant blob store SHALL use a tenant-scoped storage root (ADR-0006).

### BOXDB-001: Replication SHALL use the standard CouchDB API and replication protocol

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Preserves interoperability across many clients and enables future peer replication without proprietary protocols.

Replication between clients and the box SHALL use the standard CouchDB HTTP API and replication protocol.

**Trace:** [[arch_doc:AD-0001]] §4.5

### BOXDB-002: Replication SHALL be treated as synchronization, not backup

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Replication can copy deletions and bad changes; backup must be point-in-time retention.

Replication SHALL be treated as availability/synchronization behavior and SHALL NOT be treated as backup.

**Trace:** [[arch_doc:AD-0001]] §7.1

## External Interfaces

The CouchDB service is treated as internal infrastructure.

Client-facing replication endpoints are presented via the Gateway on tenant origins (see `[[spec:SRS-0201]]`). Any direct CouchDB node/admin surface is intentionally out of scope for client access.

Precise service-to-service interface details (ports, auth, internal URLs) will be specified via future ICDs.

## Verification

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:
- **Inspection:** tenant DB naming, partitioned mode configuration, and blob-store posture.
- **Test:** replication between a client and the box using the tenant DB as the unit of replication.

---

# SRS-0203: k3s Platform Contract Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-01-31
**Status:** Draft

This specification defines the software requirements for the **k3s platform contract** shipped on an OurBox instance (workload topology, persistent data placement, operational defaults, governance, and verification posture). It is a minimal scaffold; detailed requirements live in section records and the authoritative Glossary.

## Normative Language

Normative keywords (SHALL, SHALL NOT, SHOULD, SHOULD NOT, MAY) are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Product and architecture terms used in this SRS (including **Kubernetes namespace**, **Gateway**, **tenant**, **tenant origin**, and **tenant DB**) are defined in the OurBox OS Glossary.

- Vocabulary authority: `docs/architecture/Glossary.md` (normative for terminology)
- Normative keywords (SHALL/SHOULD/MAY): `docs/00-Glossary/Terms-and-Definitions.md`

## Introduction

This SRS defines requirements for the **k3s platform contract** used to deploy and operate OurBox OS workloads on an OurBox instance.

Scope includes:
- k3s as the Kubernetes distribution used on-box for OurBox OS workloads
- Kubernetes namespace posture (operational grouping; not tenant boundaries)
- **data placement** requirements for system-of-record data when deployed in k3s (persistent storage expectations)
- **defaults** required for out-of-box operation (e.g., default persistent volume provisioning, namespace conventions)
- **governance** posture for the deployment configuration baseline (how the deployed platform is defined and controlled)
- **verification** posture for confirming the running cluster satisfies the contract

Out of scope:
- gateway routing semantics and app/path policy (see `[[spec:SRS-0201]]`)
- on-box CouchDB data modeling posture (see `[[spec:SRS-0202]]`)
- tenant blob store semantics and CAS rules (see `[[spec:SRS-0205]]`)
- app-specific behavior and UI flows (see app SRSs)

## Referenced Documents

- `docs/00-Glossary/Terms-and-Definitions.md`
- `docs/architecture/Glossary.md`
- [[spec:SyRS-0001]]
- [[arch_doc:AD-0001]]
- [[adr:ADR-0003]]
- [[adr:ADR-0007]]
- [[spec:SRS-0201]]
- [[spec:SRS-0202]]
- [[spec:SRS-0205]]

## Requirements

Allocated system requirements from `[[spec:SyRS-0001]]` are included here for traceability; k3s-platform-specific requirements follow.

### K8S-001: Kubernetes namespaces SHALL NOT encode tenant boundaries

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** Tenant is a data boundary, not an operational namespace.

Kubernetes namespaces SHALL be used for operational grouping and SHALL NOT be treated as the primary
tenant isolation boundary.

### K8S-002: Gateway ingress SHALL support wildcard tenant hosts

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** Tenant origins rely on hostname routing.

Ingress configuration SHALL support wildcard host routing for `*.<box-host>` to enable tenant
subdomains.

### K8S-003: Shipped app workloads SHOULD use dedicated namespaces

**Status:** Draft  
**Testable:** false  
**Area:** k8s  
**Rationale:** Separates app operations while keeping tenant boundaries intact.

Shipped app workload bundles SHOULD run in their own Kubernetes namespaces to simplify operations
and isolation from platform services.

### K8S-004: OurBox OS SHALL use k3s as the Kubernetes distribution

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** AD-0001 establishes OurBox as a k3s-based appliance deployment posture.

OurBox OS SHALL deploy and operate its Kubernetes workloads using k3s on each OurBox instance.

**Trace:** [[arch_doc:AD-0001]]

### K8S-005: CouchDB SHALL run as a k3s workload

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** ADR-0007 establishes that CouchDB runs as a k3s workload for consistent appliance operations.

The CouchDB service SHALL be deployed and managed as a Kubernetes workload in the on-box k3s cluster and SHALL NOT be operated as an unmanaged host-level daemon.

**Trace:** [[adr:ADR-0007]]

### K8S-006: CouchDB data SHALL be stored on persistent volumes

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** CouchDB is the system-of-record; when deployed in k3s its data must survive pod restarts and rescheduling.

The CouchDB workload SHALL store CouchDB data files on persistent storage provided via Kubernetes PersistentVolumeClaim(s).

CouchDB SHALL NOT store system-of-record data only on ephemeral container filesystem storage.

**Trace:** [[adr:ADR-0007]]

### K8S-007: k3s platform SHALL provide default persistent volume provisioning for system-of-record workloads

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** Operational simplicity: the appliance should provide durable storage without requiring manual PV provisioning.

The k3s platform deployment SHALL provide a default mechanism to provision persistent volumes suitable for system-of-record workloads (e.g., CouchDB) without requiring the operator to pre-create volumes.

**Trace:** [[arch_doc:AD-0001]] §2.1

### K8S-008: Platform workloads SHOULD use dedicated system namespaces

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** AD-0001 recommends a small set of namespaces for platform workloads and app workloads for operational legibility.

Shared multi-tenant platform workloads (e.g., gateway, CouchDB, platform services) SHOULD run in a small set of dedicated Kubernetes namespaces (e.g., `ourbox-system`, `ourbox-platform`).

Shipped app workload bundles SHOULD run in app-specific Kubernetes namespaces (e.g., `app-simplenote`, `app-richnote`).

**Trace:** [[arch_doc:AD-0001]] §5.4.1

### K8S-009: k3s platform deployment SHALL be governed by a versioned configuration baseline

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** A versioned baseline enables reproducible deployments and controlled changes consistent with requirements governance.

The Kubernetes resources that define the OurBox OS platform deployment (namespaces, workloads, ingress, and storage objects) SHALL be defined declaratively in version-controlled artifacts.

Changes to the deployment baseline SHALL follow controlled change procedures.

**Trace:** `docs/00-Glossary/Terms-and-Definitions.md` (Baseline, Change control)

## External Interfaces

The k3s platform is treated as internal infrastructure on the OurBox instance.

External interfaces include:
- Kubernetes deployment artifacts (manifests/charts) used to define the platform baseline
- operational inspection surfaces (e.g., `kubectl`-visible resources, logs, events)

Precise operational procedures and any operator-facing commands will be specified via future ICDs or operational docs.

## Verification

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:
- **Inspection:** confirm namespace posture (no tenant namespaces) and wildcard host ingress posture.
- **Inspection:** confirm CouchDB is deployed as a k3s workload and uses persistent storage (PVC/PV).
- **Test:** restart/reschedule the CouchDB pod and confirm tenant DB data remains intact.
- **Inspection:** confirm the deployment baseline is traceable to versioned artifacts (release manifests/config snapshots).

---

# SRS-0204: Local Tenant Replica Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-01-31
**Status:** Draft

This specification defines the software requirements for the **local tenant replica** on client devices (PouchDB/IndexedDB within a tenant origin). It is a minimal scaffold; detailed requirements live in section records and the authoritative Glossary.

## Normative Language

Normative keywords (SHALL, SHALL NOT, SHOULD, SHOULD NOT, MAY) are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Product and architecture terms used in this SRS (including **PouchDB**, **IndexedDB**, **tenant origin**, and **local tenant replica**) are defined in the OurBox OS Glossary.

- Vocabulary authority: `docs/architecture/Glossary.md` (normative for terminology)
- Normative keywords (SHALL/SHOULD/MAY): `docs/00-Glossary/Terms-and-Definitions.md`

## Introduction

This SRS defines requirements for the **local tenant replica** on client devices: the PouchDB database (IndexedDB-backed) within a tenant origin that enables offline-first behavior.

Key posture (already established in architecture):
- many client devices may exist per tenant
- connectivity may be intermittent; sync is opportunistic
- storage isolation is by tenant origin (`https://<tenant_id>.<box-host>`)

Out of scope:
- on-box CouchDB service requirements (see `[[spec:SRS-0202]]`)
- gateway routing and `/db` mapping (see `[[spec:SRS-0201]]`)

## Referenced Documents

- `docs/00-Glossary/Terms-and-Definitions.md`
- `docs/architecture/Glossary.md`
- [[spec:SyRS-0001]]
- [[arch_doc:AD-0001]]
- [[adr:ADR-0001]]
- [[adr:ADR-0002]]
- [[adr:ADR-0003]]
- [[adr:ADR-0004]]
- [[spec:SRS-0201]]
- [[spec:SRS-0202]]

## Requirements

Allocated system requirements from `[[spec:SyRS-0001]]` are included here for traceability; local-replica-specific requirements follow.

### APP-002: Shipped apps SHALL persist working data locally

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Offline writes depend on local persistence.

Shipped apps SHALL store working data locally in the tenant origin using PouchDB-backed IndexedDB.

### APP-003: Shipped apps SHALL sync opportunistically

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Supports sporadic connectivity while keeping data consistent.

Shipped apps SHALL initiate incremental replication with the tenant DB when connectivity is available.

### APP-005: Apps SHALL share one local tenant replica per origin

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Ensures apps share doc kinds offline.

All shipped apps under the same tenant origin SHALL read and write through a single local tenant
replica database on that device.

### DATA-005: Tenant replication SHALL be whole-DB

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Replication posture is tenant DB ↔ tenant DB.

Replication between client devices and the box SHALL use the tenant DB as the unit of replication and
SHALL NOT require selective partition replication.

### BOXDB-001: Replication SHALL use the standard CouchDB API and replication protocol

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Preserves interoperability across many clients and enables future peer replication without proprietary protocols.

Replication between clients and the box SHALL use the standard CouchDB HTTP API and replication protocol.

**Trace:** [[arch_doc:AD-0001]] §4.5

### LCR-001: Local tenant replica SHALL use the stable database name `tenant_local`

**Status:** Draft  
**Testable:** true  
**Area:** client  
**Rationale:** A stable local DB name enables multiple shipped apps under the same tenant origin to share the same working store.

Within a tenant origin, the local tenant replica SHALL use the stable PouchDB database name `tenant_local`.

**Trace:** [[arch_doc:AD-0001]] §5.2.2

## External Interfaces

The local tenant replica interacts with:
- browser storage via IndexedDB (through PouchDB)
- replication endpoints on the tenant origin (presented by the Gateway)

Precise replication configuration (credentials/session mechanics, endpoint URLs beyond `/db`) will be specified via future ICDs.

## Verification

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:
- **Test:** offline write/read against the local tenant replica; then reconnect and replicate successfully.
- **Inspection:** confirm a single local tenant replica is used across shipped apps within the same tenant origin.

---

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

### DATA-006: Blobs SHALL be stored outside CouchDB by default

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Large binary content should not be default CouchDB attachments; tenant-scoped blob stores enable legible tenant operations.

Large binary assets (photos/video/audio) SHALL be stored outside CouchDB by default in the tenant blob store (one blob store per tenant), with references stored in application documents.

### DATA-007: Each tenant SHALL have exactly one tenant blob store

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Tenant-scoped blob stores keep blob payload bytes legible for tenant operations and align with ADR-0006 storage roots.

OurBox SHALL maintain one tenant blob store per tenant for blob payload bytes stored outside CouchDB.

Each tenant blob store SHALL use a tenant-scoped storage root (ADR-0006).

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

---

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

---

# SRS-1001: SimpleNote Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-01-28
**Status:** Draft

This specification defines the software requirements for the SimpleNote application.

This is intentionally minimal scaffolding; requirements will be added iteratively.

## Normative Language

Normative keywords (SHALL, SHALL NOT, SHOULD, SHOULD NOT, MAY) are defined in
`docs/00-Glossary/Terms-and-Definitions.md`.

## Introduction

This SRS defines the requirements for the SimpleNote application software item.

SimpleNote is a user-facing application. Detailed requirements will be added iteratively.

## Referenced Documents

- `docs/00-Glossary/Terms-and-Definitions.md`
- [[spec:SyRS-0001]]
- [[arch_doc:AD-0001]]
- [[adr:ADR-0001]]
- [[adr:ADR-0002]]
- [[adr:ADR-0003]]
- [[adr:ADR-0004]]

## Requirements

This section will be populated with SimpleNote software requirements.

Typical groupings (to be filled in later):
- Allocated System Requirements (from SyRS)
- Functional Requirements
- Data Requirements
- Quality Requirements (NFRs)
- Constraints

## External Interfaces

External interfaces (UI surface expectations, APIs consumed, replication endpoints, etc.) will be
specified via ICDs (as applicable) and referenced here.

## Verification

Verification provisions (methods, environments, and trace links to evidence) will be defined here.
Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

---

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

External interfaces (UI surface expectations, APIs consumed, replication endpoints, etc.) will be
specified via ICDs (as applicable) and referenced here.

## Verification

Verification provisions (methods, environments, and trace links to evidence) will be defined here.
Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

---
