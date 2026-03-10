# RFC-0002: Behavioral differences between local HTTP `.local` mode and public HTTPS custom-domain mode

## What
This RFC documents behavioral differences between the two permanent access modes.

## Why
The two-mode architecture intentionally provides different transport and browser-platform behavior:
- local-only mode is HTTP-only,
- public custom-domain mode is HTTPS/TLS secure-context mode.

## Core behavioral differences
- Both modes provide tenant-host routing, local data continuity, and opportunistic sync while box is reachable.
- Public custom-domain mode provides full service-worker-backed installability and reopen-offline posture after first successful load.
- Local-only mode does not guarantee equivalent installability or reopen-offline behavior.
- `http://<tenant_id>.local` and `https://<tenant_id>.<box-host>` are different origins and do not share IndexedDB, Cache Storage, service workers, or local tenant replicas.

## Next Steps
- Browser matrix validation for mode-specific behavior remains required.
- Local-only mode auth/session posture definition remains required.
- Requirement allocation/refinement remains open where traceability needs additional granularity.

## References
- ADR-0014
