# ADR-0011: Separate Hardware Enablement from the Platform Contract

## Date
2026-03-02

## Context

OurBox OS is intended to run across multiple hardware targets, and those targets will not all look
alike. Some will be straightforward general-purpose Linux hosts. Others will require a vendor BSP,
a special kernel line, a target-specific flashing workflow, a constrained boot chain, or unusual
storage provisioning. NVIDIA-backed targets make this especially obvious, but the problem is broader
than NVIDIA.

We already have a strong architectural center of gravity in `sw-ourbox-os`:

- the deployed k3s baseline is treated as the platform integration contract for wiring concerns
  (ADR-0008),
- the platform contract is packaged and consumed as an OCI artifact by digest (ADR-0009),
- image repos (`img-*`) are the place where hardware-specific packaging, installers, and bootstrap
  behavior live.

What is still missing is an explicit decision about where commonality must be enforced, and where
divergence is legitimate.

Without that boundary, future architecture discussions are likely to drift into the wrong question:
"Should every target use the same base distro?" That is often the wrong layer to standardize. For
some targets, the most supportable answer will be a generic distro. For others, the most supportable
answer will be a hardware-native substrate such as a vendor BSP or appliance-oriented image base.

We need a stable cross-target rule that preserves portability of the platform while allowing the
target-specific integration repo to make practical hardware choices.

## Decision

We will standardize OurBox OS above the hardware seam and explicitly allow target-native divergence
below it.

Concretely:

1. `sw-ourbox-os` defines the platform contract.
   - This includes the deployed platform baseline, platform-level configuration expectations,
     artifact identity posture, and the common consumer expectations that all targets must satisfy.

2. `img-*` repositories own hardware enablement.
   - Each image repo is responsible for the target-specific substrate and install path needed to
     make that target viable.
   - This includes base distro or vendor BSP selection, kernel line, firmware, boot chain, driver
     stack, partitioning strategy, installer media, flashing transport, and related bring-up logic.

3. Uniform base OS is not a requirement.
   - OurBox OS does not require one universal base distro, kernel, flashing path, or vendor
     substrate across all targets.
   - A target MAY use a hardware-native substrate when that is the most supportable way to satisfy
     the common seams above the hardware boundary.

4. Commonality SHALL be enforced at named seams above the hardware boundary.
   - These seams are the stable cross-target contract and are defined in the target integration
     contract reference:
     - platform contract consumption and provenance,
     - installed-system release metadata,
     - persistent data contract,
     - bootstrap contract,
     - airgap packaging behavior when a platform bundle is embedded,
     - status, health, and observability surfaces,
     - artifact identity and installation provenance.

5. New targets must describe both commonality and divergence explicitly.
   - A new target proposal SHALL state:
     - which common seams are satisfied unchanged,
     - which target-specific choices are intentionally divergent,
     - why those divergences pay rent,
     - and how the target will be validated and supported.

6. Central terminology
   - In central `sw-ourbox-os` documentation, we will use the term **target integration contract**
     for the seam between the platform contract and a hardware-specific image repo.
   - Repo-local docs MAY still use "host contract" informally during transition, but central docs
     SHOULD prefer "target integration contract" to keep the boundary precise.

Put plainly:

> Commonality is defined by contracts above the hardware seam, not by forcing one base distro
> across all targets.

## Rationale

1. It preserves hardware realism without giving up platform coherence.
   Different targets really do have different substrate constraints. Pretending otherwise creates
   fragile portability theater.

2. It keeps the platform portable at the right layer.
   The parts that should stay stable across targets are the parts that affect how the deployed
   OurBox platform behaves, how it is inspected, and how it is supported.

3. It improves supportability.
   When a target diverges below the seam, that divergence is intentional, named, and bounded. We
   can support it without confusing it for a platform-level exception.

4. It reduces strategy churn.
   Future discussions about "should we support target X?" can focus on the seam:
   can the target satisfy the target integration contract, and what is the justified divergence?

5. It aligns with the existing producer/consumer model.
   `sw-ourbox-os` is already the upstream producer of the platform contract. `img-*` repos are
   already the consumers that package that contract for specific hardware. This ADR makes that
   boundary explicit and durable.

## Consequences

### Positive
- Clearer strategy discussions for future hardware targets.
- Less pressure to standardize at the wrong layer.
- Cleaner support boundary between platform definition and hardware enablement.
- Better fit for targets that genuinely need vendor-native kernels, drivers, or flashing tools.
- More legible consumer expectations for `img-*` maintainers.

### Negative
- Some readers may initially prefer the simplicity of "one distro everywhere."
- The target integration contract now needs to be documented and kept current.
- Image repos will need discipline to document target-specific divergence instead of letting it
  accumulate implicitly.

### Mitigation
- Keep the cross-target seams small, explicit, and inspectable.
- Provide a reference contract and a new-target checklist so target discussions stay concrete.
- Require image repos to record platform provenance and target-specific decisions in versioned docs.

## References
- ADR-0008: Deployment Baseline as the Platform Integration Contract
- ADR-0009: Package the OurBox OS Platform Contract as an OCI Artifact
- `docs/reference/target-integration-contract.md`
- `docs/reference/new-hardware-target-checklist.md`
- `docs/architecture/artifact-distribution-and-integration.md`
- `docs/architecture/official-image-production-and-consumption.md`
