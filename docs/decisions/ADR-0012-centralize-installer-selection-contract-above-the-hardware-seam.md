# ADR-0012: Centralize the Installer Selection Contract Above the Hardware Seam

## Date
2026-03-07

## Update Note
As of 2026-03-17, Matchbox no longer vendors the shared selection resolver into
installer runtime media. Matchbox now consumes host-composed local mission media
from `sw-ourbox-installer`. The context section below records the pre-migration
state that motivated this ADR.

## Context

OurBox currently has multiple installer implementations that all decide which OS payload gets
installed:

- Matchbox fetches payloads at installer runtime and offers an interactive channel/catalog UI.
- Woodbox resolves payloads during preinstall and supports both registry and embedded-payload flows.
- Tinderbox is an offline Jetson-oriented flasher with Force Recovery, initrd diagnostics, and
  NVIDIA-specific mechanics.

Those targets are not supposed to share one monolithic installer. ADR-0011 explicitly allocates
installer UX, flashing transport, and hardware enablement to the target-specific `img-*` repos.

However, the selection policy above that hardware seam has already started to drift:

- Matchbox and Woodbox differed in default precedence and digest-resolution posture.
- Woodbox's remote install-defaults path no longer matched the artifact shape published by
  `sw-ourbox-os`.
- Catalog resolution behavior relied on row order rather than an explicit "newest by created"
  rule.
- Installed-system provenance for the selection path was richer on Woodbox than on Matchbox.

This is not just installer glue. It determines which exact bits get installed, whether the result
is immutable, and what operators can later inspect in `/etc/ourbox/release`.

We need one shared contract and one upstream reference implementation for this policy without
collapsing the hardware-specific installers into a single UI or transport.

## Decision

We will centralize the **installer selection contract** in `sw-ourbox-os` and provide a small
shell **reference resolver** there.

Concretely:

1. `sw-ourbox-os` owns the normative installer selection contract.
   - The contract defines shared precedence, install-defaults bundle shape, catalog-selection
     rules, digest-resolution rules, and provenance vocabulary.
   - The canonical reference document is
     `docs/reference/installer-selection-contract.md`.

2. `sw-ourbox-os` ships a small shell reference resolver.
   - The reference implementation lives at
     `tools/install-defaults/installer-selection-resolver.sh`.
   - It is intentionally limited to shared selection policy and helper behavior.

3. `install-defaults` remains a data artifact, not a code-delivery artifact.
   - We are not introducing a runtime-fetched executable OCI artifact for selection logic.
   - Selection code must not depend on fetching code before the payload choice is made.

4. `img-*` repositories keep all hardware-specific installer UX and install mechanics.
   - Local responsibilities include prompting, disk selection, destructive confirmations, payload
     staging, flashing transport, embedded/offline paths, NVIDIA flows, Subiquity integration, and
     other target-specific handoff logic.

5. Consumers should realize the same policy and provenance vocabulary.
   - Targets may vendor the upstream reference resolver into their installer image, call it from
     a host-side compose tool, or otherwise consume it in a target-appropriate way.
   - What matters is that the contract and behavior stay centralized above the hardware seam.

6. Tinderbox constrains the boundary but does not block the first migration.
   - Matchbox and Woodbox should migrate first because they already consume catalogs and
     install-defaults in adjacent ways.
   - Tinderbox may adopt the shared resolver later if and when it gains the same payload-selection
     lane; until then it remains explicitly outside that first migration.

## Rationale

1. It centralizes the policy that determines what exact bits get installed.
2. It stops drift without forcing one installer UX across incompatible hardware targets.
3. It aligns with the existing architecture where `sw-ourbox-os` owns install-defaults and common
   consumer expectations above the hardware seam.
4. It lets official installers keep baking pinned defaults while still making the fallback/control
   plane coherent and inspectable.
5. It creates a smaller, more durable seam for future targets like Tinderbox.

## Consequences

### Positive
- One normative place to define selection precedence and immutability rules.
- One upstream reference resolver to test and reason about.
- Cleaner installed-system provenance across targets.
- Safer catalog behavior because "newest by created" becomes explicit.
- Easier future adoption by additional targets without unifying unrelated installer mechanics.

### Negative
- Some consumers may still need to vendor or otherwise carry the upstream resolver, while others
  may instead centralize it in a host-side composer. Cross-repo coordination is still required.
- The docs surface grows: there is now an explicit installer-selection contract alongside the
  platform-contract and target-integration docs.
- Refactoring existing consumers requires short-term cross-repo coordination.

### Mitigation
- Keep the resolver small and policy-focused.
- Keep `install-defaults` data-only.
- Document clearly which parts stay local to each installer.
- Add lightweight resolver tests at the upstream source of truth.

## References
- ADR-0011: Separate Hardware Enablement from the Platform Contract
- `docs/reference/installer-selection-contract.md`
- `docs/reference/target-integration-contract.md`
- `docs/architecture/artifact-distribution-and-integration.md`
- `docs/architecture/official-image-production-and-consumption.md`
