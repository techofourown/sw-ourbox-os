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
- SRS-1003-messager-software-requirements-specification.md (source: spec:SRS-1003)
- SRS-1004-scout-software-requirements-specification.md (source: spec:SRS-1004)
- SRS-1005-compass-software-requirements-specification.md (source: spec:SRS-1005)
- SRS-1006-spar-software-requirements-specification.md (source: spec:SRS-1006)

---

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

### full host
The entire host portion of a URL before any port and before the path.

Examples:
- full host: `bob.local`
- full host: `bob.box.example.com`

### box-host
In **public custom-domain mode**, `box-host` is the base host suffix after the tenant label in a full host.

Pattern:
- full host: `<tenant_id>.<box-host>`

Examples:
- full host: `bob.bobsdomain.com`
  - `tenant_id = bob`
  - `box-host = bobsdomain.com`
- full host: `alice.box.example.com`
  - `tenant_id = alice`
  - `box-host = box.example.com`

In local-only mode, tenant hosts are `<tenant_id>.local`; there is no separate public `box-host` suffix in that local tenant-host grammar.

### Local-only mode
The zero-preparation joined-LAN mode for tenant app access.

Pattern:
- `http://<tenant_id>.local/<app_slug>`

Characteristics (normative intent):
- local-only mode is HTTP-only,
- does not require public DNS registration,
- does not require port forwarding,
- and does not require local CA installation.

### Public custom-domain mode
The user-configured internet-facing mode for tenant app access.

Pattern:
- `https://<tenant_id>.<box-host>/<app_slug>`

Characteristics (normative intent):
- HTTPS/TLS mode,
- user controls the public DNS base host,
- and external routing is operator-managed.

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
- SHALL be safe for use in DNS labels.
- SHALL be safe for use as the leftmost DNS label of a tenant host.
- SHALL be safe for use in CouchDB database names.

Examples: `bob`, `alice`, `family`, `roommates-2026`

### tenant host
The full host used to address a tenant.

Supported tenant-host patterns:
- local-only mode: `<tenant_id>.local`
- public custom-domain mode: `<tenant_id>.<box-host>`

### local landing host
A reserved non-tenant local host used for setup/admin entry flows.

Recommended example:
- `ourbox.local`

### Tenant origin
A tenant-scoped browser origin derived from tenant host/full host.

Supported patterns by mode:
- local-only mode: `http://<tenant_id>.local/...`
- public custom-domain mode: `https://<tenant_id>.<box-host>/...`

Across both modes:
- the full host carries tenant context,
- `tenant_id` is derived from the leftmost DNS label of the full host,
- and the path identifies app context.

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

## Hardware target and integration terms

### Hardware target
A specific supported device family or hardware configuration for which an `img-*` repository builds
an OS payload, installer media, or another install artifact.

### Hardware seam
The conceptual boundary between target-specific hardware enablement below the seam and the
standardized OurBox platform behavior above it.

### Hardware enablement
The target-specific work required to make a hardware target viable, including substrate selection,
boot integration, drivers, storage provisioning, flashing, installer mechanics, and related bring-up.

### Target substrate
The base operating foundation for a target, including base distro or vendor BSP, kernel, firmware,
boot chain, and driver stack.

### Base substrate
Synonym for target substrate. Central docs should prefer **target substrate**.

### Platform contract
The versioned deployed OurBox platform baseline produced by `sw-ourbox-os`, including the k3s
wiring baseline and related platform configuration expectations.

### Target integration contract
The stable set of consumer-facing expectations that a target-specific image repo must satisfy so
the OurBox platform can be consumed consistently above the hardware seam.

### Host contract
Informal repo-local synonym for target integration contract. Central `sw-ourbox-os` docs should
prefer **target integration contract**.

### Image repo
A hardware-specific `img-*` repository that consumes the platform contract and turns it into a
target-specific OS payload, installer flow, or install artifact.

### Installer profile
The installer identity used to resolve default artifact selection for a target, commonly keyed by
something like `INSTALLER_ID`.

### OS payload
The target-specific installable operating system artifact produced by an `img-*` repo.

### Official installer media
A TOOO-published artifact used to initiate installation on a hardware target. It is distinct from
the OS payload even when both are produced by the same repo.

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

In OurBox architecture, public custom-domain mode is the full installable-PWA posture.
Local-only mode is HTTP-only and does not guarantee equivalent installability or reopen-offline behavior.

### service worker
A background script registered by a web app that can intercept network requests and manage offline
caches for an origin/scope.

Service-worker-backed full PWA behavior is tied to public custom-domain mode.

### IndexedDB
The browser storage API used by PouchDB for local persistence.

---

## Routing and enforcement

### Gateway
The front door for HTTP(S) traffic to the box, responsible for:
- routing (host + path)
- authentication and authorization enforcement
- deriving tenant context from the full host (leftmost DNS label = `tenant_id`)
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

## OCI and artifact distribution terms

### OCI artifact
A non-container (or container-adjacent) payload stored and distributed through an OCI-compliant
registry, addressable by digest.

### OCI image
A container image stored in an OCI-compliant registry. In OurBox OS docs, this term is used for
container workloads; "OCI artifact" is the broader category.

### Digest
A content-addressed identifier (for example, `sha256:<hex>`) derived from artifact bytes.

Normative guidance:
- Tags are human-facing aliases and MAY move.
- Digest is identity and SHOULD be used for repeatable installs/releases.

### Platform contract artifact
The OCI artifact form of the versioned OurBox OS deployment baseline contract (ADR-0008, ADR-0009).
This is the canonical producer output from `sw-ourbox-os` for downstream image-repo consumption.

### Release manifest
A (future) signed artifact that enumerates the exact digests that define an official OurBox release
or profile.

### Trust policy
A device-local rule set that decides which signers and/or digests are accepted for install/update.

---

---

# AD-0001: OurBox OS Architecture Description

## Status
Draft (normative unless explicitly marked "informative")

## Date
2026-01-25

## Related decisions
- ADR-0001: Purpose-build Offline-First PWAs for All Shipped OurBox Apps
- ADR-0002: Adopt CouchDB + PouchDB and Standardize OurBox Data Modeling (Tenant DBs + Partitions)
- ADR-0003: Standardize on Tenant as the OurBox OS Data Boundary Term
- ADR-0004: OurBox Document IDs
- ADR-0005: Store blobs in a content-addressed blob store keyed by a canonical multihash key (no chunking)
- ADR-0006: Deterministic sharded path layout for blob payloads
- ADR-0007: Run CouchDB as a k3s Workload (Not a Host Service)
- ADR-0008: Deployment Baseline as the Platform Integration Contract
- ADR-0011: Separate Hardware Enablement from the Platform Contract
- ADR-0014: Adopt Two Access Modes (Local-only HTTP and Public Custom-Domain HTTPS)

## Terminology
- `docs/00-Glossary/Terms-and-Definitions.md` is normative for vocabulary.

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

This AD primarily describes the architecture **above the hardware seam**. It does not specify
target-specific base distro choice, vendor BSP choice, kernel line, flashing workflow, or other
hardware enablement mechanics below that boundary.

It does not specify UI flows or user-facing terminology.

### 1.3 Architectural constraints (from ADRs)
- Shipped apps SHALL be offline-first browser apps with mode-aware behavior promises (ADR-0001, ADR-0014).
- Local-only mode tenant access SHALL be HTTP-only (`http://<tenant_id>.local/...`) and SHALL NOT be documented as equivalent to HTTPS/TLS mode (ADR-0014).
- Public custom-domain mode tenant access SHALL be HTTPS/TLS (`https://<tenant_id>.<box-host>/...`) and carries the full secure-context/installable-PWA posture (ADR-0014).
- Tenant origins SHALL be supported in both access modes; tenant context SHALL be derived from the full host and `tenant_id` from its leftmost DNS label (ADR-0003, ADR-0014).
- CouchDB on the box and PouchDB in the browser SHALL be the primary data store stack for shipped apps (ADR-0002).
- Tenant SHALL be the canonical top-level data boundary term (ADR-0003).
- Kubernetes "namespace" is reserved for Kubernetes; it SHALL NOT be used as a synonym for tenant (ADR-0003).
- Tenant DBs SHALL be partitioned databases; doc kind SHALL be encoded in `_id` (ADR-0002, ADR-0004).
- OurBox application documents SHALL use `_id = "<doc_kind>:<uuidv4>"` (ADR-0004).
- Large blobs SHALL NOT be stored as CouchDB attachments by default (ADR-0002).
- Each tenant SHALL have a tenant-scoped blob store (one blob store per tenant) with a tenant-scoped storage root; blob payload layout is deterministic per ADR-0006.
- CouchDB SHALL be deployed as a k3s/Kubernetes workload and its system-of-record data SHALL be stored on persistent volumes (ADR-0007).
- The versioned deployment baseline (rendered manifests) SHALL be the authoritative platform integration contract; running cluster state SHALL conform to that baseline (ADR-0008).
- OurBox standardizes platform behavior above the hardware seam; target-specific image repos MAY
  diverge below that seam when they still satisfy the target integration contract (ADR-0011).

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

+----------------------+ HTTP(S) +-------------------------------+
| Browser (PWA/web)    | <----------------> | Gateway (Ingress/Auth/Router) |
| - tenant origin      |                    | - tenant routing by full host |
| - local tenant       |                    | - membership enforcement       |
|   replica (PouchDB)  |                    | - stable endpoints             |
+----------+-----------+                    +-----------+-------------------+
           |                                                |
           | replication (tenant DB)                        | internal
           v                                                v
+----------------------+                    +--------------------------+
| CouchDB              |                    | Platform Services        |
| - tenant DBs         |                    | - APIs/workflows         |
| - partitioned DBs    |                    | - authz, invariants      |
+----------------------+                    +--------------------------+
           |
           v
+----------------------+
| Blob/File Store      |
| - CAS blobs outside  |
|   CouchDB by default |
+----------------------+

---

## 4 Architectural model and invariants (normative)

This section defines "how the system works together" as invariants.

### 4.1 Tenants are addressed as web origins
In web platform terms, an **origin** is the browser security boundary defined by:

- `origin = (scheme, host, port)`

Supported tenant-origin patterns are mode-specific:
- local-only mode: `http://<tenant_id>.local/...`
- public custom-domain mode: `https://<tenant_id>.<box-host>/...`

Across both modes:
- the **full host** carries tenant context,
- `tenant_id` is derived from the **leftmost DNS label** of the full host,
- the path identifies app context.

Tenant origins are distinct web origins and therefore isolate IndexedDB, Cache Storage, service-worker registration, and local tenant replicas.

### 4.2 Apps are addressed as paths under a tenant origin
Apps are addressed by path under the tenant origin in both access modes.

