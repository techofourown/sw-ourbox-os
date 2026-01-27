---
typeId: req
recordId: DATA-006
parent: section:2-data-and-replication
fields:
  title: "Replication MUST be treated as sync, not backup"
  testable: false
  area: data
  order: 5
---
Replication MUST be treated as availability/synchronization, not backup. Operational backup/retention is a separate concern.

Derived from [[arch_doc:SAD-0001]] and [[adr:ADR-0002]].
