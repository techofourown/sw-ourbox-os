---
typeId: req
recordId: SCOUT-008
parent: section:SRS-1004-scout-specific-requirements
fields:
  title: "Scout SHALL support change-over-time comparison across watched sources"
  status: Draft
  testable: true
  area: scout
  rationale: "Political webpages, issue statements, and campaign material change over time; users need “what changed?” as a first-class capability."
  order: 8
---

Where multiple `snapshot:*` records exist for the same source or materially related source chain, Scout SHALL support change-over-time comparison.

Scout SHALL be able to surface additions, removals, and materially changed claims when determinable from the available evidence.
