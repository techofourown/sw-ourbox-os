---
typeId: req
recordId: DATA-007
parent: section:2-data-and-replication
fields:
  title: "Each tenant SHALL have exactly one tenant blob store"
  testable: true
  status: "Draft"
  rationale: "Tenant-scoped blob stores keep blob payload bytes legible for tenant operations and align with ADR-0006 storage roots."
  area: "data"
  order: 7
---
OurBox SHALL maintain one tenant blob store per tenant for blob payload bytes stored outside CouchDB.

Each tenant blob store SHALL use a tenant-scoped storage root (ADR-0006).
