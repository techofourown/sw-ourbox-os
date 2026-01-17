# App: Files

**Status:** Selected  
**Bundled:** Yes  
**Created:** YYYY-MM-DD  
**Updated:** YYYY-MM-DD

---

## What this app is (user-facing)

A minimal file shelf for uploading, downloading, and browsing files from the OurBox appliance via a web UI.

## Success criteria

- Web-first, mobile-friendly experience
- Simple upload/download with clear visibility of stored files
- Safe defaults (auth required, conservative permissions)

## Data ownership expectations

- Files stored on the appliance with a persistent volume
- Easy to back up or export the underlying directory

## Candidates

- [Dufs](./candidates/dufs.md)

## Open questions

- Default permissions (delete allowed?)
- Quota/limits configuration surfaced in UI

## Related RFCs / ADRs

- [ADR-0002: Adopt Dufs for Files](../../decisions/ADR-0002-adopt-dufs-for-files.md)
