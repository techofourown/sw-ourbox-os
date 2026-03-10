# ADR-0003: Standardize on Tenant as the OurBox OS Data Boundary Term

## Date
2026-01-25

## Context
Tenant is the canonical top-level data boundary term.

## Decision
Tenant remains the single canonical term for the data boundary across code, docs, APIs, and UI.

## Normative design rules
1. Use tenant everywhere for the data boundary.
2. `tenant_id` is canonical boundary identifier.
3. Tenant context is derived from the leftmost DNS label of the full host.
4. Tenant-origin patterns:
   - local-only mode: `http://<tenant_id>.local/...`
   - public custom-domain mode: `https://<tenant_id>.<box-host>/...`
5. Path identifies app in both modes.

## References
- ADR-0014
