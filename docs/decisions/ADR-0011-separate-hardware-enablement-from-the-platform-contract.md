# ADR-0011: Separate Hardware Enablement from the Platform Contract

## Date
2026-01-25

## Decision
Commonality above the hardware seam includes access-mode realization:
- local-only HTTP mode,
- public custom-domain HTTPS mode,
- operator-visible prerequisites and limitations for each mode.

New target proposals SHALL state:
- whether local-only mode is supported,
- whether public custom-domain mode is supported,
- justified limitations in either mode,
- supportability impact of those limitations.

## Consequences
Access-mode behavior is part of the shared platform contract above the hardware seam, not a target-local ad hoc choice.

## References
- ADR-0014
