# ADR-0002: Adopt CouchDB + PouchDB and Standardize OurBox Data Modeling (Tenant DBs + Partitions)

## Date
2026-01-25

## Context
OurBox uses two tenant-origin patterns:
- `http://<tenant_id>.local/...`
- `https://<tenant_id>.<box-host>/...`

Same-origin replication is exposed as `/db` in the active mode.

## Decision
Rule 7 — Local tenant replicas are per device + tenant origin and shared across apps.
- Tenant origin includes both mode patterns.
- The same tenant in local-only mode and public custom-domain mode is a different origin and therefore a different local tenant replica.
- Example on one browser:
  - `http://bob.local` uses one `tenant_local` DB bucket.
  - `https://bob.example.com` uses a different `tenant_local` DB bucket.

Rule 8 — Replication posture.
- Replication SHALL use the same-origin tenant endpoint in the current mode:
  - `http://<tenant_id>.local/db`
  - `https://<tenant_id>.<box-host>/db`

`tenant_local` remains the recommended PouchDB name within an origin; origin separation provides isolation.
