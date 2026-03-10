---
typeId: section
recordId: SRS-1002-4-external-interfaces
parent: spec:SRS-1002
fields:
  title: "External Interfaces"
  order: 50
  level: 1
---
Richnote external interfaces are mode-aware tenant-origin surfaces.

- App routes:
  - local-only mode: `http://<tenant_id>.local/richnote`
  - public custom-domain mode: `https://<tenant_id>.<box-host>/richnote`
- Replication endpoints:
  - `http://<tenant_id>.local/db`
  - `https://<tenant_id>.<box-host>/db`
- Local storage: shared local tenant replica `tenant_local` within one origin

Full installable-PWA posture is scoped to public custom-domain mode. Local-only mode is HTTP local mode with local data continuity and opportunistic sync while reachable.
