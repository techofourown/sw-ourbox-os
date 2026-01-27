---
typeId: req
recordId: DATA-006
parent: section:2-data-and-replication
fields:
  title: "Replication MUST be tenant DB to tenant DB"
  testable: true
  status: "Draft"
  rationale: "Whole-DB replication is the default posture."
  area: "data"
  order: 6
---
Replication MUST operate on the full tenant DB between local tenant replicas and CouchDB.
