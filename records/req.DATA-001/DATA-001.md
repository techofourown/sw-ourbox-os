---
typeId: req
recordId: DATA-001
parent: section:2-data-and-replication
fields:
  title: "Each tenant MUST have exactly one CouchDB tenant DB"
  testable: true
  area: data
  order: 0
---
Each tenant MUST map to exactly one CouchDB database (the tenant DB). Replication is whole tenant DB ↔ tenant DB.

Derived from [[adr:ADR-0002]] and [[arch_doc:SAD-0001]].