Patterns:
- local-only mode: `http://<tenant_id>.local/<app_slug>`
- public custom-domain mode: `https://<tenant_id>.<box-host>/<app_slug>`

Examples:
- `http://bob.local/simplenote`
- `https://bob.example.com/simplenote`

Invariant: the full host identifies tenant; the path identifies app.

### 4.3 Tenant DBs are the replication unit
Each tenant has exactly one tenant DB on the box:

- CouchDB DB name: `tenant_<tenant_id>`

Each tenant also has exactly one **tenant blob store** for blob payload bytes stored outside CouchDB. The blob store is resolved in tenant context (derived from full host) and uses a tenant-scoped storage root.

Within that tenant DB:
- the DB is a **partitioned database**
- `doc_kind` is the partition key
- `_id = "<doc_kind>:<uuidv4>"` for application documents

Replication posture:
- replicate tenant DB ↔ tenant DB (whole DB)
- do not require selective replication by partition

### 4.4 Local data is per tenant origin and shared across apps
Within a single tenant origin on a device/browser profile, shipped apps share a single local tenant replica (`tenant_local`).

This applies in both access modes, with origin semantics preserved:
- `http://bob.local` and `https://bob.<box-host>` are different origins.
- Different origins do not share IndexedDB, Cache Storage, service-worker registration, or local tenant replica state.

Therefore the same tenant accessed through local-only mode and public custom-domain mode has distinct local replicas on the same browser.

### 4.5 Replication surface is same-origin at `/db`
The gateway exposes same-origin replication endpoints in both modes:
- `http://<tenant_id>.local/db`
- `https://<tenant_id>.<box-host>/db`

`/db` is a gateway surface mapped to the tenant database; raw CouchDB ports are not tenant-facing.

### 4.6 Gateway-mediated enforcement for tenant data access
All tenant replication and app access traverse the gateway.

The gateway derives `tenant_id` from the leftmost DNS label of the full host and applies tenant membership/authorization policy before mapping to tenant resources.

### 4.7 Users are actors; tenant membership gates access
Requests are evaluated in both:
- **actor context:** `user_id` (who)
- **tenant context:** `tenant_id` (which tenant DB/origin)

The gateway SHALL enforce that the authenticated user is a member of the tenant implied by the full host,
and that their role/capabilities allow the requested action.

---

## 5 Architecture views

### 5.1 Logical view (components and responsibilities)

#### 5.1.1 Gateway responsibilities
Responsibilities:
- serve HTTP routing for local-only mode tenant hosts (`<tenant_id>.local`),
- terminate TLS for public custom-domain tenant hosts (`<tenant_id>.<box-host>`),
- optionally expose a reserved local landing host (`ourbox.local`) for setup/admin entry,
- route requests by full host and path (`/<app_slug>`, `/db`, `/api/...`) in both modes,
- derive `tenant_id` from the leftmost DNS label of the full host,
- enforce authentication and tenant membership policy.

#### 5.1.2 Static app hosting
Mode-aware posture:
- Public custom-domain mode: installable PWA posture, service-worker-backed asset caching, and reopen-offline behavior after first successful load.
- Local-only mode: same-origin browser app delivery over HTTP with local data continuity and opportunistic sync while reachable; equivalent full installable-PWA posture is not guaranteed.

#### 5.1.3 Platform services (optional but expected)
Responsibilities:
- provide higher-level APIs and workflows beyond raw replication
- mediate cross-doc-kind workflows (e.g., "task mentions contact") where needed
- implement additional authorization beyond coarse membership (when required)
- implement invariants and validation rules that are not purely "client convention"

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
- Tenant host (local-only mode): `<tenant_id>.local`
- Tenant host (public custom-domain mode): `<tenant_id>.<box-host>`
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

#### 5.3.1 Typical app sessions (informative)
Local-only mode session:
1) User navigates to `http://family.local/tasks`
2) Gateway routes HTTP request by full host and verifies membership in tenant `family`
3) App loads over HTTP and uses local tenant replica (`tenant_local`)
4) When connectivity allows, app replicates via `http://family.local/db`

Public custom-domain mode session:
1) User navigates to `https://family.<box-host>/tasks`
2) Gateway terminates TLS and verifies membership in tenant `family`
3) App loads with secure-context posture and service-worker-backed caching
4) App uses local tenant replica (`tenant_local`) for local continuity
5) When connectivity allows, app replicates via `https://family.<box-host>/db`

#### 5.3.2 Offline-first requirement (normative)
Shipped apps SHALL persist working data locally (PouchDB/IndexedDB) and attempt opportunistic, incremental replication when available. Public custom-domain mode carries full reopen-offline/installable-PWA behavior after first successful load; local-only mode carries local data continuity without equivalent full-PWA guarantees (ADR-0001, ADR-0002, ADR-0014).

### 5.4 Deployment view (k3s mapping)

#### 5.4.0 Boundary reminder
This deployment view is about the platform behavior above the hardware seam. The target-specific
substrate below that seam may vary by `img-*` repo as long as the target still satisfies the target
integration contract described in ADR-0011.

#### 5.4.1 Kubernetes namespaces
- Kubernetes namespaces are operational partitions only.
- Tenant boundaries SHALL NOT be implemented primarily as Kubernetes namespaces (ADR-0003).

Recommended posture:
- run shared multi-tenant services (gateway, platform services, CouchDB) in a small number of k3s namespaces (e.g., `ourbox-system`, `ourbox-platform`).
- run each shipped app workload bundle in its own Kubernetes namespace (e.g., `app-simplenote`, `app-richnote`).

#### 5.4.2 Ingress and routing requirements (normative)
Public custom-domain mode requirements:
- Ingress/gateway SHALL support wildcard host routing for `*.<box-host>`.
- TLS SHALL be terminated at the gateway.

Local-only mode requirements:
- Gateway SHALL support HTTP host routing for tenant hosts `<tenant_id>.local`.
- Gateway MAY expose a reserved local landing host such as `ourbox.local`.

Across both modes:
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
- `tenant_id` SHALL be derived from the request full host (leftmost DNS label).
- Services SHALL treat tenant context as required input and SHALL NOT accept `tenant_id` from untrusted client parameters as the primary authority when full host is present.

### 6.3 Authorization
Authorization SHALL consider:
- authenticated user identity (`user_id`)
- tenant derived from full host (`tenant_id`)
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
- "last write wins" vs explicit merges (if applicable)

(Exact policies are doc-kind specific and out of scope for this AD.)

---

## 8 Operational considerations (informative)

### 8.1 CouchDB maintenance
Operational hygiene includes:
- compaction schedules
- monitoring revision growth and storage use
- clear reporting of "what is taking storage?"

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

### 10.1 App URLs
- local-only mode: `http://bob.local/simplenote`
- public custom-domain mode: `https://bob.<box-host>/simplenote`
- local-only mode: `http://alice.local/calendar`
- public custom-domain mode: `https://alice.<box-host>/calendar`

### 10.2 CouchDB tenant DBs
- `tenant_bob`
- `tenant_alice`
- `tenant_family`

### 10.3 Replication endpoints
- local-only mode: `http://bob.local/db`
- public custom-domain mode: `https://bob.<box-host>/db`
- local-only mode: `http://family.local/db`
- public custom-domain mode: `https://family.<box-host>/db`

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

### APP-001: Shipped apps SHALL provide full installable-PWA posture in public custom-domain mode

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Aligns shipped-app installability guarantees with mode-specific browser behavior.

In public custom-domain mode, shipped OurBox apps SHALL be installable PWAs that can load from cache after the first successful online session.

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

### APP-004: Apps SHALL operate within a mode-aware tenant origin

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Tenant origins define storage isolation and routing in both access modes.

Shipped apps SHALL be served under mode-aware tenant origins:
- local-only mode: `http://<tenant_id>.local/<app_slug>`
- public custom-domain mode: `https://<tenant_id>.<box-host>/<app_slug>`

Tenant context SHALL be derived from the full host; `tenant_id` is the leftmost DNS label.

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

### APP-007: Local-only mode SHALL be HTTP-only

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Local-only mode is served on local HTTP tenant origins and does not depend on TLS.

Local-only mode SHALL use `http://<tenant_id>.local/...` and SHALL NOT require or imply HTTPS/TLS.

### APP-008: Local-only mode documentation SHALL NOT promise public-mode-equivalent full PWA posture

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Documentation must accurately distinguish local-only limits from public custom-domain guarantees.

Local-only mode SHALL NOT be documented as guaranteeing installability or reopen-offline behavior equivalent to public custom-domain mode.

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

### K8S-002: Gateway ingress SHALL support public custom-domain wildcard tenant hosts

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** Public custom-domain tenant hosts rely on wildcard routing.

Ingress configuration for public custom-domain mode SHALL support wildcard host routing for `*.<box-host>`.

### K8S-003: Shipped app workloads SHOULD use dedicated namespaces

**Status:** Draft  
**Testable:** false  
**Area:** k8s  
**Rationale:** Separates app operations while keeping tenant boundaries intact.

Shipped app workload bundles SHOULD run in their own Kubernetes namespaces to simplify operations
and isolation from platform services.

### K8S-010: Gateway routing SHALL support local-only tenant hosts over HTTP

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** Local-only mode requires explicit HTTP host routing for tenant hosts.

Gateway routing configuration SHALL support local-only tenant hosts `<tenant_id>.local` over HTTP.

Gateway routing MAY also expose a reserved local landing host such as `ourbox.local`.

---

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

---

# SRS-0202: CouchDB Service Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-01-31
**Status:** Draft

This specification defines the software requirements for the on-box **CouchDB service** (system-of-record for tenant DBs). It is a minimal scaffold; detailed requirements live in section records and the authoritative Glossary.

## Normative Language

Normative keywords (SHALL, SHALL NOT, SHOULD, SHOULD NOT, MAY) and OurBox OS product/architecture vocabulary are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

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
- [[spec:SRS-0203]]
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

Concrete in-cluster service interfaces (Service names, ports, authentication material, internal URLs, and any network policy)
are defined by the versioned deployment baseline manifests and are discoverable via cluster inspection (ADR-0008).

Any additional protocol-level contracts introduced between services (beyond what the deployment baseline expresses) are defined
as machine-readable contract artifacts (OpenAPI/JSON schema) and verified by automated tests.

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

Normative keywords (SHALL, SHALL NOT, SHOULD, SHOULD NOT, MAY) and OurBox OS product/architecture vocabulary are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

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

### K8S-002: Gateway ingress SHALL support public custom-domain wildcard tenant hosts

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** Public custom-domain tenant hosts rely on wildcard routing.

Ingress configuration for public custom-domain mode SHALL support wildcard host routing for `*.<box-host>`.

### K8S-003: Shipped app workloads SHOULD use dedicated namespaces

**Status:** Draft  
**Testable:** false  
**Area:** k8s  
**Rationale:** Separates app operations while keeping tenant boundaries intact.

