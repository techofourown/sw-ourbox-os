---
typeId: req
recordId: BLOB-002
parent: "section:SRS-0205-3-requirements"
fields:
  title: "Tenant blob store SHALL NOT chunk blob payload bytes"
  status: "Draft"
  testable: true
  area: "blob"
  rationale: "ADR-0005 explicitly establishes a no-chunking posture for blob payload storage."
  order: 20
---

Blob payload bytes stored in the tenant blob store SHALL NOT be chunked; a blob key identifies the full payload bytes.

**Trace:** [[adr:ADR-0005]]
