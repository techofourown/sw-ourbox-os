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

Concrete replication configuration (credentials/session mechanics and any required request metadata) is defined by the deployed Gateway
and identity implementation, and is verified by automated integration tests. This SRS specifies stable invariants (tenant origin,
`tenant_local`, whole-DB replication posture) rather than wire-format details.
