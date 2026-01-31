---
typeId: section
recordId: SRS-0204-5-verification
parent: "spec:SRS-0204"
fields:
  title: "Verification"
  order: 5
  level: 1
---

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:
- **Test:** offline write/read against the local tenant replica; then reconnect and replicate successfully.
- **Inspection:** confirm a single local tenant replica is used across shipped apps within the same tenant origin.
