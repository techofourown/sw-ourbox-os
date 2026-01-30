---
typeId: req
recordId: DATA-001
parent: section:2-data-and-replication
fields:
  title: "Each tenant SHALL have exactly one tenant DB and one tenant blob store"
  testable: true
  status: "Draft"
  rationale: "Tenant DBs are the replication unit; tenant blob stores provide tenant-scoped blob payload storage."
  area: "data"
  order: 1
---
OurBox SHALL maintain one CouchDB database per tenant, named using the `tenant_<tenant_id>` pattern.

OurBox SHALL maintain one tenant blob store per tenant for blob payload bytes stored outside CouchDB. The tenant blob store uses a tenant-scoped storage root (ADR-0006).
