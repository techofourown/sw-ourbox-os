---
typeId: section
recordId: SRS-1002-4-external-interfaces
parent: spec:SRS-1002
fields:
  title: "External Interfaces"
  order: 4
  level: 1
---
Richnote external interfaces are mode-aware tenant-origin surfaces.

- Local-only app route: `http://<tenant_id>.local/richnote`
- Public custom-domain app route: `https://<tenant_id>.<box-host>/richnote`
- Local-only replication endpoint: `http://<tenant_id>.local/db` (same-origin, via the Gateway)
- Public custom-domain replication endpoint: `https://<tenant_id>.<box-host>/db` (same-origin, via the Gateway)
- Local storage: shared local tenant replica `tenant_local` within the active origin
