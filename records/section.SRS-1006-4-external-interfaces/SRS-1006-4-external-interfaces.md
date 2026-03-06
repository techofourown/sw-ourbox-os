---
typeId: section
recordId: SRS-1006-4-external-interfaces
parent: spec:SRS-1006
fields:
  title: "External Interfaces"
  order: 50
  level: 1
---

Spar external interfaces are tenant-origin HTTP surfaces and the standard replication surface.

* App route: `https://<tenant_id>.<box-host>/spar`
* Replication endpoint: `https://<tenant_id>.<box-host>/db` (same-origin, via the Gateway)
* Local storage: shared local tenant replica `tenant_local` within the tenant origin
* Supporting source artifacts: tenant blob store (when binary/large)
* Optional service APIs: `https://<tenant_id>.<box-host>/api/spar/...` for dialogue session management, challenge generation, source-grounded analysis, and reflection summaries (when present)

Spar MAY consume shared civic records already present in the shared local tenant replica (e.g., `claim:*`, `issue:*`, `brief:*`, `candidate:*`, `stance:*`, and `fit:*` records) when available.

Any additional APIs consumed or exposed by Spar are described via machine-readable API contracts (OpenAPI/JSON schema) and verified by automated integration tests.
