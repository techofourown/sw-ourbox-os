---
typeId: req
recordId: DATA-004
parent: section:2-data-and-replication
fields:
  title: "Document IDs MUST use UUIDv4 suffixes"
  testable: true
  status: "Draft"
  rationale: "UUIDv4 enables offline-safe ID creation."
  area: "data"
  order: 4
---
Application documents MUST use _id = "<doc_kind>:<uuidv4>" with UUIDv4 identifiers.
