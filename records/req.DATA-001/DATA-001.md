---
typeId: req
recordId: DATA-001
parent: section:2-data-and-replication
fields:
  title: "Each tenant MUST have exactly one tenant DB"
  testable: true
  status: "Draft"
  rationale: "Tenant DBs are the replication unit for the platform."
  area: "data"
  order: 1
---
OurBox OS MUST provision exactly one CouchDB tenant DB per tenant and use it as the system-of-record.
