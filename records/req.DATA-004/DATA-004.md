---
typeId: req
recordId: DATA-004
parent: section:2-data-and-replication
fields:
  title: "Shipped apps MUST model user entities as one document per entity"
  testable: true
  area: data
  order: 3
---
Shipped apps MUST use one document per user-editable entity (note/task/contact/event/etc.). Aggregating many independent entities into one giant document is forbidden.

Derived from [[adr:ADR-0002]].
