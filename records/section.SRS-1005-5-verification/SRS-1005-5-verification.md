---
typeId: section
recordId: SRS-1005-5-verification
parent: spec:SRS-1005
fields:
  title: "Verification"
  order: 60
  level: 1
---

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:

* **Test:** create an explicit user values profile and confirm the profile remains user-visible and editable.
* **Test:** configure a contest scope and candidate set, ingest candidate materials, and confirm Compass extracts source-grounded candidate stances.
* **Test:** generate candidate-fit evaluations and confirm each evaluation explains its reasoning with source references and explicit user-priority inputs.
* **Test:** change issue weighting or red-line configuration and confirm candidate-fit outputs update predictably.
* **Test:** confirm Compass surfaces insufficient evidence when candidate-position data is missing or ambiguous.
* **Inspection:** confirm Compass does not require hidden psychographic inference or hidden persuasion optimization as the primary basis for output.
* **Test:** confirm saved profiles, candidate-fit evaluations, and cited source excerpts remain readable offline after first successful load.
