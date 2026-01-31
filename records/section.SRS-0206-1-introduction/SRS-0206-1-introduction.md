---
typeId: section
recordId: SRS-0206-1-introduction
parent: "spec:SRS-0206"
fields:
  title: "Introduction"
  level: 1
  order: 1
---

This SRS defines requirements for identity and tenant membership posture in OurBox OS.

Scope includes:
- identifier constraints for `tenant_id` and `user_id`
- tenant membership as the authorization gate at the tenant boundary
- authorization decision inputs (user identity + tenant context + membership + roles/capabilities)

Out of scope:
- gateway routing and ingress mechanics (see `[[spec:SRS-0201]]`)
- token formats, header names, and session mechanics (future ICDs)
- UI flows for login/tenant management (not specified here)
