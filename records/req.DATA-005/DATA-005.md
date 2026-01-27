---
typeId: req
recordId: DATA-005
parent: section:2-data-and-replication
fields:
  title: "Replication is tenant DB ↔ tenant DB"
  testable: true
  status: "Draft"
  rationale: "Whole-DB replication is the default sync unit."
  area: "data"
  order: 5
---
Replication MUST operate on whole tenant databases (local tenant replica ↔ tenant DB) rather than
selective partition replication.
