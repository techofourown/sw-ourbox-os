---
typeId: req
recordId: DATA-005
parent: section:2-data-and-replication
fields:
  title: "Replication MUST be whole tenant DB"
  testable: "Yes"
  status: "Draft"
  rationale: "ADR-0002 defines tenant DB replication as the default unit."
  area: "data"
  order: 5
---
Replication MUST be performed as whole tenant DB replication between the local tenant replica and
the tenant CouchDB database.
