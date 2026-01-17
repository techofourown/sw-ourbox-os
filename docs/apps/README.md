# Apps (App Catalog + Dossiers)

This folder is a living reference for the OurBox OS app suite and upstream OSS candidates.
It is intentionally lightweight and continuously editable.

## What belongs here

- App suite inventory and status (bundled vs optional)
- Per-app dossiers (what the app is, criteria, open questions)
- Upstream candidate evaluations and notes
- Licensing, maintenance, UX fit, and integration considerations

## What does NOT belong here

- Platform-wide changes to app model, permissions, lifecycle, identity, etc. -> RFCs
- Final decisions on app suite or upstream selections -> ADRs

## Status vocabulary

- **Idea**: We might want this app or capability.
- **Exploring**: Actively evaluating candidates.
- **Shortlisted**: Down to a few candidates.
- **Selected**: Decision made (must link an ADR).
- **Shipped**: Available in a release.
- **Deprecated**: No longer offered or supported.

## Where to start

- `docs/apps/app-suite.md` for the current app matrix
- `docs/apps/0000-app-template.md` for new app dossiers
- `docs/apps/0000-upstream-template.md` for candidate evaluations

## Relationship to RFCs and ADRs

- RFCs propose or explore platform rules and constraints.
- ADRs record decisions (including selecting an upstream project).
- App dossiers and candidate notes live here; link to RFCs/ADRs as needed.
