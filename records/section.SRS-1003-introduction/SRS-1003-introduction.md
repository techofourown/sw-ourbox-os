---
typeId: section
recordId: SRS-1003-introduction
parent: spec:SRS-1003
fields:
  title: "Introduction"
  order: 20
  level: 1
---

This SRS defines requirements for the **Messager** app experience.

Scope includes:
- tenant-scoped channels and messages
- offline-first behavior consistent with ADR-0001 posture
- shared local tenant replica usage (`tenant_local`)
- message document model and attachment handling using the tenant blob store
- optional voice/video calls within the tenant boundary
- optional bot/automation behavior within tenant membership semantics

Out of scope:
- interoperability with external messaging ecosystems (e.g., SMS, email, Matrix, ActivityPub)
- privacy compartments inside a tenant (DMs, secret channels) — use separate tenants instead
