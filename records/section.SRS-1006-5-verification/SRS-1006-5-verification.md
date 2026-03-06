---
typeId: section
recordId: SRS-1006-5-verification
parent: spec:SRS-1006
fields:
  title: "Verification"
  order: 60
  level: 1
---

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:

* **Test:** start a dialogue session around a user-provided civic claim, question, or proposal and confirm that user-selected challenge modes change the output type appropriately.
* **Test:** attach or select source materials and confirm Spar cites relevant supporting or opposing source records when source-grounded responses are available.
* **Test:** request separation of facts, value judgments, predictions, and tradeoffs and confirm Spar distinguishes those categories in its output.
* **Test:** ask what evidence would strengthen, weaken, or change a conclusion and confirm Spar returns explicit evidence conditions or states that the available evidence is insufficient.
* **Inspection:** confirm dialogue goals, challenge modes, and explicit conversation constraints are tenant-visible configuration and that hidden persuasion optimization is not the primary basis for output.
* **Test:** confirm generated turns record authorship and provenance and remain append-only after creation.
* **Test:** confirm saved dialogues and reflection summaries remain readable offline after first successful load.
