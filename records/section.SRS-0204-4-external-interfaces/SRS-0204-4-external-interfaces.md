---
typeId: section
recordId: SRS-0204-4-external-interfaces
parent: spec:SRS-0204
fields:
  title: "External Interfaces"
  order: 4
  level: 1
---
Replication interfaces:
- local-only: `http://<tenant_id>.local/db`
- public custom-domain: `https://<tenant_id>.<box-host>/db`

Same tenant across these two origins uses distinct local replicas on the same browser profile.