Shipped app workload bundles SHOULD run in their own Kubernetes namespaces to simplify operations
and isolation from platform services.

### K8S-010: Gateway routing SHALL support local-only tenant hosts over HTTP

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** Local-only mode requires explicit HTTP host routing for tenant hosts.

Gateway routing configuration SHALL support local-only tenant hosts `<tenant_id>.local` over HTTP.

Gateway routing MAY also expose a reserved local landing host such as `ourbox.local`.

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

Operational procedures and any operator-facing commands are documented as operational runbooks and validated by conformance tests
where feasible. The deployment baseline manifests are the authoritative definition of platform topology and configuration (ADR-0008).

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

Normative keywords (SHALL, SHALL NOT, SHOULD, SHOULD NOT, MAY) and OurBox OS product/architecture vocabulary are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

## Introduction

This SRS defines requirements for the **local tenant replica** on client devices: the PouchDB database (IndexedDB-backed) within a tenant origin that enables offline-first behavior.

Key posture (already established in architecture):
- many client devices may exist per tenant
- connectivity may be intermittent; sync is opportunistic
- storage isolation is by tenant origin (`http://<tenant_id>.local` or `https://<tenant_id>.<box-host>`), so the same tenant in local-only and public custom-domain mode is origin-split

Out of scope:
- on-box CouchDB service requirements (see `[[spec:SRS-0202]]`)
- gateway routing and `/db` mapping (see `[[spec:SRS-0201]]`)

## Referenced Documents

- `docs/00-Glossary/Terms-and-Definitions.md`
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

### LCR-002: Same tenant across local-only and public modes SHALL map to different local tenant replicas

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Browser-origin boundaries isolate storage and therefore isolate local tenant replica state by origin.

On the same browser/device, `http://<tenant_id>.local` and `https://<tenant_id>.<box-host>` are different origins for the same tenant and SHALL use different local tenant replicas.

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
- same-origin replication endpoints presented by the gateway:
  - `http://<tenant_id>.local/db`
  - `https://<tenant_id>.<box-host>/db`

For the same tenant on the same browser profile, local-only (`http://<tenant_id>.local`) and public custom-domain (`https://<tenant_id>.<box-host>`) are different origins and therefore different local tenant replicas.

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

Normative keywords (SHALL, SHALL NOT, SHOULD, SHOULD NOT, MAY) and OurBox OS product/architecture vocabulary are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

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

Client-visible blob upload/download interfaces (if/when introduced) are defined as tenant-origin HTTP surfaces and described via
machine-readable API contracts (OpenAPI/JSON schema), with conformance tests. This SRS specifies blob-store invariants and on-box storage
posture; HTTP/API surfaces are mediated by the Gateway and/or platform services.

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

Allocated requirements are included here for traceability; identity- and membership-specific requirements follow.

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

### GW-009: Gateway SHALL treat full-host-derived tenant context as authoritative

**Status:** Draft  
**Testable:** true  
**Area:** gateway  
**Rationale:** Prevent tenant confusion and parameter spoofing when full host is present.

When full host is present, `tenant_id` SHALL be derived from the leftmost DNS label of the request full host and SHALL NOT be accepted from untrusted client parameters as the primary authority.

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

**Trace:** `docs/00-Glossary/Terms-and-Definitions.md` (user_id)

### ID-002: tenant_id SHALL satisfy tenant-host DNS-label and CouchDB naming constraints

**Status:** Draft  
**Testable:** true  
**Area:** identity  
**Rationale:** Glossary defines tenant_id constraints required for tenant origins and tenant DB naming.

`tenant_id` SHALL be lowercase.

`tenant_id` SHALL be safe for use in DNS labels and as the leftmost DNS label of a tenant host.

`tenant_id` SHALL be safe for use in CouchDB database names.

**Trace:** `docs/00-Glossary/Terms-and-Definitions.md` (tenant_id)

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
- tenant derived from the full host (`tenant_id` from leftmost DNS label)
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

SimpleNote external interfaces are tenant-origin app/replication surfaces in both access modes.

- App route (local-only mode): `http://<tenant_id>.local/simplenote`
- App route (public custom-domain mode): `https://<tenant_id>.<box-host>/simplenote`
- Replication endpoint (local-only mode): `http://<tenant_id>.local/db`
- Replication endpoint (public custom-domain mode): `https://<tenant_id>.<box-host>/db`
- Local storage: shared local tenant replica `tenant_local` within the current tenant origin

Public custom-domain mode is the full installable-PWA posture. Local-only mode remains HTTP local mode with local data continuity and opportunistic sync, without equivalent full installability/reopen-offline guarantees.

## Verification

Verification provisions (methods, environments, and trace links to evidence) will be defined here.
Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

### Allocated System Requirements (from SyRS)

System-level application requirements allocated to SimpleNote are included here for traceability.

#### APP-001: Shipped apps SHALL provide full installable-PWA posture in public custom-domain mode

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Aligns shipped-app installability guarantees with mode-specific browser behavior.

In public custom-domain mode, shipped OurBox apps SHALL be installable PWAs that can load from cache after the first successful online session.

#### APP-002: Shipped apps SHALL persist working data locally

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Offline writes depend on local persistence.

Shipped apps SHALL store working data locally in the tenant origin using PouchDB-backed IndexedDB.

#### APP-003: Shipped apps SHALL sync opportunistically

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Supports sporadic connectivity while keeping data consistent.

Shipped apps SHALL initiate incremental replication with the tenant DB when connectivity is available.

#### APP-004: Apps SHALL operate within a mode-aware tenant origin

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Tenant origins define storage isolation and routing in both access modes.

Shipped apps SHALL be served under mode-aware tenant origins:
- local-only mode: `http://<tenant_id>.local/<app_slug>`
- public custom-domain mode: `https://<tenant_id>.<box-host>/<app_slug>`

Tenant context SHALL be derived from the full host; `tenant_id` is the leftmost DNS label.

#### APP-005: Apps SHALL share one local tenant replica per origin

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Ensures apps share doc kinds offline.

All shipped apps under the same tenant origin SHALL read and write through a single local tenant
replica database on that device.

#### APP-006: Apps SHALL honor doc-kind contracts

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Shared storage requires strict doc-kind boundaries.

Shipped apps SHALL only create and update documents whose `_id` prefixes match the stable doc-kind
vocabulary defined for OurBox OS.

#### APP-007: Local-only mode SHALL be HTTP-only

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Local-only mode is served on local HTTP tenant origins and does not depend on TLS.

Local-only mode SHALL use `http://<tenant_id>.local/...` and SHALL NOT require or imply HTTPS/TLS.

#### APP-008: Local-only mode documentation SHALL NOT promise public-mode-equivalent full PWA posture

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Documentation must accurately distinguish local-only limits from public custom-domain guarantees.

Local-only mode SHALL NOT be documented as guaranteeing installability or reopen-offline behavior equivalent to public custom-domain mode.

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

RichNote external interfaces are tenant-origin app/replication surfaces in both access modes.

- App route (local-only mode): `http://<tenant_id>.local/richnote`
- App route (public custom-domain mode): `https://<tenant_id>.<box-host>/richnote`
- Replication endpoint (local-only mode): `http://<tenant_id>.local/db`
- Replication endpoint (public custom-domain mode): `https://<tenant_id>.<box-host>/db`
- Local storage: shared local tenant replica `tenant_local` within the current tenant origin

Public custom-domain mode is the full installable-PWA posture. Local-only mode remains HTTP local mode with local data continuity and opportunistic sync, without equivalent full installability/reopen-offline guarantees.

## Verification

Verification provisions (methods, environments, and trace links to evidence) will be defined here.
Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

### Allocated System Requirements (from SyRS)

System-level application requirements allocated to RichNote are included here for traceability.

#### APP-001: Shipped apps SHALL provide full installable-PWA posture in public custom-domain mode

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Aligns shipped-app installability guarantees with mode-specific browser behavior.

In public custom-domain mode, shipped OurBox apps SHALL be installable PWAs that can load from cache after the first successful online session.

#### APP-002: Shipped apps SHALL persist working data locally

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Offline writes depend on local persistence.

Shipped apps SHALL store working data locally in the tenant origin using PouchDB-backed IndexedDB.

#### APP-003: Shipped apps SHALL sync opportunistically

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Supports sporadic connectivity while keeping data consistent.

Shipped apps SHALL initiate incremental replication with the tenant DB when connectivity is available.

#### APP-004: Apps SHALL operate within a mode-aware tenant origin

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Tenant origins define storage isolation and routing in both access modes.

Shipped apps SHALL be served under mode-aware tenant origins:
- local-only mode: `http://<tenant_id>.local/<app_slug>`
- public custom-domain mode: `https://<tenant_id>.<box-host>/<app_slug>`

Tenant context SHALL be derived from the full host; `tenant_id` is the leftmost DNS label.

#### APP-005: Apps SHALL share one local tenant replica per origin

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Ensures apps share doc kinds offline.

All shipped apps under the same tenant origin SHALL read and write through a single local tenant
replica database on that device.

#### APP-006: Apps SHALL honor doc-kind contracts

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Shared storage requires strict doc-kind boundaries.

Shipped apps SHALL only create and update documents whose `_id` prefixes match the stable doc-kind
vocabulary defined for OurBox OS.

#### APP-007: Local-only mode SHALL be HTTP-only

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Local-only mode is served on local HTTP tenant origins and does not depend on TLS.

Local-only mode SHALL use `http://<tenant_id>.local/...` and SHALL NOT require or imply HTTPS/TLS.

#### APP-008: Local-only mode documentation SHALL NOT promise public-mode-equivalent full PWA posture

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Documentation must accurately distinguish local-only limits from public custom-domain guarantees.

Local-only mode SHALL NOT be documented as guaranteeing installability or reopen-offline behavior equivalent to public custom-domain mode.

---

# SRS-1003: Messager Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-02-25
**Status:** Draft

This specification defines the software requirements for the **Messager** application.

Messager is a shipped, tenant-scoped messaging experience for OurBox OS. It is designed for multi-user
communication within a tenant without introducing “private compartments” inside the tenant boundary,
aligning with the principle that the tenant is the social boundary.

## Normative Language

The key words **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, and **MAY** are to be interpreted as
requirements.

OurBox OS vocabulary and normative definitions are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

## Introduction

This SRS defines requirements for the **Messager** app experience.

Scope includes:
- tenant-scoped channels and messages
- offline-first behavior consistent with ADR-0001 posture
- shared local tenant replica usage (`tenant_local`)
- message document model and attachment handling using the tenant blob store
- optional voice/video calls within the tenant boundary
- optional bot/automation behavior within tenant membership semantics

