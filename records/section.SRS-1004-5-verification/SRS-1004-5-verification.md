---
typeId: section
recordId: SRS-1004-5-verification
parent: spec:SRS-1004
fields:
  title: "Verification"
  order: 60
  level: 1
---

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:

* **Test:** configure a watched public source, ingest content, and generate a source-grounded briefing with citations.
* **Test:** upload a political mailer image or PDF and confirm Scout extracts claims, issue references, and source-backed briefing output.
* **Test:** ingest two versions of the same source and confirm Scout surfaces change-over-time differences.
* **Test:** ask a question over the watched corpus and confirm the answer cites supporting `snapshot:*` records or explicitly states insufficient evidence.
* **Inspection:** confirm watched sources and prioritization rules are explicit tenant-visible configuration and that no hidden feed is the primary ranking mechanism.
* **Test:** confirm previously generated briefings and supporting source excerpts remain readable offline after first successful load.
