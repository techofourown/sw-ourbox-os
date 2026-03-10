# Requirements Management Guide

## Authoring rules
- Any requirement mentioning tenant origin, app URL, replication endpoint, PWA/installability, service worker, or offline behavior SHALL be explicit about mode unless truly mode-agnostic.
- Use glossary terms: full host, box-host, tenant host, Local-only mode, Public custom-domain mode.
- Do not use “subdomain” as the primary architecture term.
- If a requirement is only true in public custom-domain mode, state that scope.
- If a requirement is true in both modes, state both modes.
- If local-only mode is HTTP-only with weaker guarantees, state those implications.

## Source of truth and generation
- Do not hand-edit compiled SyRS/SRS outputs.
- Update authoritative GraphMD source records under `records/`.
- Recompile with `npm test`.
