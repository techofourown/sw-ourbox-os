---
typeId: req
recordId: DATA-005
parent: section:2-data-and-replication
fields:
  title: "Tenant replication MUST be whole-DB"
  testable: true
  status: "Draft"
  rationale: "Replication posture is tenant DB ↔ tenant DB."
  area: "data"
  order: 5
---
Replication between client devices and the box MUST use the tenant DB as the unit of replication and
MUST NOT require selective partition replication.
