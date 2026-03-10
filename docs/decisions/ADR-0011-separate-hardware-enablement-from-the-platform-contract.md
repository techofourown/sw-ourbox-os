# ADR-0011: Separate hardware enablement from the platform contract

## Decision
4. Commonality SHALL be enforced at named seams above the hardware boundary, including access-mode realization:
   - local-only HTTP mode,
   - public custom-domain HTTPS mode,
   - operator-visible prerequisites and limitations for each.

5. New target proposals SHALL state:
   - whether local-only mode is supported,
   - whether public custom-domain mode is supported,
   - justified limitations in either mode,
   - supportability impact of those limitations.

## Consequences
Access-mode behavior is part of the platform contract above the hardware seam, not a target-local ad hoc choice.
