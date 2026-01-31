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
- storage isolation is by tenant origin (`https://<tenant_id>.<box-host>`)

Out of scope:
- on-box CouchDB service requirements (see `[[spec:SRS-0202]]`)
- gateway routing and `/db` mapping (see `[[spec:SRS-0201]]`)
