---
typeId: req
recordId: DATA-003
parent: section:2-data-and-replication
fields:
  title: "Document kinds MUST be encoded in _id"
  testable: "Yes"
  status: "Draft"
  rationale: "ADR-0004 defines doc kind as the partition key."
  area: "data"
  order: 3
---
Application documents MUST use `_id = "<doc_kind>:<doc_uuid>"` and derive `doc_kind` from `_id` only.
