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
- mode-aware same-origin replication endpoints:
  - `http://<tenant_id>.local/db`
  - `https://<tenant_id>.<box-host>/db`
