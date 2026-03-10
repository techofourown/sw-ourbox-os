---
typeId: section
recordId: SRS-1001-4-external-interfaces
parent: spec:SRS-1001
fields:
  title: "External Interfaces"
  order: 4
  level: 1
---
- App route (local-only): `http://<tenant_id>.local/simplenote`
- App route (public custom-domain): `https://<tenant_id>.<box-host>/simplenote`
- Replication endpoint (local-only): `http://<tenant_id>.local/db`
- Replication endpoint (public custom-domain): `https://<tenant_id>.<box-host>/db` (same-origin, via Gateway)