Out of scope:
- interoperability with external messaging ecosystems (e.g., SMS, email, Matrix, ActivityPub)
- privacy compartments inside a tenant (DMs, secret channels) — use separate tenants instead

## Referenced Documents

- `docs/00-Glossary/Terms-and-Definitions.md`
- [[spec:SyRS-0001]]
- [[arch_doc:AD-0001]]
- [[adr:ADR-0001]]
- [[adr:ADR-0002]]
- [[adr:ADR-0003]]
- [[adr:ADR-0004]]
- [[adr:ADR-0005]]
- [[adr:ADR-0006]]
- [[spec:SRS-0201]]
- [[spec:SRS-0204]]
- [[spec:SRS-0205]]
- [[spec:SRS-0206]]

## Requirements

Allocated system requirements from `[[spec:SyRS-0001]]` are included here for traceability; Messager-specific requirements follow.

### Allocated System Requirements (from SyRS)

#### APP-001: Shipped apps SHALL provide full installable-PWA posture in public custom-domain mode

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Aligns shipped-app installability guarantees with mode-specific browser behavior.

In public custom-domain mode, shipped OurBox apps SHALL be installable PWAs that can load from cache after the first successful online session.

#### APP-002: Shipped apps SHALL persist working data locally

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Offline writes depend on local persistence.

Shipped apps SHALL store working data locally in the tenant origin using PouchDB-backed IndexedDB.

#### APP-003: Shipped apps SHALL sync opportunistically

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Supports sporadic connectivity while keeping data consistent.

Shipped apps SHALL initiate incremental replication with the tenant DB when connectivity is available.

#### APP-004: Apps SHALL operate within a mode-aware tenant origin

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Tenant origins define storage isolation and routing in both access modes.

Shipped apps SHALL be served under mode-aware tenant origins:
- local-only mode: `http://<tenant_id>.local/<app_slug>`
- public custom-domain mode: `https://<tenant_id>.<box-host>/<app_slug>`

Tenant context SHALL be derived from the full host; `tenant_id` is the leftmost DNS label.

#### APP-005: Apps SHALL share one local tenant replica per origin

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Ensures apps share doc kinds offline.

All shipped apps under the same tenant origin SHALL read and write through a single local tenant
replica database on that device.

#### APP-006: Apps SHALL honor doc-kind contracts

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Shared storage requires strict doc-kind boundaries.

Shipped apps SHALL only create and update documents whose `_id` prefixes match the stable doc-kind
vocabulary defined for OurBox OS.

#### APP-007: Local-only mode SHALL be HTTP-only

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Local-only mode is served on local HTTP tenant origins and does not depend on TLS.

Local-only mode SHALL use `http://<tenant_id>.local/...` and SHALL NOT require or imply HTTPS/TLS.

#### APP-008: Local-only mode documentation SHALL NOT promise public-mode-equivalent full PWA posture

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Documentation must accurately distinguish local-only limits from public custom-domain guarantees.

Local-only mode SHALL NOT be documented as guaranteeing installability or reopen-offline behavior equivalent to public custom-domain mode.

### Functional and Data Requirements (Messager-specific)

#### MSG-001: Messager SHALL treat the tenant as the social boundary

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Avoid private compartments; tenant is the unit of social trust.

Messager SHALL treat the tenant boundary as the only privacy/social boundary.

All tenant members with `messager:read` capability SHALL be able to read all messages in the tenant.

If users require a private compartment, they SHALL create a separate tenant instead of creating DMs inside a tenant.

#### MSG-002: Messager SHALL NOT implement private compartments within a tenant

**Status:** Draft  
**Testable:** true  
**Area:** security  
**Rationale:** Private compartments inside a tenant are confusing and dangerous; use tenants instead.

Messager SHALL NOT implement:
- direct/private messages scoped to a subset of tenant members,
- “secret” channels with per-channel membership ACLs,
- per-message encryption keys that exclude some tenant members.

Any feature that materially restricts message visibility MUST be implemented by using a separate tenant.

#### MSG-003: Messager SHALL operate within a tenant origin

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Tenant origins define storage isolation and routing (AD-0001).

Messager SHALL be served under tenant-origin mode-aware routes (`http://<tenant_id>.local/messager` and `https://<tenant_id>.<box-host>/messager`) and SHALL derive tenant context from the full host (leftmost DNS label = `tenant_id`).

#### MSG-004: Messager SHALL use the shared local tenant replica

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Shared local tenant replica is required for offline-first behavior and cross-app doc sharing (SyRS APP-005).

Messager SHALL read and write its documents through the shared local tenant replica `tenant_local` within the tenant origin.

#### MSG-005: Messager SHALL provide tenant-wide channels

**Status:** Draft  
**Testable:** true  
**Area:** messaging  
**Rationale:** Provide organization without introducing private compartments.

Messager SHALL provide one or more tenant-wide message channels.

Channel membership SHALL NOT be restricted within the tenant.

Messager SHALL provide a default channel (e.g., `general`).

#### MSG-006: Messager SHALL support real-time-ish updates via replication

**Status:** Draft  
**Testable:** true  
**Area:** messaging  
**Rationale:** Leverages CouchDB/PouchDB replication for incremental updates without custom protocols.

Messager SHOULD use live/continuous replication (or periodic incremental replication) to deliver near-real-time updates when the box is reachable.

Messager SHALL remain functional when the box is unreachable after first load.

#### MSG-007: Messager SHALL support end-to-end offline messaging

**Status:** Draft  
**Testable:** true  
**Area:** offline  
**Rationale:** Offline-first posture: messages must be creatable and viewable without connectivity.

Messages composed offline SHALL be persisted locally immediately and appear in the UI.

When connectivity returns, messages SHALL replicate automatically to the tenant DB via `/db` without user intervention.

#### MSG-008: Messager SHALL support file and media attachments

**Status:** Draft  
**Testable:** true  
**Area:** messaging  
**Rationale:** Messaging commonly includes images/audio/files; blob store is the canonical posture.

Messager SHALL support attaching files/media to messages.

Attachment metadata (filename, MIME type, size, and blob reference) SHALL be stored in message documents.

Attachment payload bytes SHALL be stored in the tenant blob store by default (see MSG-009).

#### MSG-009: Messager SHALL store attachment payload bytes in the tenant blob store by default

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Align with ADR-0002/ADR-0005 posture: blobs outside CouchDB, content-addressed, tenant-scoped.

Messager SHALL NOT store attachment payload bytes as CouchDB attachments by default.

Instead, Messager SHALL store attachment payload bytes in the tenant blob store and store only content-addressed references (e.g., multihash/CID) in message documents.

**Trace:** [[spec:SyRS-0001]] DATA-006, DATA-007; [[adr:ADR-0005]]; [[adr:ADR-0006]].

#### MSG-010: Messager SHOULD support offline staging of attachments

**Status:** Draft  
**Testable:** false  
**Area:** offline  
**Rationale:** Improves usability on unstable networks; staging may be complex due to blob-store APIs.

Messager SHOULD allow users to attach files while offline by staging payload bytes locally and uploading them to the tenant blob store when connectivity returns.

If offline staging is not supported, Messager SHALL communicate clearly that attachments require connectivity.

#### MSG-011: Messager SHALL support voice notes

**Status:** Draft  
**Testable:** true  
**Area:** messaging  
**Rationale:** Voice notes are a common low-friction messaging primitive.

Messager SHALL allow users to record and send voice notes.

Voice note audio payload bytes SHALL be stored as blobs in the tenant blob store, referenced from a message document.

#### MSG-012: Messager SHALL support sharing existing tenant documents by reference

**Status:** Draft  
**Testable:** true  
**Area:** integration  
**Rationale:** Apps share one local tenant replica; sharing should be references, not copies.

Messager SHALL allow messages to reference existing tenant documents by `_id`.

Example: a message may reference a `note:*` document or a `task:*` document.

Messager SHALL NOT duplicate the referenced document as a message payload.

#### MSG-013: Messager SHALL define messaging doc kinds and commit to stable doc-kind vocabulary tokens

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Shared storage requires stable doc kinds and clear contracts (AD-0001 §9.2).

Messager SHALL store its primary documents using doc kinds encoded in `_id`.

Messager SHALL introduce the following doc kinds (stable vocabulary tokens):
- `thread` — channel/thread metadata
- `msg` — message documents
- `call` — call history documents

Each doc kind SHALL be documented with:
- required and optional fields,
- indexing/query posture,
- conflict handling posture.

**Trace:** [[arch_doc:AD-0001]] §9.2 (Adding a new doc kind).

#### MSG-014: Messager message documents SHALL be immutable after creation

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Append-only messaging avoids conflicts and reduces complexity.

After a `msg:*` document is created, Messager SHALL treat it as immutable.

Edits and deletions of messages SHOULD NOT be supported in the v0 posture.

If redaction/moderation is required in future, it SHALL be implemented via additional documents (not in-place mutation).

#### MSG-015: Messager SHALL provide deterministic message ordering

**Status:** Draft  
**Testable:** true  
**Area:** messaging  
**Rationale:** Replication and intermittent connectivity require stable ordering for rendering.

Messager SHALL render messages in a deterministic order.

Recommended ordering (normative):
1) `created_at` timestamp ascending,
2) tie-break by `_id` ascending.

Messager SHALL tolerate clock skew across devices by not assuming timestamps are globally accurate.

#### MSG-016: Messager SHALL support voice and video calls between tenant members

**Status:** Draft  
**Testable:** true  
**Area:** calling  
**Rationale:** Calls are a canonical “phone-like OS” primitive; tenant boundary keeps it legible.

Messager SHALL support initiating and receiving real-time voice and video calls between tenant members.

Call participation SHALL be limited to tenant members (per membership enforced by the Gateway).

#### MSG-017: Messager call signaling SHALL be same-origin with the tenant

**Status:** Draft  
**Testable:** true  
**Area:** calling  
**Rationale:** Avoid CORS/topology coupling; align with tenant-origin routing posture.

Call signaling (offer/answer/ICE exchange) SHALL occur over a tenant-origin surface:
- local-only mode: `http://<tenant_id>.local/api/messager/call/...`
- public custom-domain mode: `https://<tenant_id>.<box-host>/api/messager/call/...`

The Gateway SHALL enforce tenant membership on signaling endpoints.

(Exact signaling protocol is out of scope; WebRTC is assumed.)

#### MSG-018: Messager SHALL record durable call history in the tenant DB

**Status:** Draft  
**Testable:** true  
**Area:** calling  
**Rationale:** Call history is user-visible state and must replicate across devices.

Messager SHALL record call events (missed/received/placed, participants, start/end times) as durable documents in the tenant DB (doc kind `call`).

Call history SHALL be visible to all tenant members with `messager:read` capability.

#### MSG-019: Messager SHALL support bots as ordinary users

