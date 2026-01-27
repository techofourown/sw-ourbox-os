---
typeId: req
recordId: DATA-002
parent: section:2-data-and-replication
fields:
  title: "Tenant DBs MUST be partitioned databases"
  testable: true
  area: data
  order: 1
---
All tenant DBs MUST be created in partitioned mode, and the partition key MUST be the doc kind.

Derived from [[adr:ADR-0002]].
