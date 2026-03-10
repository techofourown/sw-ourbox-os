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

Key posture (already established in architecture):
- many client devices may exist per tenant
- connectivity may be intermittent; sync is opportunistic
- tenant-origin patterns are mode-specific:
  - local-only mode: `http://<tenant_id>.local/...`
  - public custom-domain mode: `https://<tenant_id>.<box-host>/...`
- for the same tenant on the same browser/device, those two full hosts are different origins and therefore map to different local tenant replicas

Out of scope:
- on-box CouchDB service requirements (see `[[spec:SRS-0202]]`)
- gateway routing and `/db` mapping (see `[[spec:SRS-0201]]`)
