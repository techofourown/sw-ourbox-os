---
typeId: section
recordId: SRS-1001-4-external-interfaces
parent: spec:SRS-1001
fields:
  title: "External Interfaces"
  order: 4
  level: 1
---
Simplenote external interfaces are mode-aware tenant-origin surfaces.

- Local-only app route: `http://<tenant_id>.local/simplenote`
- Public custom-domain app route: `https://<tenant_id>.<box-host>/simplenote`
- Local-only replication endpoint: `http://<tenant_id>.local/db` (same-origin, via the Gateway)
- Public custom-domain replication endpoint: `https://<tenant_id>.<box-host>/db` (same-origin, via the Gateway)
- Local storage: shared local tenant replica `tenant_local` within the active origin
