---
typeId: req
recordId: DATA-001
parent: section:2-data-and-replication
fields:
  title: "One tenant DB per tenant"
  testable: true
  status: "Draft"
  rationale: "Tenant DBs are the primary data boundary."
  area: "data"
  order: 1
---
Each tenant MUST have exactly one CouchDB tenant database on the box.