**Status:** Draft  
**Testable:** true  
**Area:** automation  
**Rationale:** Bots should be legible: they are users with memberships/capabilities.

Messager SHALL support bot accounts implemented as ordinary `user_id` identities with tenant membership.

Bots SHALL NOT bypass tenant membership enforcement.

Bots MAY post messages and attachments subject to the same capability checks as humans.

#### MSG-020: Messager SHALL NOT require external messaging networks or federation

**Status:** Draft  
**Testable:** true  
**Area:** constraint  
**Rationale:** Explicit product posture: no external interop requirement; keep implementation small and legible.

Messager SHALL NOT require interoperability with external messaging ecosystems.

Messager SHALL NOT implement federated identity, cross-instance message routing, or third-party network bridges in the v0 posture.

#### MSG-021: Messager SHOULD provide a tenant-scoped encryption mode without creating intra-tenant compartments

**Status:** Draft  
**Testable:** false  
**Area:** security  
**Rationale:** Encryption is desirable, but must not create intra-tenant compartments; operator truth still applies.

Messager SHOULD provide an encryption mode where message payloads are encrypted at rest in the tenant DB/blob store.

If implemented, encryption keys SHALL be tenant-scoped and available to all tenant members (subject to membership), not per-channel or per-DM.

This feature SHALL NOT claim confidentiality from the device operator (Operator Truth).

#### MSG-022: Messager SHOULD minimize client resource footprint

**Status:** Draft  
**Testable:** false  
**Area:** quality  
**Rationale:** Align with “low profile code” posture: minimal RAM/CPU and small bundle size.

Messager SHOULD minimize client resource usage by:
- using pagination/virtualized lists for long timelines,
- avoiding loading unbounded message history into memory,
- limiting background timers and watchers,
- keeping client bundle size small.

Resource budgets (exact numbers) are defined in performance test baselines, not in this SRS.

## External Interfaces

Messager external interfaces are tenant-origin app/replication surfaces in both access modes.

- App route (local-only mode): `http://<tenant_id>.local/messager`
- App route (public custom-domain mode): `https://<tenant_id>.<box-host>/messager`
- Replication endpoint (local-only mode): `http://<tenant_id>.local/db`
- Replication endpoint (public custom-domain mode): `https://<tenant_id>.<box-host>/db`
- Local storage: shared local tenant replica `tenant_local` within the current tenant origin
- Attachments: tenant blob store (accessed via platform services / gateway-mediated APIs when present)

Public custom-domain mode is the full installable-PWA posture. Local-only mode remains HTTP local mode with local data continuity and opportunistic sync, without equivalent full installability/reopen-offline guarantees.

## Verification

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:
- **Test:** offline send/receive behavior using the local tenant replica; then reconnect and replicate successfully.
- **Inspection:** confirm no DM/private-channel UI or enforcement exists within a tenant.
- **Test:** attachment upload/download round-trip with blob references in message docs.
- **Test (optional):** voice/video call signaling and call-history persistence.

---

# SRS-1004: Scout Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-03-06
**Status:** Draft

This specification defines the software requirements for the **Scout** application.

Scout is a shipped, tenant-scoped civic intelligence experience for OurBox OS. It monitors user-chosen civic information sources and user-provided civic artifacts, then produces source-grounded briefings, extracted claims, issue tracking, and question-answering for the tenant.

## Normative Language

The key words **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, and **MAY** are to be interpreted as requirements.

OurBox OS vocabulary and normative definitions are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

## Introduction

This SRS defines requirements for the **Scout** app experience.

Scope includes:

* user-chosen civic source monitoring
* user-provided civic artifact analysis (e.g., political mailers, flyers, public notices, PDFs, screenshots)
* source snapshotting and provenance tracking
* issue, claim, and civic event/proceeding extraction
* source-grounded briefings and question-answering
* change-over-time comparison across watched sources

Out of scope:

* value-to-candidate matching and ballot guidance
* adversarial/perspective-challenging dialogue behavior
* standalone long-form event recording and evidence workflows
* standalone anti-censorship archiving/version-history workflows
* interoperability with third-party social networks or box-to-box distribution in the v0 posture

## Referenced Documents

* `docs/00-Glossary/Terms-and-Definitions.md`
* [[spec:SyRS-0001]]
* [[arch_doc:AD-0001]]
* [[adr:ADR-0001]]
* [[adr:ADR-0002]]
* [[adr:ADR-0003]]
* [[adr:ADR-0004]]
* [[adr:ADR-0005]]
* [[adr:ADR-0006]]
* [[spec:SRS-0201]]
* [[spec:SRS-0204]]
* [[spec:SRS-0205]]
* [[spec:SRS-0206]]

## Requirements

Allocated system requirements from `[[spec:SyRS-0001]]` are included here for traceability; Scout-specific requirements follow.

### Allocated System Requirements (from SyRS)

#### APP-001: Shipped apps SHALL provide full installable-PWA posture in public custom-domain mode

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Aligns shipped-app installability guarantees with mode-specific browser behavior.

In public custom-domain mode, shipped OurBox apps SHALL be installable PWAs that can load from cache after the first successful online session.

#### APP-002: Shipped apps SHALL persist working data locally

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Offline writes depend on local persistence.

Shipped apps SHALL store working data locally in the tenant origin using PouchDB-backed IndexedDB.

#### APP-003: Shipped apps SHALL sync opportunistically

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Supports sporadic connectivity while keeping data consistent.

Shipped apps SHALL initiate incremental replication with the tenant DB when connectivity is available.

#### APP-004: Apps SHALL operate within a mode-aware tenant origin

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Tenant origins define storage isolation and routing in both access modes.

Shipped apps SHALL be served under mode-aware tenant origins:
- local-only mode: `http://<tenant_id>.local/<app_slug>`
- public custom-domain mode: `https://<tenant_id>.<box-host>/<app_slug>`

Tenant context SHALL be derived from the full host; `tenant_id` is the leftmost DNS label.

#### APP-005: Apps SHALL share one local tenant replica per origin

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Ensures apps share doc kinds offline.

All shipped apps under the same tenant origin SHALL read and write through a single local tenant
replica database on that device.

#### APP-006: Apps SHALL honor doc-kind contracts

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Shared storage requires strict doc-kind boundaries.

Shipped apps SHALL only create and update documents whose `_id` prefixes match the stable doc-kind
vocabulary defined for OurBox OS.

#### APP-007: Local-only mode SHALL be HTTP-only

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Local-only mode is served on local HTTP tenant origins and does not depend on TLS.

Local-only mode SHALL use `http://<tenant_id>.local/...` and SHALL NOT require or imply HTTPS/TLS.

#### APP-008: Local-only mode documentation SHALL NOT promise public-mode-equivalent full PWA posture

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Documentation must accurately distinguish local-only limits from public custom-domain guarantees.

Local-only mode SHALL NOT be documented as guaranteeing installability or reopen-offline behavior equivalent to public custom-domain mode.

### Functional and Data Requirements (Scout-specific)

#### SCOUT-001: Scout SHALL monitor user-chosen civic information sources

**Status:** Draft  
**Testable:** true  
**Area:** scout  
**Rationale:** Scout is a civic intelligence app, not a generic feed; source selection must remain user-directed.

Scout SHALL allow the user to configure one or more watched civic information sources.

Watched sources SHALL be explicit tenant-visible configuration.

Scout SHALL support monitoring public internet sources selected by the user and SHALL NOT require a hidden platform-curated feed as the primary input to Scout coverage.

#### SCOUT-002: Scout SHALL accept user-provided civic artifacts for analysis

**Status:** Draft  
**Testable:** true  
**Area:** scout  
**Rationale:** Users often receive civic information outside normal web sources (e.g., political mailers, flyers, notices).

Scout SHALL accept user-provided civic artifacts for analysis.

At minimum, Scout SHALL accept:

* URL inputs,
* text/HTML inputs,
* image artifacts, and
* PDF artifacts.

Examples include political mailers, campaign flyers, candidate webpages, public notices, and issue handouts.

#### SCOUT-003: Scout SHALL preserve source snapshots and provenance

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Source-grounded civic analysis requires durable provenance and inspectable evidence.

For each fetched or uploaded artifact that Scout analyzes, Scout SHALL create or reference a `source:*` record and a `snapshot:*` record.

Each `snapshot:*` record SHALL include, at minimum:

* provenance (e.g., source URI or upload origin),
* observed/ingested timestamp,
* content hash/digest, and
* media type.

When source artifact payload bytes are binary or large, Scout SHALL store payload bytes in the tenant blob store by default and SHALL store only references in application documents.

**Trace:** [[spec:SyRS-0001]] DATA-006, DATA-007; [[spec:SRS-0205]]; [[adr:ADR-0005]]; [[adr:ADR-0006]]

#### SCOUT-004: Scout SHALL produce source-grounded briefings

**Status:** Draft  
**Testable:** true  
**Area:** scout  
**Rationale:** Scout’s primary user-visible value is turning civic source material into readable briefings without severing the link to evidence.

Scout SHALL generate plain-language briefings over watched sources, issues, and civic events/proceedings.

Each nontrivial factual assertion presented in a briefing SHALL be traceable to one or more underlying `snapshot:*` records available to the user.

Briefings SHALL present source links or references sufficient for user inspection.

#### SCOUT-005: Scout SHALL distinguish source material, extraction, and generation

**Status:** Draft  
**Testable:** true  
**Area:** transparency  
**Rationale:** Users must be able to tell what came from the source, what was extracted, and what was generated by AI.

Scout SHALL distinguish between:

* captured or quoted source material,
* extracted structured observations, and
* AI-generated summaries or synthesized briefings.

At minimum, Scout SHALL distinguish:

* source text/media,
* extracted issues, claims, names, dates, and actions,
* generated summaries, narratives, or explanations.

#### SCOUT-006: Scout SHALL extract issues, claims, and civic events/proceedings from sources

**Status:** Draft  
**Testable:** true  
**Area:** scout  
**Rationale:** Scout’s civic intelligence value depends on structured extraction rather than simple bookmarking.

Scout SHALL extract issue, claim, and civic event/proceeding information from analyzed sources when supported by source evidence.

Where Scout materializes a civic event or proceeding as a durable application document, Scout SHALL use the existing `event:*` doc kind.

Scout SHALL surface referenced public actors (e.g., candidates, committees, agencies, organizations) in briefings and query results when detected in source material.

#### SCOUT-007: Scout SHALL answer questions over the watched corpus with citations and explicit insufficiency

**Status:** Draft  
**Testable:** true  
**Area:** scout  
**Rationale:** Question-answering is only trustworthy when grounded in the watched corpus and honest about gaps.

Scout SHALL answer user questions over the watched corpus with citations to underlying `snapshot:*` records.

When sufficient evidence is not available in the watched corpus, Scout SHALL say so explicitly and SHALL NOT present unsupported certainty as established fact.

