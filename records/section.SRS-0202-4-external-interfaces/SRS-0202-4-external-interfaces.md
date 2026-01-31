---
typeId: section
recordId: SRS-0202-4-external-interfaces
parent: spec:SRS-0202
fields:
  title: "External Interfaces"
  order: 4
  level: 1
---
The CouchDB service is treated as internal infrastructure.

Client-facing replication endpoints are presented via the Gateway on tenant origins (see `[[spec:SRS-0201]]`). Any direct CouchDB node/admin surface is intentionally out of scope for client access.

Precise service-to-service interface details (ports, auth, internal URLs) will be specified via future ICDs.
