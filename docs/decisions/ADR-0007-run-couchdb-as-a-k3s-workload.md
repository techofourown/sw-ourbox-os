# ADR-0007: Run CouchDB as a k3s Workload (Not a Host Service)

## Date
2026-01-25

## Decision — tenant access posture
- Tenant-facing replication uses same-origin `/db` in both modes:
  - `http://<tenant_id>.local/db`
  - `https://<tenant_id>.<box-host>/db`
- Raw CouchDB node/admin endpoints are unexposed in both modes.
- Gateway is the only tenant-facing surface (HTTP local-only mode, HTTPS public custom-domain mode).
- CouchDB remains ClusterIP-only internal infrastructure.
