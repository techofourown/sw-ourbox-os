---
typeId: section
recordId: SRS-0201-4-external-interfaces
parent: spec:SRS-0201
fields:
  title: "External Interfaces"
  order: 4
  level: 1
---
Gateway tenant-facing interfaces:
- local-only app route pattern: `http://<tenant_id>.local/<app_slug>`
- public app route pattern: `https://<tenant_id>.<box-host>/<app_slug>`
- local-only replication endpoint: `http://<tenant_id>.local/db`
- public replication endpoint: `https://<tenant_id>.<box-host>/db`
- replication path: `/db`
