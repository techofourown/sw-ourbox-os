---
typeId: section
recordId: SRS-1004-4-external-interfaces
parent: spec:SRS-1004
fields:
  title: "External Interfaces"
  order: 50
  level: 1
---
Scout external interfaces are tenant-origin app/replication surfaces in both access modes.

- App route (local-only mode): `http://<tenant_id>.local/scout`
- App route (public custom-domain mode): `https://<tenant_id>.<box-host>/scout`
- Replication endpoint (local-only mode): `http://<tenant_id>.local/db`
- Replication endpoint (public custom-domain mode): `https://<tenant_id>.<box-host>/db`
- Local storage: shared local tenant replica `tenant_local` within the current tenant origin
- Source artifacts and retained binary snapshots: tenant blob store (when binary/large)
- Optional service APIs: `/api/scout/...` on the current tenant origin

Public custom-domain mode is the full installable-PWA posture. Local-only mode remains HTTP local mode with local data continuity and opportunistic sync, without equivalent full installability/reopen-offline guarantees.
