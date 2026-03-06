---
typeId: req
recordId: COMPASS-006
parent: section:SRS-1005-compass-specific-requirements
fields:
  title: "Compass SHALL extract candidate stances tied to source evidence"
  status: Draft
  testable: true
  area: compass
  rationale: "Candidate-fit evaluation depends on durable stance extraction rather than opaque free-form model impressions."
  order: 6
---

Compass SHALL extract candidate stances from analyzed materials when supported by source evidence.

Each durable `stance:*` record SHALL identify, at minimum:

* the candidate,
* the issue or issue reference,
* the extracted position, characterization, or stated uncertainty, and
* one or more supporting source references.

Where a relevant `issue:*` record exists in the tenant DB, Compass SHOULD link extracted stances to that `issue:*` record rather than duplicating issue identity.
