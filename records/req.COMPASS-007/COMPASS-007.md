---
typeId: req
recordId: COMPASS-007
parent: section:SRS-1005-compass-specific-requirements
fields:
  title: "Compass SHALL evaluate candidate fit against the explicit user profile using inspectable matching logic"
  status: Draft
  testable: true
  area: compass
  rationale: "Compass should help users reason about fit, not hide a recommendation in opaque model behavior."
  order: 7
---

Compass SHALL evaluate each candidate against the active civic values profile using inspectable matching logic.

A candidate-fit evaluation SHALL be traceable to:

* explicit profile inputs,
* extracted candidate stance information, and
* underlying source references.

Compass MAY present summary scores or categories, but the explanation of candidate fit SHALL remain inspectable by the user.
