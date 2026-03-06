---
typeId: req
recordId: SPAR-013
parent: section:SRS-1006-spar-specific-requirements
fields:
  title: "Spar dialogue turns and generated outputs SHALL record provenance and remain append-only"
  status: Draft
  testable: true
  area: data
  rationale: "Users need a durable, inspectable record of what was said, what was generated, and how the dialogue evolved over time."
  order: 13
---

Each `turn:*` document SHALL record, at minimum:

* turn author type (e.g., user or Spar),
* created timestamp,
* parent dialog ID, and
* referenced source, claim, or generation inputs sufficient to reconstruct turn provenance when applicable.

After a `turn:*`, `challenge:*`, or `reflection:*` document is created, Spar SHALL treat it as immutable.

Corrections or follow-on elaborations SHALL be represented as new linked documents rather than by overwriting the original record.
