---
typeId: req
recordId: COMPASS-003
parent: section:SRS-1005-compass-specific-requirements
fields:
  title: "Compass SHALL operate on a user-selected contest scope and candidate set"
  status: Draft
  testable: true
  area: compass
  rationale: "Candidate matching is only meaningful within a contest scope the user can inspect and confirm."
  order: 3
---

Compass SHALL allow the user to select, confirm, or provide the contest scope and candidate set to be evaluated.

Any location-, district-, or ballot-scope derivation used by Compass SHALL remain user-visible and user-confirmable.

The user-confirmed contest scope SHALL be authoritative for Compass candidate-fit evaluation.
