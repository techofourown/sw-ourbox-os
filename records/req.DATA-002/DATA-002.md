---
typeId: req
recordId: DATA-002
parent: section:2-data-and-replication
fields:
  title: "Tenant DBs MUST be partitioned databases"
  testable: true
  status: "Draft"
  rationale: "Partitioned DBs enforce doc-kind vocabulary and access patterns."
  area: "data"
  order: 2
---
Each tenant DB MUST be created in CouchDB partitioned mode, with doc kind as the partition key.
