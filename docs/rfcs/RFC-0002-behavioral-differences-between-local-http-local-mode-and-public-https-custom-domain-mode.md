# RFC-0002: Behavioral Differences Between Local HTTP `.local` Mode and Public HTTPS Custom-Domain Mode

## Why
This RFC defines the behavioral differences between the two supported access modes so product, architecture, and requirements language stays precise and mode-aware.

## Modes
- Local-only mode: `http://<tenant_id>.local/<app_slug>` and `http://<tenant_id>.local/db`.
- Public custom-domain mode: `https://<tenant_id>.<box-host>/<app_slug>` and `https://<tenant_id>.<box-host>/db`.

Terms:
- full host: complete URL host before path/port.
- box-host: public custom-domain suffix after tenant label.
- tenant host: full host used to address a tenant.

## Common behavior
- full host carries tenant context,
- leftmost DNS label identifies `tenant_id`,
- path identifies app,
- same-origin replication endpoint is `/db` in each mode,
- local data continuity is supported while box is reachable and sync is opportunistic.

## Differences
- Local-only mode is HTTP-only and does not provide TLS transport authentication, confidentiality, or integrity.
- Browser insecure-transport UI can appear in local-only mode.
- `http://bob.local` and `https://bob.example.com` are different origins and do not share IndexedDB, Cache Storage, service worker registration, or local tenant replica.
- Public custom-domain mode is the full installable-PWA posture (secure context + service-worker-backed reopen-offline after first successful load).
- Local-only mode does not guarantee equivalent installability or reopen-offline behavior.

## Next steps
- Browser matrix validation.
- Local-mode auth/session posture refinement.
- Requirement allocation/refinement for any remaining open items.
