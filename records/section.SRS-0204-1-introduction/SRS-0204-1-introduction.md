---
typeId: section
recordId: SRS-0204-1-introduction
parent: "spec:SRS-0204"
fields:
  title: "Introduction"
  order: 1
  level: 1
---

This SRS defines requirements for the **local tenant replica** on client devices: the PouchDB database (IndexedDB-backed) within a tenant origin that enables offline-first behavior.

Tenant-origin posture for local tenant replicas:
- local-only mode tenant origin: `http://<tenant_id>.local`
- public custom-domain mode tenant origin: `https://<tenant_id>.<box-host>`
- for the same tenant on the same browser/device, those origins are different and therefore map to different local tenant replicas

Out of scope:
- on-box CouchDB service requirements (see `[[spec:SRS-0202]]`)
- gateway routing and `/db` mapping (see `[[spec:SRS-0201]]`)
