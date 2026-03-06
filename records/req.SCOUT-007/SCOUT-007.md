---
typeId: req
recordId: SCOUT-007
parent: section:SRS-1004-scout-specific-requirements
fields:
  title: "Scout SHALL answer questions over the watched corpus with citations and explicit insufficiency"
  status: Draft
  testable: true
  area: scout
  rationale: "Question-answering is only trustworthy when grounded in the watched corpus and honest about gaps."
  order: 7
---

Scout SHALL answer user questions over the watched corpus with citations to underlying `snapshot:*` records.

When sufficient evidence is not available in the watched corpus, Scout SHALL say so explicitly and SHALL NOT present unsupported certainty as established fact.
