---
typeId: req
recordId: DATA-001
parent: section:2-data-and-replication
fields:
  title: "Each tenant SHALL have exactly one tenant DB"
  testable: true
  status: "Draft"
  rationale: "Tenant DBs are the replication unit."
  area: "data"
  order: 1
---
OurBox SHALL maintain one CouchDB database per tenant, named using the `tenant_<tenant_id>` pattern.
