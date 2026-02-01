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

Concrete in-cluster service interfaces (Service names, ports, authentication material, internal URLs, and any network policy)
are defined by the versioned deployment baseline manifests and are discoverable via cluster inspection (ADR-0008).

Any additional protocol-level contracts introduced between services (beyond what the deployment baseline expresses) are defined
as machine-readable contract artifacts (OpenAPI/JSON schema) and verified by automated tests.
