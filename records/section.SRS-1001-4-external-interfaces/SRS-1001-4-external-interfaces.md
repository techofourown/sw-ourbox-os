---
typeId: section
recordId: SRS-1001-4-external-interfaces
parent: spec:SRS-1001
fields:
  title: "External Interfaces"
  order: 4
  level: 1
---
SimpleNote external interfaces are tenant-origin HTTP surfaces and the standard replication surface.

- App route: `https://<tenant_id>.<box-host>/simplenote`
- Replication endpoint: `https://<tenant_id>.<box-host>/db` (same-origin, via the Gateway)
- Local storage: shared local tenant replica `tenant_local` within the tenant origin

Any additional APIs consumed or exposed by SimpleNote are described via machine-readable API contracts (OpenAPI/JSON schema) and verified
by automated integration tests.
