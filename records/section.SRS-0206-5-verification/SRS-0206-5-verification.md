---
typeId: section
recordId: SRS-0206-5-verification
parent: "spec:SRS-0206"
fields:
  title: "Verification"
  level: 1
  order: 5
---

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:
- **Inspection:** identifier rules for `tenant_id` and `user_id` are enforced consistently.
- **Test:** membership gating prevents cross-tenant access when hostnames differ.
