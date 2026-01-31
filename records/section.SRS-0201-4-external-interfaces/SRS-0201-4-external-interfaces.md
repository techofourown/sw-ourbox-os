---
typeId: section
recordId: SRS-0201-4-external-interfaces
parent: spec:SRS-0201
fields:
  title: "External Interfaces"
  order: 4
  level: 1
---
Gateway external interfaces are HTTP(S) surfaces on tenant origins, including:
- wildcard tenant hosts: `*.<box-host>`
- app paths: `/<app_slug>`
- replication path: `/db`
- API paths: `/api/...` (when present)

Identity context propagation to internal services (headers/claims/etc.) SHALL be specified in a future Interface Control Document (ICD). This SRS does not define header names or token formats.
