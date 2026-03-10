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

#### APP-001: Public custom-domain mode SHALL provide full installable-PWA posture for shipped apps

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Full installability and reopen-offline guarantees are mode-scoped to public HTTPS tenant origins.

In public custom-domain mode, shipped OurBox apps SHALL be installable PWAs and SHALL be capable of reopen-offline behavior after first successful load via service-worker-backed cached assets.

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

#### APP-004: Apps SHALL operate within a tenant origin in both access modes

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Tenant origins define storage isolation and routing in both local-only and public custom-domain modes.

Shipped apps SHALL be served under tenant origins in both supported patterns:
- local-only mode: `http://<tenant_id>.local/<app_slug>`
- public custom-domain mode: `https://<tenant_id>.<box-host>/<app_slug>`

The full host SHALL carry tenant context, `tenant_id` SHALL be derived from the leftmost DNS label of the full host, and path SHALL identify app.

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

Scout external interfaces are mode-aware tenant-origin surfaces.

- Local-only app route: `http://<tenant_id>.local/scout`
- Public custom-domain app route: `https://<tenant_id>.<box-host>/scout`
- Local-only replication endpoint: `http://<tenant_id>.local/db` (same-origin, via the Gateway)
- Public custom-domain replication endpoint: `https://<tenant_id>.<box-host>/db` (same-origin, via the Gateway)
- Local storage: shared local tenant replica `tenant_local` within the active origin
- Optional service APIs by mode: `http://<tenant_id>.local/api/scout/...` and `https://<tenant_id>.<box-host>/api/scout/...` (when present)

## Verification

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:

* **Test:** configure a watched public source, ingest content, and generate a source-grounded briefing with citations.
* **Test:** upload a political mailer image or PDF and confirm Scout extracts claims, issue references, and source-backed briefing output.
* **Test:** ingest two versions of the same source and confirm Scout surfaces change-over-time differences.
* **Test:** ask a question over the watched corpus and confirm the answer cites supporting `snapshot:*` records or explicitly states insufficient evidence.
* **Inspection:** confirm watched sources and prioritization rules are explicit tenant-visible configuration and that no hidden feed is the primary ranking mechanism.
* **Test:** confirm previously generated briefings and supporting source excerpts remain readable offline after first successful load.
