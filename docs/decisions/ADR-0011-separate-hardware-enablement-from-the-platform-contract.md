# ADR-0011: Separate Hardware Enablement from the Platform Contract

## Date
2026-02-20

## Decision
Common seams above the hardware boundary include access-mode realization:
- local-only HTTP mode,
- public custom-domain HTTPS mode,
- operator-visible prerequisites and limitations for each mode.

New target proposals SHALL state:
- support for local-only mode,
- support for public custom-domain mode,
- justified limitations in either mode,
- supportability impact of those limitations.

Access-mode behavior is part of the platform contract, not target-local ad hoc behavior.
