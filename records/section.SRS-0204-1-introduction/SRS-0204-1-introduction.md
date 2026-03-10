---
typeId: section
recordId: SRS-0204-1-introduction
parent: spec:SRS-0204
fields:
  title: "Introduction"
  order: 1
  level: 1
---
The Local Tenant Replica stores tenant data in-browser per tenant origin.

Tenant origins include both mode patterns:
- `http://<tenant_id>.local`
- `https://<tenant_id>.<box-host>`

These are different origins and therefore different local tenant replicas.
