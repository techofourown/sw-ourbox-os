---
typeId: section
recordId: SRS-1003-verification
parent: spec:SRS-1003
fields:
  title: "Verification"
  order: 60
  level: 1
---

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:
- **Test:** offline send/receive behavior using the local tenant replica; then reconnect and replicate successfully.
- **Inspection:** confirm no DM/private-channel UI or enforcement exists within a tenant.
- **Test:** attachment upload/download round-trip with blob references in message docs.
- **Test (optional):** voice/video call signaling and call-history persistence.
