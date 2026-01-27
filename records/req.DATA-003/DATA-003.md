---
typeId: req
recordId: DATA-003
parent: section:2-data-and-replication
fields:
  title: "Document kind MUST be derived from _id only"
  testable: true
  status: "Draft"
  rationale: "Doc kind is single-source-of-truth in the ID structure."
  area: "data"
  order: 3
---
Applications MUST derive doc kind from the _id prefix and MUST NOT store a separate doc type field.
