---
typeId: req
recordId: DATA-004
parent: section:2-data-and-replication
fields:
  title: "Doc kind SHALL be derived from _id only"
  testable: true
  status: "Draft"
  rationale: "Avoids divergent sources of truth for document classification."
  area: "data"
  order: 4
---
Applications and services SHALL derive `doc_kind` from the `_id` prefix and SHALL NOT store a separate
doc-type field as the authoritative source.
