---
typeId: req
recordId: SCOUT-003
parent: section:SRS-1004-scout-specific-requirements
fields:
  title: "Scout SHALL preserve source snapshots and provenance"
  status: Draft
  testable: true
  area: data
  rationale: "Source-grounded civic analysis requires durable provenance and inspectable evidence."
  order: 3
---

For each fetched or uploaded artifact that Scout analyzes, Scout SHALL create or reference a `source:*` record and a `snapshot:*` record.

Each `snapshot:*` record SHALL include, at minimum:

* provenance (e.g., source URI or upload origin),
* observed/ingested timestamp,
* content hash/digest, and
* media type.

When source artifact payload bytes are binary or large, Scout SHALL store payload bytes in the tenant blob store by default and SHALL store only references in application documents.

**Trace:** [[spec:SyRS-0001]] DATA-006, DATA-007; [[spec:SRS-0205]]; [[adr:ADR-0005]]; [[adr:ADR-0006]]
