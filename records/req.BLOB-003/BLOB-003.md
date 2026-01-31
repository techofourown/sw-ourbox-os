---
typeId: req
recordId: BLOB-003
parent: "section:SRS-0205-3-requirements"
fields:
  title: "Blob payload bytes SHALL use a deterministic sharded path layout"
  status: "Draft"
  testable: true
  area: "blob"
  rationale: "ADR-0006 establishes deterministic sharded path layout for blob payload bytes."
  order: 30
---

Blob payload bytes SHALL be stored using a deterministic sharded path layout under the tenant storage root.

**Trace:** [[adr:ADR-0006]]
