# ADR-0003: Standardize on Tenant as the OurBox OS Data Boundary Term

## Date
2026-01-25

## Decision
Tenant remains the top-level data boundary.

Rule 4 — Tenant origin (full host)
- local-only mode: `http://<tenant_id>.local/...`
- public custom-domain mode: `https://<tenant_id>.<box-host>/...`

Short form:
- full host carries tenant context,
- leftmost DNS label identifies `tenant_id`,
- path identifies app.

Terminology uses full host / tenant host / leftmost DNS label as primary terms.
