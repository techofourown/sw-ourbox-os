# ADR-0014: Adopt Two Access Modes: Local HTTP `.local` and Public HTTPS Custom-Domain

## Date
2026-03-10

## Context
OurBox supports tenant-host access in two first-class modes while preserving one routing model:
- full host carries tenant context,
- `tenant_id` is the leftmost DNS label of the full host,
- path identifies app.

## Decision
Two permanent access modes are adopted:

1. Local-only mode
   - `http://<tenant_id>.local/<app_slug>`
   - `http://<tenant_id>.local/db`
   - optional local landing host `http://ourbox.local/`
   - HTTP-only; no TLS transport guarantees; insecure-transport browser UI may appear.

2. Public custom-domain mode
   - `https://<tenant_id>.<box-host>/<app_slug>`
   - `https://<tenant_id>.<box-host>/db`
   - HTTPS/TLS secure-context posture and full installable-PWA posture.

Mode-aware language is the repository norm across architecture, glossary, and requirements artifacts.

## Consequences
- Same tenant across local-only/public modes is an origin split and therefore a local-replica split.
- Gateway routing and requirements are mode-aware.

## References
- RFC-0002
