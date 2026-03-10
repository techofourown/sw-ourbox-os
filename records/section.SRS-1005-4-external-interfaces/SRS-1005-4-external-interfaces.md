---
typeId: section
recordId: SRS-1005-4-external-interfaces
parent: spec:SRS-1005
fields:
  title: "External Interfaces"
  order: 4
  level: 1
---
- App route (local-only): `http://<tenant_id>.local/compass`
- App route (public custom-domain): `https://<tenant_id>.<box-host>/compass`
- Replication endpoint (local-only): `http://<tenant_id>.local/db`
- Replication endpoint (public custom-domain): `https://<tenant_id>.<box-host>/db` (same-origin, via Gateway)
- Optional service APIs (local-only): `http://<tenant_id>.local/api/compass/...`
- Optional service APIs (public custom-domain): `https://<tenant_id>.<box-host>/api/compass/...`
