---
typeId: section
recordId: SRS-1005-4-external-interfaces
parent: spec:SRS-1005
fields:
  title: "External Interfaces"
  order: 50
  level: 1
---

Compass external interfaces are tenant-origin HTTP surfaces and the standard replication surface.

* App route: `https://<tenant_id>.<box-host>/compass`
* Replication endpoint: `https://<tenant_id>.<box-host>/db` (same-origin, via the Gateway)
* Local storage: shared local tenant replica `tenant_local` within the tenant origin
* Candidate and contest source artifacts: tenant blob store (when binary/large)
* Optional service APIs: `https://<tenant_id>.<box-host>/api/compass/...` for profile capture, contest scoping, stance extraction, fit evaluation, and candidate comparison (when present)

Compass MAY consume source-grounded civic records already present in the shared local tenant replica (e.g., `source:*`, `snapshot:*`, `issue:*`, and `brief:*` records) when available.

Any additional APIs consumed or exposed by Compass are described via machine-readable API contracts (OpenAPI/JSON schema) and verified by automated integration tests.
