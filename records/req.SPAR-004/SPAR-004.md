---
typeId: req
recordId: SPAR-004
parent: section:SRS-1006-spar-specific-requirements
fields:
  title: "Spar SHALL preserve source provenance for fetched or uploaded supporting materials"
  status: Draft
  testable: true
  area: data
  rationale: "Source-grounded civic dialogue must remain inspectable and tied back to evidence."
  order: 4
---

For each fetched or uploaded artifact that Spar analyzes, Spar SHALL create or reference a `source:*` record and a `snapshot:*` record.

Each referenced or created `snapshot:*` record SHALL include, at minimum:

* provenance (e.g., source URI or upload origin),
* observed/ingested timestamp,
* content hash/digest, and
* media type.

When source artifact payload bytes are binary or large, Spar SHALL store payload bytes in the tenant blob store by default and SHALL store only references in application documents.

**Trace:** [[spec:SyRS-0001]] DATA-006, DATA-007; [[spec:SRS-0205]]; [[adr:ADR-0005]]; [[adr:ADR-0006]]
