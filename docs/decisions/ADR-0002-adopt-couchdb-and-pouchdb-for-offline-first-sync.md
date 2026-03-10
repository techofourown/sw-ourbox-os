# ADR-0002: Adopt CouchDB and PouchDB for Offline-First Sync

## Context
Tenant origins are supported in both access modes:
- `http://<tenant_id>.local/...`
- `https://<tenant_id>.<box-host>/...`

## Decision
Rule 7: Local tenant replicas are per device + tenant origin and shared across apps.

Tenant origin is mode-specific. `http://<tenant_id>.local` and `https://<tenant_id>.<box-host>` are different origins and therefore different local tenant replicas.

Example: On one browser, `http://bob.local/simplenote` and `https://bob.example.com/simplenote` use distinct local replicas even though `tenant_id` is `bob`.

Rule 8: Same-origin replication occurs through the current mode tenant origin:
- `http://<tenant_id>.local/db`
- `https://<tenant_id>.<box-host>/db`

`tenant_local` remains the recommended local PouchDB database name within an origin; origin separation enforces cross-mode isolation.
