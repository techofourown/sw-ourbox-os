---
typeId: req
recordId: BLOB-001
parent: "section:SRS-0205-3-requirements"
fields:
  title: "Tenant blob store SHALL be content-addressed by a canonical multihash key"
  status: "Draft"
  testable: true
  area: "blob"
  rationale: "ADR-0005 establishes content-addressed blob storage keyed by a canonical multihash key."
  order: 10
---

The tenant blob store SHALL store blob payload bytes in a content-addressed manner keyed by a canonical multihash key.

**Trace:** [[adr:ADR-0005]]
