---
typeId: req
recordId: COMPASS-005
parent: section:SRS-1005-compass-specific-requirements
fields:
  title: "Compass SHALL preserve source provenance for candidate and contest materials"
  status: Draft
  testable: true
  area: data
  rationale: "Values-to-candidate matching must remain inspectable and tied back to evidence."
  order: 5
---

For each fetched or uploaded artifact that Compass analyzes, Compass SHALL create or reference a `source:*` record and a `snapshot:*` record.

Each referenced or created `snapshot:*` record SHALL include, at minimum:

* provenance (e.g., source URI or upload origin),
* observed/ingested timestamp,
* content hash/digest, and
* media type.

When source artifact payload bytes are binary or large, Compass SHALL store payload bytes in the tenant blob store by default and SHALL store only references in application documents.

**Trace:** [[spec:SyRS-0001]] DATA-006, DATA-007; [[spec:SRS-0205]]; [[adr:ADR-0005]]; [[adr:ADR-0006]]
