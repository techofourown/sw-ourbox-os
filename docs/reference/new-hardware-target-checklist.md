# New Hardware Target Checklist

- Status: Draft
- Audience: maintainers proposing or reviewing a new `img-*` target
- Related:
  - `./target-integration-contract.md`
  - `../decisions/ADR-0011-separate-hardware-enablement-from-the-platform-contract.md`

## Purpose

Use this checklist whenever a new hardware target is proposed or when an existing target is being
substantially rethought.

The goal is not to force one substrate everywhere. The goal is to make the target's common seams
and intentional divergences explicit.

## 1. Target summary

- [ ] Target name, device family, and intended audience are named clearly.
- [ ] The proposal identifies the owning repository (existing `img-*` repo or new repo).
- [ ] The proposal states whether this is:
  - [ ] a general-purpose Linux target,
  - [ ] a vendor-BSP target,
  - [ ] an embedded direct-flash target,
  - [ ] or another class.

Suggested summary fields:
- `TARGET_ID`:
- Human name:
- Primary CPU architecture:
- GPU / accelerator expectations:
- Install style:
- Intended support tier:

## 2. Target substrate and hardware enablement

- [ ] The target substrate is named explicitly.
  - base distro or vendor BSP:
  - kernel line:
  - boot chain / firmware posture:
  - driver stack posture:
- [ ] The choice of substrate is justified in terms of supportability, not just familiarity.
- [ ] The proposal states which hardware constraints made this substrate the right choice.
- [ ] The proposal states what would have broken, become fragile, or become harder to support if a
      different substrate had been forced.

## 3. Platform contract consumption

- [ ] The target explains how it consumes the `sw-ourbox-os` platform contract.
- [ ] The proposal states whether the platform contract is:
  - [ ] vendored temporarily,
  - [ ] embedded at build time,
  - [ ] fetched at install time,
  - [ ] fetched at first boot,
  - [ ] or consumed another documented way.
- [ ] The source and revision are recorded.
- [ ] If OCI packaging is available, the consumer path can pin the contract by digest.
- [ ] If vendoring is used, the update procedure is documented.

## 4. Installed-system provenance

- [ ] The target records installed-system metadata in `/etc/ourbox/release` or a documented
      equivalent.
- [ ] Minimum fields are present:
  - [ ] `OURBOX_PRODUCT`
  - [ ] `OURBOX_TARGET`
  - [ ] `OURBOX_VERSION`
  - [ ] `OURBOX_PLATFORM_CONTRACT_SOURCE`
  - [ ] `OURBOX_PLATFORM_CONTRACT_REVISION`
- [ ] Additional payload / installer provenance fields are included where available.
- [ ] An operator can answer "what am I running?" locally on the target.

## 5. Persistent data contract

- [ ] The target defines a stable persistent data contract.
- [ ] The proposal states whether the canonical data root is `/data`.
- [ ] If the target does not use `/data`, the divergence is documented and justified.
- [ ] The proposal explains how persistent storage is provisioned:
  - [ ] auto-created,
  - [ ] installer-selected,
  - [ ] fixed partition layout,
  - [ ] operator-prepared,
  - [ ] or other documented mechanism.
- [ ] If multiple physical devices exist, OS-vs-data behavior is documented.

## 6. Bootstrap contract

- [ ] The bootstrap path from base host to applied/staged platform baseline is described.
- [ ] The proposal identifies what mechanism is used:
  - [ ] systemd,
  - [ ] installer hook,
  - [ ] cloud-init / autoinstall,
  - [ ] vendor-specific first-boot logic,
  - [ ] or another documented mechanism.
- [ ] The proposal explains how bootstrap success and failure are surfaced to operators.
- [ ] The target does not rely on undocumented magic steps.

## 7. Airgap and artifact posture

- [ ] The proposal states whether the target supports airgapped installation.
- [ ] If a platform airgap bundle is embedded, its location is documented.
- [ ] The OS payload / installer media / defaults / catalog story is documented at least at a
      public-model level.
- [ ] Artifact identity is preserved by digest, checksum, or another stable identifier as
      appropriate to the artifact type.

## 8. Status and observability

- [ ] The target exposes operator-visible status surfaces.
- [ ] The proposal explains where logs live.
- [ ] The proposal explains how an operator checks:
  - [ ] installed build identity,
  - [ ] platform contract provenance,
  - [ ] bootstrap status,
  - [ ] persistent data state.

## 9. Commonality vs divergence

Fill this out explicitly.

### Common seams satisfied unchanged
- [ ] platform contract consumption
- [ ] installed-system release metadata
- [ ] persistent data contract
- [ ] bootstrap contract
- [ ] airgap behavior (if applicable)
- [ ] status / observability surfaces
- [ ] artifact identity / install provenance

Notes:
- Which of the above match the standard pattern exactly?
- Which are adapted but still equivalent?

### Intentional divergences below the hardware seam
- [ ] base distro / vendor BSP
- [ ] kernel line
- [ ] boot chain / firmware
- [ ] GPU / accelerator stack
- [ ] partitioning / storage layout
- [ ] flashing / installer transport
- [ ] installer UX

For each divergence, answer:
- what diverges?
- why does it pay rent?
- what is the support implication?
- what common seam remains unchanged above it?

## 10. Support matrix and limits

- [ ] Supported models / SKUs are named explicitly.
- [ ] Unsupported variants are named explicitly.
- [ ] Required host-side tooling or flashing prerequisites are documented.
- [ ] The proposal avoids vague "maybe works" language for hardware support.

## 11. Conformance and validation plan

- [ ] There is a plan to validate platform baseline application on the target.
- [ ] There is a plan to validate persistent data behavior.
- [ ] There is a plan to validate installer / flashing repeatability.
- [ ] There is a plan to validate provenance recording.
- [ ] The target's support claims match the actual validation plan.

## 12. Required docs to create or update

For a new target, the following docs should normally exist:

- [ ] repo-local ADR for consuming the platform contract
- [ ] repo-local platform-contract provenance reference
- [ ] repo-local target contracts / host contracts doc
- [ ] install / flashing instructions
- [ ] support matrix / compatibility notes

Central docs that may need updating:
- [ ] `sw-ourbox-os` architecture or reference docs
- [ ] install-defaults or artifact-distribution docs
- [ ] glossary terms if new vocabulary was introduced

## 13. Decision checkpoint

Before green-lighting the target, reviewers should be able to answer:

- Is the target substrate justified?
- Are the common seams above the hardware boundary still intact?
- Are the divergences explicit and supportable?
- Is the documentation good enough that future maintainers will not have to rediscover the same
  boundary from scratch?
