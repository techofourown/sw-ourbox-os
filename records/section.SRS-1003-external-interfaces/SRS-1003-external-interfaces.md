---
typeId: section
recordId: SRS-1003-external-interfaces
parent: spec:SRS-1003
fields:
  title: "External Interfaces"
  order: 50
  level: 1
---

Messager external interfaces are tenant-origin HTTP surfaces and the standard replication surface.

- App route: `https://<tenant_id>.<box-host>/messager`
- Replication endpoint: `https://<tenant_id>.<box-host>/db` (same-origin, via the Gateway)
- Local storage: shared local tenant replica `tenant_local` within the tenant origin
- Attachments: tenant blob store (accessed via platform services / gateway-mediated APIs when present)

Any additional APIs consumed or exposed by Messager are described via machine-readable API contracts (OpenAPI/JSON schema) and verified
by automated integration tests.
