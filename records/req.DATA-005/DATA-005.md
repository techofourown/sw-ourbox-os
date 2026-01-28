---
typeId: req
recordId: DATA-005
parent: section:2-data-and-replication
fields:
  title: "Tenant replication SHALL be whole-DB"
  testable: true
  status: "Draft"
  rationale: "Replication posture is tenant DB ↔ tenant DB."
  area: "data"
  order: 5
---
Replication between client devices and the box SHALL use the tenant DB as the unit of replication and
SHALL NOT require selective partition replication.
