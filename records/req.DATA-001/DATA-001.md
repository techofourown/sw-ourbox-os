---
typeId: req
recordId: DATA-001
parent: section:2-data-and-replication
fields:
  title: "Each tenant MUST have exactly one tenant DB"
  testable: "Yes"
  status: "Draft"
  rationale: "ADR-0002 defines DB-per-tenant."
  area: "data"
  order: 1
---
Each tenant MUST have exactly one CouchDB tenant database named using the `tenant_<tenant_id>`
pattern.
