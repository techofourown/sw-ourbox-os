---
typeId: section
recordId: SRS-1004-4-external-interfaces
parent: spec:SRS-1004
fields:
  title: "External Interfaces"
  order: 50
  level: 1
---

Scout external interfaces are tenant-origin HTTP surfaces and the standard replication surface.

* App route: `https://<tenant_id>.<box-host>/scout`
* Replication endpoint: `https://<tenant_id>.<box-host>/db` (same-origin, via the Gateway)
* Local storage: shared local tenant replica `tenant_local` within the tenant origin
* Source artifacts and retained binary snapshots: tenant blob store (when binary/large)
* Optional service APIs: `https://<tenant_id>.<box-host>/api/scout/...` for source monitoring, extraction, briefing generation, and question-answering (when present)

Any additional APIs consumed or exposed by Scout are described via machine-readable API contracts (OpenAPI/JSON schema) and verified by automated integration tests.
