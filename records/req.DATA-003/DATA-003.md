---
typeId: req
recordId: DATA-003
parent: section:2-data-and-replication
fields:
  title: "Document IDs SHALL use the doc_kind:uuidv4 scheme"
  testable: true
  status: "Draft"
  rationale: "Canonical IDs ensure consistent replication and conflict boundaries."
  area: "data"
  order: 3
---
Application documents SHALL have `_id` values shaped as `<doc_kind>:<uuidv4>` and SHALL NOT use ULIDs.
