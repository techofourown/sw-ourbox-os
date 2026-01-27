---
typeId: req
recordId: DATA-003
parent: section:2-data-and-replication
fields:
  title: "Application documents MUST use _id = <doc_kind>:<uuidv4>"
  testable: true
  area: data
  order: 2
---
Application documents MUST use `_id = "<doc_kind>:<uuidv4>"`. `doc_kind` MUST be derived from `_id` only. ULIDs MUST NOT be used as document identifiers.

Derived from [[adr:ADR-0004]].
