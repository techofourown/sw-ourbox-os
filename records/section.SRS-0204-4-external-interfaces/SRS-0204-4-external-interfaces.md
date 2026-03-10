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
- same-origin replication endpoints presented by the gateway:
  - `http://<tenant_id>.local/db`
  - `https://<tenant_id>.<box-host>/db`

For the same tenant on the same browser profile, local-only (`http://<tenant_id>.local`) and public custom-domain (`https://<tenant_id>.<box-host>`) are different origins and therefore different local tenant replicas.
