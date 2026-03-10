# ADR-0014: Adopt Two Access Modes: Local HTTP `.local` and Public HTTPS Custom-Domain

## Date
2026-03-10

## Decision
OurBox supports two first-class tenant access modes.

1. Local-only mode
- `http://<tenant_id>.local/<app_slug>`
- `http://<tenant_id>.local/db`
- optional local landing host: `http://ourbox.local/`
- HTTP-only; no TLS.

2. Public custom-domain mode
- `https://<tenant_id>.<box-host>/<app_slug>`
- `https://<tenant_id>.<box-host>/db`
- HTTPS/TLS.

Unified routing model:
- full host carries tenant context,
- `tenant_id` is the leftmost DNS label of the full host,
- path identifies app.

Repository norm:
- architecture, glossary, and requirements use this two-mode model.
- mode-aware language is the standard for tenant origin, replication endpoint, and PWA/offline statements.
