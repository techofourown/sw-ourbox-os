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
**Rationale:** Local-only mode uses tenant-local HTTP routing and does not rely on TLS posture.

Local-only mode SHALL use `http://<tenant_id>.local/...` and SHALL NOT require or imply HTTPS/TLS.

#### APP-008: Local-only mode documentation SHALL NOT promise public-mode-equivalent full PWA posture

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Product documentation must accurately describe local-only limits relative to public custom-domain mode.

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
