# Candidate: Flatnotes

**Status:** Selected  
**License:** TBD  
**Source:** URL  
**Created:** YYYY-MM-DD  
**Updated:** YYYY-MM-DD

---

## Project summary

Minimal notes app with file-based storage and a web UI.

## Why it is interesting for OurBox

- Simple, mobile-friendly note capture
- File-backed Markdown storage aligns with export/backup goals
- Lightweight deployment fits appliance constraints

## Fit vs criteria

- Offline: Local storage; evaluate offline behaviors
- Mobile UX: Yes
- Export/data ownership: Strong (Markdown files)
- Multi-user support: Limited; suitable for single user or small trusted group

## Integration shape (high-level)

- Run as an OurBox app with a persistent volume mounted at `/data`

## Licensing notes

- Verify license compatibility before shipping

## Risks

- Limited structure/hierarchy compared to heavier note systems
- Attachments may be basic; not a file shelf replacement

## Decision status

- Selected (see ADR-0001)
