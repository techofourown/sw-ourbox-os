---
typeId: section
recordId: SRS-1003-external-interfaces
parent: spec:SRS-1003
fields:
  title: "External Interfaces"
  order: 4
  level: 1
---
- App route (local-only): `http://<tenant_id>.local/messager`
- App route (public custom-domain): `https://<tenant_id>.<box-host>/messager`
- Replication endpoint (local-only): `http://<tenant_id>.local/db`
- Replication endpoint (public custom-domain): `https://<tenant_id>.<box-host>/db` (same-origin, via Gateway)
