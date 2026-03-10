---
typeId: section
recordId: SRS-0201-4-external-interfaces
parent: spec:SRS-0201
fields:
  title: "External Interfaces"
  order: 4
  level: 1
---
Gateway external interfaces are mode-aware tenant-origin surfaces:
- local-only mode tenant hosts: `<tenant_id>.local` over HTTP
- optional local landing host: `ourbox.local` over HTTP
- public custom-domain tenant hosts: `*.<box-host>` over HTTPS/TLS
- app paths: `/<app_slug>`
- replication path: `/db`
- API paths: `/api/...` (when present)
