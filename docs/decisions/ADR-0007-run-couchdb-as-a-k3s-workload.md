# ADR-0007: Run CouchDB as a k3s Workload (Not a Host Service)

## Date
2026-01-25

## Decision
CouchDB runs as an internal k3s workload with ClusterIP-only exposure.

Tenant access posture:
- Same-origin replication surface in both modes:
  - `http://<tenant_id>.local/db`
  - `https://<tenant_id>.<box-host>/db`
- Raw CouchDB is unexposed in both modes.
- Gateway is the tenant-facing HTTP/HTTPS surface according to mode.

## References
- ADR-0014
