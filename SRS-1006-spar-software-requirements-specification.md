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
**Rationale:** Local-only mode uses tenant-local HTTP routing and does not rely on TLS posture.

Local-only mode SHALL use `http://<tenant_id>.local/...` and SHALL NOT require or imply HTTPS/TLS.

#### APP-008: Local-only mode documentation SHALL NOT promise public-mode-equivalent full PWA posture

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Product documentation must accurately describe local-only limits relative to public custom-domain mode.

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
