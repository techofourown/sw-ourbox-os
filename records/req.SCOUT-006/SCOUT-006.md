---
typeId: req
recordId: SCOUT-006
parent: section:SRS-1004-scout-specific-requirements
fields:
  title: "Scout SHALL extract issues, claims, and civic events/proceedings from sources"
  status: Draft
  testable: true
  area: scout
  rationale: "Scout’s civic intelligence value depends on structured extraction rather than simple bookmarking."
  order: 6
---

Scout SHALL extract issue, claim, and civic event/proceeding information from analyzed sources when supported by source evidence.

Where Scout materializes a civic event or proceeding as a durable application document, Scout SHALL use the existing `event:*` doc kind.

Scout SHALL surface referenced public actors (e.g., candidates, committees, agencies, organizations) in briefings and query results when detected in source material.
