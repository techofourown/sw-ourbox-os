# ADR-0003: Standardize on “tenant” as the data-boundary term

## Decision
Rule 4: Tenant origin (tenant host) patterns:
- local-only mode: `http://<tenant_id>.local/...`
- public custom-domain mode: `https://<tenant_id>.<box-host>/...`

Architecture rule:
- full host carries tenant context,
- leftmost DNS label identifies `tenant_id`,
- path identifies app.

Tenant remains the data boundary in both modes.
