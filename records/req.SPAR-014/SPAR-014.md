---
typeId: req
recordId: SPAR-014
parent: section:SRS-1006-spar-specific-requirements
fields:
  title: "Spar SHALL define Spar doc kinds and commit to stable doc-kind vocabulary tokens"
  status: Draft
  testable: true
  area: data
  rationale: "Shared storage across apps requires stable civic doc kinds and explicit contracts."
  order: 14
---

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
