---
typeId: section
recordId: SRS-0201-4-external-interfaces
parent: spec:SRS-0201
fields:
  title: "External Interfaces"
  order: 4
  level: 1
---
Gateway external interfaces are tenant-origin HTTP/HTTPS surfaces in two access modes:
- local-only mode tenant hosts: `<tenant_id>.local` over HTTP
- optional local landing host: `ourbox.local` over HTTP
- public custom-domain tenant hosts: `*.<box-host>` over HTTPS/TLS
- app paths: `/<app_slug>`
- replication path: `/db`
- API paths: `/api/...` (when present)

Same-origin replication endpoints are:
- `http://<tenant_id>.local/db`
- `https://<tenant_id>.<box-host>/db`

The authoritative definition of these external surfaces (host routing, paths, routing objects, and service bindings)
is the versioned deployment baseline (rendered Kubernetes manifests) and the running cluster state, verified by
conformance/integration tests (see ADR-0008).
