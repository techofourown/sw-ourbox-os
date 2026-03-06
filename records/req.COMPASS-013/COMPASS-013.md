---
typeId: req
recordId: COMPASS-013
parent: section:SRS-1005-compass-specific-requirements
fields:
  title: "Compass SHALL define Compass doc kinds and commit to stable doc-kind vocabulary tokens"
  status: Draft
  testable: true
  area: data
  rationale: "Shared storage across apps requires stable civic doc kinds and explicit contracts."
  order: 13
---

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
