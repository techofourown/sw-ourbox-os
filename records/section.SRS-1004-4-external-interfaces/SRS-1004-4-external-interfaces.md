---
typeId: section
recordId: SRS-1004-4-external-interfaces
parent: spec:SRS-1004
fields:
  title: "External Interfaces"
  order: 4
  level: 1
---
- App route (local-only): `http://<tenant_id>.local/scout`
- App route (public custom-domain): `https://<tenant_id>.<box-host>/scout`
- Replication endpoint (local-only): `http://<tenant_id>.local/db`
- Replication endpoint (public custom-domain): `https://<tenant_id>.<box-host>/db` (same-origin, via Gateway)
- Optional service APIs (local-only): `http://<tenant_id>.local/api/scout/...`
- Optional service APIs (public custom-domain): `https://<tenant_id>.<box-host>/api/scout/...`
