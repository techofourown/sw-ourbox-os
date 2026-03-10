---
typeId: section
recordId: SRS-0204-1-introduction
parent: "spec:SRS-0204"
fields:
  title: "Introduction"
  order: 1
  level: 1
---
This SRS defines requirements for the local tenant replica (`tenant_local`) within a tenant origin.

Tenant-origin patterns:
- `http://<tenant_id>.local`
- `https://<tenant_id>.<box-host>`

For the same tenant in one browser/device, these are different origins and therefore different local tenant replicas.
