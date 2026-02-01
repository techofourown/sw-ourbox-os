# Terms and Definitions

## Purpose
This document defines canonical terms and acronyms used across OurBox OS requirements, architecture,
design, and verification artifacts.

It also defines the normative requirement keywords (SHALL, SHOULD, MAY, etc.) used throughout this
repository’s specifications.

**Rule:** one concept gets one term. Avoid ambiguous synonyms.

If anything in this repository conflicts with this document’s vocabulary, **this document wins**.

---

## Vocabulary rules and reserved terms

### Vocabulary authority
This document is the vocabulary authority for:

- OurBox OS product and architecture terms (tenant, gateway, local tenant replica, etc.)
- requirements language (SHALL/SHOULD/MAY)
- general systems/software engineering process terms (verification methods, baseline, change control, etc.)

### Reserved words (normative)
Avoid overloaded words. In particular:

- “Dataset” is reserved for GraphMD conversations and is **not** used as an OurBox OS storage term.
- “Domain” is avoided (confusable with DNS domains).
- “Namespace” is reserved for Kubernetes namespaces.

**Reserved term:** `capability` refers only to tenant-scoped authorization permissions. Use **system capability** for system functions/abilities.

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

## OurBox OS product and architecture terms (normative)

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

---

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

---

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

---

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

---

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

---

## Web platform terms

### Progressive Web App (PWA)
A web application that can be installed and can provide offline capability using web platform features
(e.g., service worker, Cache Storage, IndexedDB).

### service worker
A background script registered by a web app that can intercept network requests and manage offline
caches for an origin/scope.

### IndexedDB
The browser storage API used by PouchDB for local persistence.

---

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

## General systems and software engineering definitions

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

### System capability
A named ability or function the system provides, typically described at an operational level.

**Note:** In OurBox OS, the term **capability** (without “system”) is reserved for authorization permissions; use **system capability** for system abilities/functions.

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
A requirement that specifies a function, behavior, or system capability the system or system element shall
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
A system element composed of multiple components that together provide a set of system capabilities within
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
