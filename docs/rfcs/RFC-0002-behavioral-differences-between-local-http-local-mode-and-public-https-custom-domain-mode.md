# RFC-0002: Behavioral differences between local HTTP `.local` mode and public HTTPS custom-domain mode

## Why
This RFC documents behavioral differences between the two supported access modes so requirements and product claims remain precise.

## Core differences
- Local-only mode is HTTP-only and may present insecure-transport browser UI.
- Public custom-domain mode is HTTPS/TLS secure-context mode.
- Both modes support tenant-host app routing and same-origin `/db` replication.
- Full installable-PWA posture and reopen-offline behavior are public custom-domain mode behaviors.
- Local-only mode supports local data continuity but does not guarantee equivalent installability/reopen-offline behavior.

Terminology:
- full host: full host portion of URL before port/path,
- box-host: public custom-domain base host suffix,
- tenant host: full host used to address a tenant,
- tenant_id: leftmost DNS label of full host.

## Next steps
- Browser matrix validation for mode-specific behavior.
- Local-mode auth/session posture refinement.
- Requirement allocation/refinement where still open.
