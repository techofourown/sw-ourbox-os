---
typeId: req
recordId: SCOUT-010
parent: section:SRS-1004-scout-specific-requirements
fields:
  title: "Scout SHALL define Scout doc kinds and commit to stable doc-kind vocabulary tokens"
  status: Draft
  testable: true
  area: data
  rationale: "Shared storage across apps requires stable civic doc kinds and explicit contracts."
  order: 10
---

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