#### SCOUT-008: Scout SHALL support change-over-time comparison across watched sources

**Status:** Draft  
**Testable:** true  
**Area:** scout  
**Rationale:** Political webpages, issue statements, and campaign material change over time; users need “what changed?” as a first-class capability.

Where multiple `snapshot:*` records exist for the same source or materially related source chain, Scout SHALL support change-over-time comparison.

Scout SHALL be able to surface additions, removals, and materially changed claims when determinable from the available evidence.

#### SCOUT-009: Scout SHALL keep prioritization and following rules user-visible and user-controlled

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Scout is meant to strengthen citizen judgment, not to hide agenda-setting behind an opaque ranking system.

Scout SHALL present watched sources, followed issues, and prioritization/ranking rules as tenant-visible configuration.

Scout SHALL NOT use hidden engagement optimization as the primary method for deciding what civic information to surface to the user.

#### SCOUT-010: Scout SHALL define Scout doc kinds and commit to stable doc-kind vocabulary tokens

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Shared storage across apps requires stable civic doc kinds and explicit contracts.

Scout SHALL store its primary documents using doc kinds encoded in `_id`.

Scout SHALL introduce the following doc kinds (stable vocabulary tokens):

* `source` — watched source identity/configuration
* `snapshot` — captured source artifact at a point in time
* `issue` — canonical civic issue/topic record
* `claim` — extracted claim tied to one or more snapshots
* `brief` — user-facing briefing generated from source material
* `watch` — user watch/follow configuration

Each doc kind SHALL be documented with:

* required and optional fields,
* indexing/query posture,
* conflict handling posture.

**Trace:** [[arch_doc:AD-0001]] §9.2

#### SCOUT-011: Scout-generated briefings SHALL record generation provenance

**Status:** Draft  
**Testable:** true  
**Area:** transparency  
**Rationale:** Users need inspectable generation context for civic briefings.

Each `brief:*` document generated by Scout SHALL record generation provenance.

At minimum, a `brief:*` document SHALL record:

* input snapshot IDs,
* generation time,
* model/runtime identifier, and
* any user-selected briefing scope or watch criteria used.

#### SCOUT-012: Scout source snapshots SHALL be immutable after creation

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Provenance and change-over-time analysis depend on immutable historical capture records.

After a `snapshot:*` document is created, Scout SHALL treat it as immutable.

Corrections, annotations, or re-ingests SHALL be represented as new documents or linked documents rather than by overwriting the original snapshot.

#### SCOUT-013: Scout SHOULD support on-demand and scheduled briefings

**Status:** Draft  
**Testable:** false  
**Area:** scout  
**Rationale:** Users benefit from both pull-based research and push-style periodic summary.

Scout SHOULD support:

* on-demand briefings for watched issues,
* on-demand briefings for candidates or organizations referenced in the watched corpus, and
* scheduled digests covering recent changes across watched sources.

## External Interfaces

Scout external interfaces are tenant-origin app/replication surfaces in both access modes.

- App route (local-only mode): `http://<tenant_id>.local/scout`
- App route (public custom-domain mode): `https://<tenant_id>.<box-host>/scout`
- Replication endpoint (local-only mode): `http://<tenant_id>.local/db`
- Replication endpoint (public custom-domain mode): `https://<tenant_id>.<box-host>/db`
- Local storage: shared local tenant replica `tenant_local` within the current tenant origin
- Source artifacts and retained binary snapshots: tenant blob store (when binary/large)
- Optional service APIs: `/api/scout/...` on the current tenant origin

Public custom-domain mode is the full installable-PWA posture. Local-only mode remains HTTP local mode with local data continuity and opportunistic sync, without equivalent full installability/reopen-offline guarantees.

## Verification

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:

* **Test:** configure a watched public source, ingest content, and generate a source-grounded briefing with citations.
* **Test:** upload a political mailer image or PDF and confirm Scout extracts claims, issue references, and source-backed briefing output.
* **Test:** ingest two versions of the same source and confirm Scout surfaces change-over-time differences.
* **Test:** ask a question over the watched corpus and confirm the answer cites supporting `snapshot:*` records or explicitly states insufficient evidence.
* **Inspection:** confirm watched sources and prioritization rules are explicit tenant-visible configuration and that no hidden feed is the primary ranking mechanism.
* **Test:** confirm previously generated briefings and supporting source excerpts remain readable offline after first successful load.

---

# SRS-1005: Compass Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-03-06
**Status:** Draft

This specification defines the software requirements for the **Compass** application.

Compass is a shipped, tenant-scoped civic decision-support experience for OurBox OS. It helps users map explicit civic values, priorities, and red lines to source-grounded candidate positions within a user-selected contest scope.

## Normative Language

The key words **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, and **MAY** are to be interpreted as requirements.

OurBox OS vocabulary and normative definitions are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

## Introduction

This SRS defines requirements for the **Compass** app experience.

Scope includes:

* explicit user civic values, priorities, red lines, and tradeoff capture
* user-selected contest scope and candidate-set evaluation
* candidate and contest material analysis
* source-grounded stance extraction
* transparent candidate-fit evaluation against explicit user values
* side-by-side candidate comparison within a contest

Out of scope:

* broad civic source monitoring and general-purpose issue reporting
* adversarial/perspective-challenging dialogue behavior
* standalone long-form event recording and evidence workflows
* standalone anti-censorship archiving/version-history workflows
* official election-administration guidance (e.g., registration deadlines, polling-place procedures)
* campaign persuasion optimization, voter targeting, or hidden behavioral ranking

## Referenced Documents

* `docs/00-Glossary/Terms-and-Definitions.md`
* [[spec:SyRS-0001]]
* [[arch_doc:AD-0001]]
* [[adr:ADR-0001]]
* [[adr:ADR-0002]]
* [[adr:ADR-0003]]
* [[adr:ADR-0004]]
* [[adr:ADR-0005]]
* [[adr:ADR-0006]]
* [[spec:SRS-0201]]
* [[spec:SRS-0204]]
* [[spec:SRS-0205]]
* [[spec:SRS-0206]]
* [[spec:SRS-1004]]

## Requirements

Allocated system requirements from `[[spec:SyRS-0001]]` are included here for traceability; Compass-specific requirements follow.

### Allocated System Requirements (from SyRS)

#### APP-001: Shipped apps SHALL provide full installable-PWA posture in public custom-domain mode

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Aligns shipped-app installability guarantees with mode-specific browser behavior.

In public custom-domain mode, shipped OurBox apps SHALL be installable PWAs that can load from cache after the first successful online session.

#### APP-002: Shipped apps SHALL persist working data locally

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Offline writes depend on local persistence.

Shipped apps SHALL store working data locally in the tenant origin using PouchDB-backed IndexedDB.

#### APP-003: Shipped apps SHALL sync opportunistically

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Supports sporadic connectivity while keeping data consistent.

Shipped apps SHALL initiate incremental replication with the tenant DB when connectivity is available.

#### APP-004: Apps SHALL operate within a mode-aware tenant origin

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Tenant origins define storage isolation and routing in both access modes.

Shipped apps SHALL be served under mode-aware tenant origins:
- local-only mode: `http://<tenant_id>.local/<app_slug>`
- public custom-domain mode: `https://<tenant_id>.<box-host>/<app_slug>`

Tenant context SHALL be derived from the full host; `tenant_id` is the leftmost DNS label.

#### APP-005: Apps SHALL share one local tenant replica per origin

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Ensures apps share doc kinds offline.

All shipped apps under the same tenant origin SHALL read and write through a single local tenant
replica database on that device.

#### APP-006: Apps SHALL honor doc-kind contracts

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Shared storage requires strict doc-kind boundaries.

Shipped apps SHALL only create and update documents whose `_id` prefixes match the stable doc-kind
vocabulary defined for OurBox OS.

#### APP-007: Local-only mode SHALL be HTTP-only

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Local-only mode is served on local HTTP tenant origins and does not depend on TLS.

Local-only mode SHALL use `http://<tenant_id>.local/...` and SHALL NOT require or imply HTTPS/TLS.

#### APP-008: Local-only mode documentation SHALL NOT promise public-mode-equivalent full PWA posture

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Documentation must accurately distinguish local-only limits from public custom-domain guarantees.

Local-only mode SHALL NOT be documented as guaranteeing installability or reopen-offline behavior equivalent to public custom-domain mode.

### Functional and Data Requirements (Compass-specific)

#### COMPASS-001: Compass SHALL capture explicit user civic values and priorities

**Status:** Draft  
**Testable:** true  
**Area:** compass  
**Rationale:** Compass exists to help users apply their own values to civic choices; those values must be explicit rather than implicit.

Compass SHALL allow the user to create one or more explicit civic values profiles.

A civic values profile SHALL support, at minimum:

* named priorities,
* issue preferences,
* red lines or non-negotiable concerns, and
* relative weighting or tradeoff inputs sufficient for candidate-fit evaluation.

#### COMPASS-002: Compass SHALL treat the user values profile as user-visible, user-editable configuration

**Status:** Draft  
**Testable:** true  
**Area:** transparency  
**Rationale:** Compass should strengthen user agency, not replace it with hidden psychographic inference.

Compass SHALL present the active civic values profile as tenant-visible, user-editable configuration.

Compass SHALL NOT require hidden psychographic inference as the primary authority for candidate-fit evaluation when an explicit user profile is present.

#### COMPASS-003: Compass SHALL operate on a user-selected contest scope and candidate set

**Status:** Draft  
**Testable:** true  
**Area:** compass  
**Rationale:** Candidate matching is only meaningful within a contest scope the user can inspect and confirm.

Compass SHALL allow the user to select, confirm, or provide the contest scope and candidate set to be evaluated.

Any location-, district-, or ballot-scope derivation used by Compass SHALL remain user-visible and user-confirmable.

The user-confirmed contest scope SHALL be authoritative for Compass candidate-fit evaluation.

#### COMPASS-004: Compass SHALL accept candidate and contest materials for analysis

**Status:** Draft  
**Testable:** true  
**Area:** compass  
**Rationale:** Users need to evaluate candidates from real materials such as websites, mailers, debate transcripts, and handouts.

Compass SHALL accept candidate and contest materials for analysis.

At minimum, Compass SHALL accept:

* URL inputs,
* text/HTML inputs,
* image artifacts, and
* PDF artifacts.

Examples include candidate webpages, political mailers, debate transcripts, campaign flyers, voter guides, and issue handouts.

#### COMPASS-005: Compass SHALL preserve source provenance for candidate and contest materials

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Values-to-candidate matching must remain inspectable and tied back to evidence.

For each fetched or uploaded artifact that Compass analyzes, Compass SHALL create or reference a `source:*` record and a `snapshot:*` record.

Each referenced or created `snapshot:*` record SHALL include, at minimum:

