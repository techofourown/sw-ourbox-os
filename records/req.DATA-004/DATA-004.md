---
typeId: req
recordId: DATA-004
parent: section:2-data-and-replication
fields:
  title: "Doc kind MUST be derived from _id only"
  testable: true
  status: "Draft"
  rationale: "Avoids divergent sources of truth for document classification."
  area: "data"
  order: 4
---
Applications and services MUST derive `doc_kind` from the `_id` prefix and MUST NOT store a separate
doc-type field as the authoritative source.
