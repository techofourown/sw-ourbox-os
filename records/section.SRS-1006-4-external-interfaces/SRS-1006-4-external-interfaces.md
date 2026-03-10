---
typeId: section
recordId: SRS-1006-4-external-interfaces
parent: spec:SRS-1006
fields:
  title: "External Interfaces"
  order: 50
  level: 1
---
Spar external interfaces are mode-aware tenant-origin surfaces.

- Local-only app route: `http://<tenant_id>.local/spar`
- Public custom-domain app route: `https://<tenant_id>.<box-host>/spar`
- Local-only replication endpoint: `http://<tenant_id>.local/db` (same-origin, via the Gateway)
- Public custom-domain replication endpoint: `https://<tenant_id>.<box-host>/db` (same-origin, via the Gateway)
- Local storage: shared local tenant replica `tenant_local` within the active origin
- Optional service APIs by mode: `http://<tenant_id>.local/api/spar/...` and `https://<tenant_id>.<box-host>/api/spar/...` (when present)
