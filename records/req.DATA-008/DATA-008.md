---
typeId: req
recordId: DATA-008
parent: section:2-data-and-replication
fields:
  title: "Local tenant replicas SHALL remain origin-separated across access modes"
  testable: true
  status: "Draft"
  rationale: "Browser origin boundaries isolate local replicas across scheme/host differences."
  area: "data"
  order: 8
---
The same tenant accessed as `http://<tenant_id>.local` and `https://<tenant_id>.<box-host>` SHALL
be treated as different browser origins and therefore SHALL use different local tenant replicas.
