---
typeId: section
recordId: SRS-0205-4-external-interfaces
parent: "spec:SRS-0205"
fields:
  title: "External Interfaces"
  level: 1
  order: 4
---

The tenant blob store is treated as internal infrastructure.

Client-visible blob upload/download interfaces (if/when introduced) are defined as tenant-origin HTTP surfaces and described via
machine-readable API contracts (OpenAPI/JSON schema), with conformance tests. This SRS specifies blob-store invariants and on-box storage
posture; HTTP/API surfaces are mediated by the Gateway and/or platform services.
