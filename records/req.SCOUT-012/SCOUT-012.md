---
typeId: req
recordId: SCOUT-012
parent: section:SRS-1004-scout-specific-requirements
fields:
  title: "Scout source snapshots SHALL be immutable after creation"
  status: Draft
  testable: true
  area: data
  rationale: "Provenance and change-over-time analysis depend on immutable historical capture records."
  order: 12
---

After a `snapshot:*` document is created, Scout SHALL treat it as immutable.

Corrections, annotations, or re-ingests SHALL be represented as new documents or linked documents rather than by overwriting the original snapshot.
