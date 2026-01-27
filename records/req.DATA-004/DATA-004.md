---
typeId: req
recordId: DATA-004
parent: section:2-data-and-replication
fields:
  title: "Document kind is derived only from _id"
  testable: true
  status: "Draft"
  rationale: "Avoid multiple sources of truth for doc kind."
  area: "data"
  order: 4
---
Apps and services MUST derive `doc_kind` exclusively from the `_id` prefix and MUST NOT store a
secondary doc kind field.
