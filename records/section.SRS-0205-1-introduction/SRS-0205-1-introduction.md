---
typeId: section
recordId: SRS-0205-1-introduction
parent: "spec:SRS-0205"
fields:
  title: "Introduction"
  level: 1
  order: 1
---

This SRS defines requirements for the **tenant blob store**, which stores blob payload bytes outside CouchDB as part of the tenant storage contract.

Key posture (already established in architecture/decisions):
- each tenant has a tenant-scoped blob store
- application documents store references to blobs (payload bytes live outside CouchDB by default)
- blob storage is content-addressed and uses a deterministic path layout

Out of scope:
- gateway routing and external HTTP surfaces for blob access (see `[[spec:SRS-0201]]`)
- CouchDB tenant DB concerns (see `[[spec:SRS-0202]]`)
- client-local replica behavior (see `[[spec:SRS-0204]]`)
