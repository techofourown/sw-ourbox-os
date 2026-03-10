---
typeId: req
recordId: DATA-008
parent: section:2-data-and-replication
fields:
  title: "Local tenant replicas SHALL be origin-split across access modes"
  testable: true
  status: "Draft"
  rationale: "Browser origin rules isolate local storage by scheme+host+port."
  area: "data"
  order: 8
---
For the same tenant and browser, `http://<tenant_id>.local` and `https://<tenant_id>.<box-host>` SHALL be treated as different origins and therefore different local tenant replicas.
