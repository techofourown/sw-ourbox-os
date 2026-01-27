---
typeId: req
recordId: DATA-003
parent: section:2-data-and-replication
fields:
  title: "Document IDs follow doc_kind:uuidv4"
  testable: true
  status: "Draft"
  rationale: "Stable identifiers are required for replication and conflict handling."
  area: "data"
  order: 3
---
Application documents MUST use `_id = "<doc_kind>:<uuidv4>"` and MUST NOT use ULIDs.
