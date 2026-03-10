# ADR-0014: Adopt Two Access Modes: Local HTTP `.local` and Public HTTPS Custom-Domain

## Decision
OurBox supports two permanent first-class access modes:
- Local-only mode: `http://<tenant_id>.local/<app_slug>` and `http://<tenant_id>.local/db`
- Public custom-domain mode: `https://<tenant_id>.<box-host>/<app_slug>` and `https://<tenant_id>.<box-host>/db`

Rules:
- full host carries tenant context,
- `tenant_id` is derived from the leftmost DNS label of the full host,
- path identifies app,
- local-only mode is HTTP-only,
- public custom-domain mode is HTTPS/TLS.

Local-only mode and public custom-domain mode are different origins and therefore have separate local browser storage, service worker registration, and local tenant replicas.

## Repository norm
Architecture, glossary, and requirements artifacts use mode-aware language and this two-mode model.
