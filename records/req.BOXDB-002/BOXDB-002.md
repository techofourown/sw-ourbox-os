---
typeId: req
recordId: BOXDB-002
parent: "section:SRS-0202-3-requirements"
fields:
  title: "Replication SHALL be treated as synchronization, not backup"
  status: "Draft"
  testable: true
  area: "data"
  rationale: "Replication can copy deletions and bad changes; backup must be point-in-time retention."
  order: 20
---
Replication SHALL be treated as availability/synchronization behavior and SHALL NOT be treated as backup.

**Trace:** [[arch_doc:AD-0001]] §7.1
