# Candidate: Dufs

**Status:** Selected  
**License:** TBD  
**Source:** URL  
**Created:** YYYY-MM-DD  
**Updated:** YYYY-MM-DD

---

## Project summary

Minimal web file server with upload/download support and directory browsing.

## Why it is interesting for OurBox

- Very small operational footprint suitable for appliance hardware
- Browser-first UI for quick file transfer without clients
- Aligns with "file shelf" mental model

## Fit vs criteria

- Web-first UX: Yes
- Self-hosting simplicity: Strong
- File handling: Upload and download with simple directory view
- Permissions: Configurable; defaults should be conservative

## Integration shape (high-level)

- Run as an OurBox app with a persistent volume mounted at `/data`

## Licensing notes

- Verify license and any feature gating before shipping

## Risks

- Not a sync solution; limited collaboration features
- Need to ensure authentication is enforced by default

## Decision status

- Selected (see ADR-0002)
