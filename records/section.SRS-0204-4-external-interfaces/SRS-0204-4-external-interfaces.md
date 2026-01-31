---
typeId: section
recordId: SRS-0204-4-external-interfaces
parent: "spec:SRS-0204"
fields:
  title: "External Interfaces"
  order: 4
  level: 1
---

The local tenant replica interacts with:
- browser storage via IndexedDB (through PouchDB)
- replication endpoints on the tenant origin (presented by the Gateway)

Precise replication configuration (credentials/session mechanics, endpoint URLs beyond `/db`) will be specified via future ICDs.
