# ADR-0007: Run CouchDB as a k3s workload

## Decision — Tenant access posture
- Clients replicate same-origin through gateway `/db` in both modes:
  - `http://<tenant_id>.local/db`
  - `https://<tenant_id>.<box-host>/db`
- Raw CouchDB remains unexposed in both modes.
- CouchDB is ClusterIP-only internal service.
- Gateway is the tenant-facing surface over HTTP or HTTPS according to mode.
