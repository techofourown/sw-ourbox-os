# ADR-0002: Adopt CouchDB + PouchDB and Standardize OurBox Data Modeling (Tenant DBs + Partitions)

## Date
2026-01-25

## Context
OurBox uses tenant-scoped browser origins in two access modes.

## Decision
CouchDB on-box and PouchDB in-browser are the primary store/sync stack.

## Normative design rules
### 7) Local tenant replicas are per device + tenant origin and shared across apps
Tenant-origin patterns:
- `http://<tenant_id>.local/...`
- `https://<tenant_id>.<box-host>/...`

Same tenant, same browser, different modes are different origins and therefore different local tenant replicas.

Example: `http://family.local/simplenote` and `https://family.example.com/simplenote` use different IndexedDB/Cache Storage/service worker buckets.

`tenant_local` remains the stable local PouchDB DB name within an origin; origin separation provides isolation.

### 8) Replication posture
Replication is same-origin through gateway `/db` in the current mode:
- `http://<tenant_id>.local/db`
- `https://<tenant_id>.<box-host>/db`

## References
- ADR-0014
- RFC-0002