* provenance (e.g., source URI or upload origin),
* observed/ingested timestamp,
* content hash/digest, and
* media type.

When source artifact payload bytes are binary or large, Compass SHALL store payload bytes in the tenant blob store by default and SHALL store only references in application documents.

**Trace:** [[spec:SyRS-0001]] DATA-006, DATA-007; [[spec:SRS-0205]]; [[adr:ADR-0005]]; [[adr:ADR-0006]]

#### COMPASS-006: Compass SHALL extract candidate stances tied to source evidence

**Status:** Draft  
**Testable:** true  
**Area:** compass  
**Rationale:** Candidate-fit evaluation depends on durable stance extraction rather than opaque free-form model impressions.

Compass SHALL extract candidate stances from analyzed materials when supported by source evidence.

Each durable `stance:*` record SHALL identify, at minimum:

* the candidate,
* the issue or issue reference,
* the extracted position, characterization, or stated uncertainty, and
* one or more supporting source references.

Where a relevant `issue:*` record exists in the tenant DB, Compass SHOULD link extracted stances to that `issue:*` record rather than duplicating issue identity.

#### COMPASS-007: Compass SHALL evaluate candidate fit against the explicit user profile using inspectable matching logic

**Status:** Draft  
**Testable:** true  
**Area:** compass  
**Rationale:** Compass should help users reason about fit, not hide a recommendation in opaque model behavior.

Compass SHALL evaluate each candidate against the active civic values profile using inspectable matching logic.

A candidate-fit evaluation SHALL be traceable to:

* explicit profile inputs,
* extracted candidate stance information, and
* underlying source references.

Compass MAY present summary scores or categories, but the explanation of candidate fit SHALL remain inspectable by the user.

#### COMPASS-008: Compass SHALL distinguish source material, extraction, and generation

**Status:** Draft  
**Testable:** true  
**Area:** transparency  
**Rationale:** Users need to tell the difference between candidate source material, extracted stance data, and generated evaluation.

Compass SHALL distinguish between:

* captured or quoted source material,
* extracted candidate stances and structured observations, and
* AI-generated fit explanations, summaries, or comparisons.

At minimum, Compass SHALL distinguish:

* source text/media,
* extracted issue and stance observations, and
* generated candidate-fit explanations.

#### COMPASS-009: Compass SHALL surface per-issue alignment, conflict, and insufficient evidence

**Status:** Draft  
**Testable:** true  
**Area:** compass  
**Rationale:** A useful civic match should show where a candidate aligns, where they conflict, and where the record is thin.

For each evaluated candidate, Compass SHALL surface per-issue results sufficient to distinguish:

* alignment with the active civic values profile,
* conflict with the active civic values profile, and
* insufficient evidence or unresolved ambiguity.

Compass SHALL NOT reduce the primary user-facing result to a single unexplained overall ranking.

#### COMPASS-010: Compass SHALL keep issue weighting and ranking rules user-visible and user-controlled

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Candidate ranking and issue prioritization are normative choices that should remain under user control.

Compass SHALL present issue weighting, red-line handling, and any ranking rules used in candidate-fit evaluation as tenant-visible configuration.

Compass SHALL allow the user to modify those controls before or after generating candidate-fit evaluations.

#### COMPASS-011: Compass SHALL surface uncertainty and missing information explicitly

**Status:** Draft  
**Testable:** true  
**Area:** transparency  
**Rationale:** Civic decision support is misleading if it hides weak evidence, ambiguity, or missing candidate positions.

When evidence is incomplete, ambiguous, contradictory, or absent, Compass SHALL say so explicitly.

Compass SHALL NOT present unsupported certainty about a candidate position, issue fit, or overall candidate-fit result as established fact.

#### COMPASS-012: Compass SHALL NOT use hidden persuasion optimization or covert recommendation as the primary output

**Status:** Draft  
**Testable:** true  
**Area:** constraint  
**Rationale:** Compass is for citizen decision support, not behavioral manipulation.

Compass SHALL NOT use hidden persuasion optimization, engagement optimization, or covert recommendation as the primary output mode.

Compass SHALL NOT treat undisclosed behavioral profiling as the primary basis for ranking candidates or emphasizing issues.

#### COMPASS-013: Compass SHALL define Compass doc kinds and commit to stable doc-kind vocabulary tokens

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Shared storage across apps requires stable civic doc kinds and explicit contracts.

Compass SHALL store its primary documents using doc kinds encoded in `_id`.

Compass SHALL introduce the following doc kinds (stable vocabulary tokens):

* `profile` — explicit user civic values/priorities profile
* `contest` — selected contest scope and candidate set
* `candidate` — candidate identity record within a contest
* `stance` — extracted candidate stance tied to one or more sources
* `fit` — generated comparison between a profile and candidate within a contest

Each doc kind SHALL be documented with:

* required and optional fields,
* indexing/query posture,
* conflict handling posture.

**Trace:** [[arch_doc:AD-0001]] §9.2

#### COMPASS-014: Compass-generated fit evaluations SHALL record generation provenance

**Status:** Draft  
**Testable:** true  
**Area:** transparency  
**Rationale:** Users need inspectable generation context for candidate-fit outputs.

Each `fit:*` document generated by Compass SHALL record generation provenance.

At minimum, a `fit:*` document SHALL record:

* input profile ID,
* contest ID,
* candidate ID,
* referenced stance and snapshot IDs,
* generation time,
* model/runtime identifier, and
* weighting or ranking configuration used.

#### COMPASS-015: Compass SHOULD support side-by-side candidate comparison within a contest

**Status:** Draft  
**Testable:** false  
**Area:** compass  
**Rationale:** Users benefit from comparing multiple candidates against the same explicit values profile and evidence base.

Compass SHOULD support side-by-side comparison of two or more candidates within the same contest.

A side-by-side comparison SHOULD highlight, at minimum:

* issue-by-issue differences,
* shared unknowns or missing evidence, and
* the profile inputs driving the comparison.

## External Interfaces

Compass external interfaces are tenant-origin app/replication surfaces in both access modes.

- App route (local-only mode): `http://<tenant_id>.local/compass`
- App route (public custom-domain mode): `https://<tenant_id>.<box-host>/compass`
- Replication endpoint (local-only mode): `http://<tenant_id>.local/db`
- Replication endpoint (public custom-domain mode): `https://<tenant_id>.<box-host>/db`
- Local storage: shared local tenant replica `tenant_local` within the current tenant origin
- Candidate and contest source artifacts: tenant blob store (when binary/large)
- Optional service APIs: `/api/compass/...` on the current tenant origin

Public custom-domain mode is the full installable-PWA posture. Local-only mode remains HTTP local mode with local data continuity and opportunistic sync, without equivalent full installability/reopen-offline guarantees.

## Verification

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:

* **Test:** create an explicit user values profile and confirm the profile remains user-visible and editable.
* **Test:** configure a contest scope and candidate set, ingest candidate materials, and confirm Compass extracts source-grounded candidate stances.
* **Test:** generate candidate-fit evaluations and confirm each evaluation explains its reasoning with source references and explicit user-priority inputs.
* **Test:** change issue weighting or red-line configuration and confirm candidate-fit outputs update predictably.
* **Test:** confirm Compass surfaces insufficient evidence when candidate-position data is missing or ambiguous.
* **Inspection:** confirm Compass does not require hidden psychographic inference or hidden persuasion optimization as the primary basis for output.
* **Test:** confirm saved profiles, candidate-fit evaluations, and cited source excerpts remain readable offline after first successful load.

---

# SRS-1006: Spar Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-03-06
**Status:** Draft

This specification defines the software requirements for the **Spar** application.

Spar is a shipped, tenant-scoped civic dialogue experience for OurBox OS. It helps users challenge, refine, and test civic positions through source-grounded, user-controlled dialogue intended to reduce echo-chamber effects without hidden persuasion optimization or behavioral steering.

## Normative Language

The key words **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, and **MAY** are to be interpreted as requirements.

OurBox OS vocabulary and normative definitions are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

## Introduction

This SRS defines requirements for the **Spar** app experience.

Scope includes:

* user-initiated civic dialogue over positions, claims, questions, and proposals
* user-selectable challenge modes such as steelmanning, reframing, and evidence testing
* source-grounded dialogue over user-provided materials and tenant-local civic records
* explicit separation of facts, value judgments, predictions, and tradeoffs
* uncertainty and evidence-gap surfacing
* reflection summaries over dialogue sessions

Out of scope:

* broad civic source monitoring and general-purpose issue reporting
* value-to-candidate matching and ballot guidance
* standalone long-form event recording and evidence workflows
* standalone anti-censorship archiving/version-history workflows
* social networking, box-to-box distribution, or public-feed mechanics in the v0 posture
* hidden persuasion optimization, behavioral targeting, or covert viewpoint steering

## Referenced Documents

* `docs/00-Glossary/Terms-and-Definitions.md`
* [[spec:SyRS-0001]]
* [[arch_doc:AD-0001]]
* [[adr:ADR-0001]]
* [[adr:ADR-0002]]
* [[adr:ADR-0003]]
* [[adr:ADR-0004]]
* [[adr:ADR-0005]]
* [[adr:ADR-0006]]
* [[spec:SRS-0201]]
* [[spec:SRS-0204]]
* [[spec:SRS-0205]]
* [[spec:SRS-0206]]
* [[spec:SRS-1004]]
* [[spec:SRS-1005]]

## Requirements

Allocated system requirements from `[[spec:SyRS-0001]]` are included here for traceability; Spar-specific requirements follow.

### Allocated System Requirements (from SyRS)

#### APP-001: Shipped apps SHALL provide full installable-PWA posture in public custom-domain mode

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Aligns shipped-app installability guarantees with mode-specific browser behavior.

In public custom-domain mode, shipped OurBox apps SHALL be installable PWAs that can load from cache after the first successful online session.

#### APP-002: Shipped apps SHALL persist working data locally

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Offline writes depend on local persistence.

Shipped apps SHALL store working data locally in the tenant origin using PouchDB-backed IndexedDB.

#### APP-003: Shipped apps SHALL sync opportunistically

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Supports sporadic connectivity while keeping data consistent.

Shipped apps SHALL initiate incremental replication with the tenant DB when connectivity is available.

#### APP-004: Apps SHALL operate within a mode-aware tenant origin

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Tenant origins define storage isolation and routing in both access modes.

Shipped apps SHALL be served under mode-aware tenant origins:
- local-only mode: `http://<tenant_id>.local/<app_slug>`
- public custom-domain mode: `https://<tenant_id>.<box-host>/<app_slug>`

Tenant context SHALL be derived from the full host; `tenant_id` is the leftmost DNS label.

#### APP-005: Apps SHALL share one local tenant replica per origin

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Ensures apps share doc kinds offline.

