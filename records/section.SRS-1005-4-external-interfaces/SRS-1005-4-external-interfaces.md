---
typeId: section
recordId: SRS-1005-4-external-interfaces
parent: spec:SRS-1005
fields:
  title: "External Interfaces"
  order: 50
  level: 1
---
Compass external interfaces are mode-aware tenant-origin surfaces.

- Local-only app route: `http://<tenant_id>.local/compass`
- Public custom-domain app route: `https://<tenant_id>.<box-host>/compass`
- Local-only replication endpoint: `http://<tenant_id>.local/db` (same-origin, via the Gateway)
- Public custom-domain replication endpoint: `https://<tenant_id>.<box-host>/db` (same-origin, via the Gateway)
- Local storage: shared local tenant replica `tenant_local` within the active origin
- Optional service APIs by mode: `http://<tenant_id>.local/api/compass/...` and `https://<tenant_id>.<box-host>/api/compass/...` (when present)