All shipped apps under the same tenant origin SHALL read and write through a single local tenant
replica database on that device.

#### APP-006: Apps SHALL honor doc-kind contracts

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Shared storage requires strict doc-kind boundaries.

Shipped apps SHALL only create and update documents whose `_id` prefixes match the stable doc-kind
vocabulary defined for OurBox OS.

#### APP-007: Local-only mode SHALL be HTTP-only

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Local-only mode is served on local HTTP tenant origins and does not depend on TLS.

Local-only mode SHALL use `http://<tenant_id>.local/...` and SHALL NOT require or imply HTTPS/TLS.

#### APP-008: Local-only mode documentation SHALL NOT promise public-mode-equivalent full PWA posture

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Documentation must accurately distinguish local-only limits from public custom-domain guarantees.

Local-only mode SHALL NOT be documented as guaranteeing installability or reopen-offline behavior equivalent to public custom-domain mode.

### Functional and Data Requirements (Spar-specific)

#### SPAR-001: Spar SHALL support user-initiated civic dialogue over positions, claims, questions, and proposals

**Status:** Draft  
**Testable:** true  
**Area:** spar  
**Rationale:** Spar exists to help users actively test their own civic thinking rather than passively consume a feed.

Spar SHALL allow the user to start one or more dialogue sessions around a civic position, claim, question, or proposal.

A dialogue session SHALL support user turns and Spar-generated turns over a user-selected topic or issue scope.

#### SPAR-002: Spar SHALL provide user-selectable challenge modes

**Status:** Draft  
**Testable:** true  
**Area:** spar  
**Rationale:** Users should be able to choose how they want their thinking challenged rather than receive a single opaque style of response.

Spar SHALL provide user-selectable challenge modes.

At minimum, Spar SHALL support modes sufficient to:

* steelman an opposing or alternative view,
* identify assumptions or tradeoffs,
* separate facts, value judgments, and predictions, and
* explore what evidence would change the conclusion.

#### SPAR-003: Spar SHALL accept user-provided positions, claims, questions, and supporting materials

**Status:** Draft  
**Testable:** true  
**Area:** spar  
**Rationale:** Users need to challenge their thinking using both their own statements and civic materials already in their possession.

Spar SHALL accept user-provided positions, claims, questions, and supporting materials for analysis.

At minimum, Spar SHALL accept:

* free-text inputs,
* URL inputs,
* image artifacts,
* PDF artifacts, and
* references to tenant-local civic records already present in the shared local tenant replica.

Examples include user-written opinions, screenshots, political mailers, candidate materials, issue briefs, and Scout-generated records.

#### SPAR-004: Spar SHALL preserve source provenance for fetched or uploaded supporting materials

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Source-grounded civic dialogue must remain inspectable and tied back to evidence.

For each fetched or uploaded artifact that Spar analyzes, Spar SHALL create or reference a `source:*` record and a `snapshot:*` record.

Each referenced or created `snapshot:*` record SHALL include, at minimum:

* provenance (e.g., source URI or upload origin),
* observed/ingested timestamp,
* content hash/digest, and
* media type.

When source artifact payload bytes are binary or large, Spar SHALL store payload bytes in the tenant blob store by default and SHALL store only references in application documents.

**Trace:** [[spec:SyRS-0001]] DATA-006, DATA-007; [[spec:SRS-0205]]; [[adr:ADR-0005]]; [[adr:ADR-0006]]

#### SPAR-005: Spar SHALL distinguish source material, extraction, and generation

**Status:** Draft  
**Testable:** true  
**Area:** transparency  
**Rationale:** Users need to know what came from source material, what was extracted or structured, and what was generated by AI.

Spar SHALL distinguish between:

* captured or quoted source material,
* extracted positions, claims, issue observations, or other structured observations, and
* AI-generated challenge responses, reflections, or dialogue summaries.

At minimum, Spar SHALL distinguish:

* source text/media,
* extracted claim or issue observations, and
* generated challenge or reflection output.

#### SPAR-006: Spar SHALL support steelmanned opposing arguments and alternative civic framings

**Status:** Draft  
**Testable:** true  
**Area:** spar  
**Rationale:** Spar should help users become less trapped in echo chambers by presenting materially different viewpoints and framings.

When the user selects an opposing-view or reframing challenge mode, Spar SHALL produce one or more challenge responses that present a materially different position, concern, or policy framing.

Where supporting source material is available, Spar SHALL cite that material in the generated challenge response.

#### SPAR-007: Spar SHALL distinguish facts, value judgments, predictions, and policy tradeoffs when requested

**Status:** Draft  
**Testable:** true  
**Area:** spar  
**Rationale:** Civic disagreement often becomes less confusing when factual claims, moral commitments, and predictions are separated.

When the user requests analytical separation, Spar SHALL be able to distinguish:

* factual claims,
* value judgments or normative commitments,
* predictions or causal expectations, and
* policy tradeoffs or opportunity costs.

#### SPAR-008: Spar SHALL identify assumptions, uncertainties, and evidence gaps in the position under examination

**Status:** Draft  
**Testable:** true  
**Area:** spar  
**Rationale:** A useful challenge process should reveal what is being assumed and where the evidence is weak.

Spar SHALL be able to identify assumptions, uncertainties, and evidence gaps in the position, claim, or proposal under examination.

Where supporting source material is available, Spar SHALL link identified evidence gaps or contradictions back to relevant source references.

#### SPAR-009: Spar SHALL articulate what evidence would strengthen, weaken, or change a conclusion when determinable

**Status:** Draft  
**Testable:** true  
**Area:** spar  
**Rationale:** Users need help understanding what would actually move a civic judgment rather than only hearing abstract disagreement.

When determinable from the available material, Spar SHALL articulate one or more evidence conditions, observations, or questions that would strengthen, weaken, or change the current conclusion or position under examination.

#### SPAR-010: Spar SHALL keep dialogue goals, challenge modes, and explicit conversation constraints user-visible and user-controlled

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Spar should help users think better without hiding the rules of engagement.

Spar SHALL present the active dialogue goal, selected challenge mode, and any explicit conversation constraints as tenant-visible, user-editable configuration.

Examples of conversation constraints MAY include source scope, response style, or challenge intensity.

#### SPAR-011: Spar SHALL NOT use hidden persuasion optimization or covert behavioral steering as the primary output

**Status:** Draft  
**Testable:** true  
**Area:** constraint  
**Rationale:** Spar is for citizen self-reflection and intellectual resilience, not behavioral manipulation.

Spar SHALL NOT use hidden persuasion optimization, engagement optimization, or covert behavioral steering as the primary output mode.

Spar SHALL NOT treat undisclosed behavioral profiling as the primary basis for determining which arguments, framings, or challenges to present.

#### SPAR-012: Spar SHALL surface uncertainty and insufficient evidence explicitly

**Status:** Draft  
**Testable:** true  
**Area:** transparency  
**Rationale:** Civic dialogue is misleading if it hides weak evidence, ambiguity, or unresolved uncertainty.

When evidence is incomplete, ambiguous, contradictory, or absent, Spar SHALL say so explicitly.

Spar SHALL NOT present unsupported certainty about a claim, challenge response, or reflection summary as established fact.

#### SPAR-013: Spar dialogue turns and generated outputs SHALL record provenance and remain append-only

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Users need a durable, inspectable record of what was said, what was generated, and how the dialogue evolved over time.

Each `turn:*` document SHALL record, at minimum:

* turn author type (e.g., user or Spar),
* created timestamp,
* parent dialog ID, and
* referenced source, claim, or generation inputs sufficient to reconstruct turn provenance when applicable.

After a `turn:*`, `challenge:*`, or `reflection:*` document is created, Spar SHALL treat it as immutable.

Corrections or follow-on elaborations SHALL be represented as new linked documents rather than by overwriting the original record.

#### SPAR-014: Spar SHALL define Spar doc kinds and commit to stable doc-kind vocabulary tokens

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Shared storage across apps requires stable civic doc kinds and explicit contracts.

Spar SHALL store its primary documents using doc kinds encoded in `_id`.

Spar SHALL introduce the following doc kinds (stable vocabulary tokens):

* `dialog` — user-controlled Spar dialogue session
* `turn` — immutable user or Spar dialogue turn
* `position` — explicit civic position, question, claim, or proposal under examination
* `challenge` — generated counterargument, reframing, or evidence challenge tied to dialogue context
* `reflection` — generated summary of strongest counterarguments, uncertainties, and next evidence questions

Each doc kind SHALL be documented with:

* required and optional fields,
* indexing/query posture,
* conflict handling posture.

**Trace:** [[arch_doc:AD-0001]] §9.2

#### SPAR-015: Spar SHOULD support reflection summaries and resumable dialogue

**Status:** Draft  
**Testable:** false  
**Area:** spar  
**Rationale:** Users benefit from returning to a civic question later with a clear summary of what was learned and what remains unresolved.

Spar SHOULD support generated reflection summaries that capture, at minimum:

* strongest opposing arguments surfaced,
* unresolved uncertainties or evidence gaps, and
* next questions or evidence to seek.

Previously saved dialogues SHOULD be resumable by the user within the same tenant origin.

## External Interfaces

Spar external interfaces are tenant-origin app/replication surfaces in both access modes.

- App route (local-only mode): `http://<tenant_id>.local/spar`
- App route (public custom-domain mode): `https://<tenant_id>.<box-host>/spar`
- Replication endpoint (local-only mode): `http://<tenant_id>.local/db`
- Replication endpoint (public custom-domain mode): `https://<tenant_id>.<box-host>/db`
- Local storage: shared local tenant replica `tenant_local` within the current tenant origin
- Supporting source artifacts: tenant blob store (when binary/large)
- Optional service APIs: `/api/spar/...` on the current tenant origin

Public custom-domain mode is the full installable-PWA posture. Local-only mode remains HTTP local mode with local data continuity and opportunistic sync, without equivalent full installability/reopen-offline guarantees.

## Verification

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:

* **Test:** start a dialogue session around a user-provided civic claim, question, or proposal and confirm that user-selected challenge modes change the output type appropriately.
* **Test:** attach or select source materials and confirm Spar cites relevant supporting or opposing source records when source-grounded responses are available.
* **Test:** request separation of facts, value judgments, predictions, and tradeoffs and confirm Spar distinguishes those categories in its output.
* **Test:** ask what evidence would strengthen, weaken, or change a conclusion and confirm Spar returns explicit evidence conditions or states that the available evidence is insufficient.
* **Inspection:** confirm dialogue goals, challenge modes, and explicit conversation constraints are tenant-visible configuration and that hidden persuasion optimization is not the primary basis for output.
* **Test:** confirm generated turns record authorship and provenance and remain append-only after creation.
* **Test:** confirm saved dialogues and reflection summaries remain readable offline after first successful load.

---
