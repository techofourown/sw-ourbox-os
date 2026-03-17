# OurBox OS Target Integration Contract

- Status: Draft
- Audience: `sw-ourbox-os` maintainers, `img-*` maintainers, downstream builders
- Related:
  - `../decisions/ADR-0011-separate-hardware-enablement-from-the-platform-contract.md`
  - `../decisions/ADR-0008-deployment-baseline-as-the-platform-integration-contract.md`
  - `../decisions/ADR-0009-package-the-platform-contract-as-an-oci-artifact.md`
  - `../decisions/ADR-0013-centralize-installer-ssh-contract-above-the-hardware-seam.md`
  - `../architecture/artifact-distribution-and-integration.md`
  - `../architecture/official-image-production-and-consumption.md`

## 1. Purpose

This document defines the stable seam between the upstream OurBox platform definition and a
hardware-specific image repository.

In short:

- `sw-ourbox-os` defines the platform contract,
- `img-*` repositories own hardware enablement,
- this document defines what a target-specific image must expose so the platform remains legible,
  supportable, and comparable across targets.

This is the common contract above the hardware seam. It is not a requirement that every target use
the same base distro, kernel, flashing tool, or vendor substrate.

## 2. Scope

This document is concerned with target integration surfaces such as:

- platform contract consumption,
- installed-system provenance,
- persistent data expectations,
- bootstrap phases,
- airgap packaging behavior,
- operator-visible status and health surfaces,
- access-mode realization and routing posture.

It does not define:

- which distro a target must use,
- which kernel or boot chain a target must use,
- which flashing or installer mechanism a target must use,
- target-specific support matrices or hardware quirks.

Those belong in the relevant `img-*` repository.

## 3. Definitions

**Hardware seam**  
The conceptual boundary between the target-specific substrate and the standardized OurBox platform
behavior that sits above it.

**Target substrate**  
The base operating foundation for a hardware target, including base distro or vendor BSP, kernel,
firmware, boot chain, and driver stack.

**Hardware enablement**  
The target-specific work required to make a hardware target viable, including install mechanics,
flashing, storage provisioning, firmware/driver integration, and related bring-up.

**Target integration contract**  
The stable set of consumer-facing expectations a target-specific image repo must satisfy so the
OurBox platform can be consumed consistently above the hardware seam.

**Platform contract**  
The versioned deployed OurBox platform baseline, produced by `sw-ourbox-os`, that is consumed by
image repos and is identifiable by source, revision, and eventually OCI digest.

## 4. Principle

Target-specific divergence is allowed below the hardware seam. Commonality is required above it.

That means:

- base OS, kernel, vendor BSP, boot chain, flashing path, and installer mechanics MAY differ,
- platform provenance, installed-system identity, persistent-data expectations, bootstrap outcomes,
  and operator-visible inspection surfaces SHOULD remain stable enough that all targets can be
  reasoned about with the same mental model.

## 5. Required common seams

The following seams define the minimum cross-target contract.

### 5.1 Platform contract consumption

Every target integration repo MUST make platform contract consumption explicit.

Minimum expectations:
- the source of the consumed platform contract MUST be legible,
- the consumed revision MUST be legible,
- when OCI packaging is used, the contract SHOULD be pinnable by digest,
- if a target temporarily vendors a platform snapshot instead of consuming an OCI artifact, that
  vendored content MUST still be traceable to an upstream `sw-ourbox-os` revision.

Acceptable implementation shapes:
- build-time embed,
- host-composed staged mission media,
- staged airgap bundle,
- another target-appropriate mechanism.

The mechanism may differ. The provenance may not be ambiguous.

### 5.2 Installed-system release metadata

The installed system SHOULD expose a stable local record of what it is running.

Recommended location:
- `/etc/ourbox/release`

If a target uses another location, the repo MUST document that choice and why it diverges.

Minimum required metadata fields:
- `OURBOX_PRODUCT`
- `OURBOX_TARGET`
- `OURBOX_VERSION`
- `OURBOX_PLATFORM_CONTRACT_SOURCE`
- `OURBOX_PLATFORM_CONTRACT_REVISION`

Recommended additional fields:
- `OURBOX_DEVICE`
- `OURBOX_SKU`
- `OURBOX_VARIANT`
- `OURBOX_PLATFORM_CONTRACT_VERSION`
- `OURBOX_PLATFORM_CONTRACT_DIGEST`
- `OURBOX_OS_ARTIFACT_SOURCE` or `OURBOX_OS_REPO`
- `OURBOX_OS_ARTIFACT_REF`
- `OURBOX_OS_ARTIFACT_DIGEST`
- `OURBOX_OS_IMAGE_SHA256` (for file-shaped payloads)
- `OURBOX_INSTALLER_ID`
- `OURBOX_INSTALLER_VERSION`
- `OURBOX_INSTALLER_GIT_HASH`
- `OURBOX_INSTALL_DEFAULTS_SOURCE`
- `OURBOX_INSTALL_DEFAULTS_REF`
- `OURBOX_INSTALL_SELECTION_SOURCE`
- `OURBOX_RELEASE_CHANNEL`
- `OURBOX_BUILD_TS`

The goal is that an operator can answer:
- what am I running,
- where did it come from,
- what exact platform contract did it correspond to?

### 5.3 Persistent data contract

A full-platform target MUST provide at least one stable persistent storage root for platform state
and application data.

Canonical default:
- `/data`

Expectations:
- the repo MUST document how persistent storage is provisioned,
- the repo MUST document whether the storage root is auto-created, operator-selected, or externally
  prepared,
- if a target does not use `/data`, the divergence MUST be explicit and justified,
- if multiple physical storage devices exist, the repo MUST document which contract exists for
  system vs data storage.

This contract is intentionally about the stable outcome, not about the exact partitioning strategy.

### 5.4 Bootstrap contract

Every full-platform target SHOULD provide a deterministic bootstrap path from "base host is up" to
"OurBox platform baseline is applied or staged."

The exact tooling may differ, but the phases SHOULD be legible:

1. target substrate boots successfully,
2. persistent storage contract is satisfied,
3. platform contract is available (embedded or fetchable),
4. platform bootstrap applies or stages the platform baseline,
5. success or failure is recorded in operator-visible surfaces.

Repos MAY implement this with systemd, first-boot jobs, installer hooks, cloud-init, vendor
mechanisms, or other target-appropriate tools.

### 5.5 Installer diagnostics access (SSH)

If a target exposes installer-time SSH for diagnostics or support, it SHOULD realize the shared
installer SSH contract defined in `docs/reference/installer-ssh-contract.md`.

The common seam above the hardware boundary is:

- shared installer SSH policy vocabulary,
- mode/user/root normalization,
- auth-path validation,
- and deterministic `sshd_config.d` rendering semantics.

Targets remain free to differ in:

- when installer SSH policy is applied,
- how local password generation or disclosure works,
- how host keys are managed,
- how `sshd` is validated or restarted,
- how readiness is checked,
- and how status, monitor, or support UX surfaces are published.

That lifecycle and UX behavior remains target-local below the hardware seam.

### 5.6 Airgap platform bundle behavior

If a target embeds the platform contract or a platform airgap bundle into the installed image, the
bundle location SHOULD be stable and documented.

Recommended location:
- `/opt/ourbox/airgap/platform/`

If the target does not embed such a bundle, the repo MUST document:
- how the host or compose path stages that contract or bundle before the target
  boots,
- and where the target expects to find those staged local bytes.

### 5.7 Status, health, and observability surfaces

The target SHOULD provide enough operator-visible surfaces to answer basic health questions without
source-diving.

At minimum, an operator should be able to determine:
- what target build is installed,
- what platform contract revision or digest it corresponds to,
- whether bootstrap succeeded,
- where relevant logs or status outputs live.

Common implementation patterns may include:
- systemd units,
- journald logs,
- a target-specific status command,
- release metadata under `/etc/ourbox/release`.

Exact commands may differ by target, but the inspection story should not be mysterious.

### 5.8 Artifact identity and installation provenance

A target SHOULD preserve the link between:
- installer profile,
- selected OS payload,
- selected channel or pinned artifact ref,
- installed system metadata.

This does not require every target to use identical installation transport. It does require that the
result be legible and reproducible.

When a target installs OS payloads through install-defaults/catalog logic, it SHOULD realize the
shared installer-selection contract defined in
`docs/reference/installer-selection-contract.md`. The hardware target may keep its own local
prompts, flashing transport, and payload-shape verification, but the selection policy above that
boundary should remain comparable across targets.

When a target exposes installer SSH, it SHOULD realize the shared installer SSH contract defined in
`docs/reference/installer-ssh-contract.md`, while keeping lifecycle, disclosure, and support UX
local to the target implementation.


### 5.9 Access-mode realization

Every target integration repo MUST document how access modes are realized above the hardware seam.

Minimum expectations:
- local-only mode support and host grammar (`<tenant_id>.local`) are documented,
- local-only mode HTTP-only posture is documented,
- local landing host behavior (`ourbox.local`) is documented when exposed,
- public custom-domain mode support and host grammar (`<tenant_id>.<box-host>`) are documented,
- operator prerequisites for public mode (DNS/routing/TLS) are documented,
- any unsupported combinations or target-specific limitations are explicit.

## 6. Intentionally divergent surfaces

The following are expected areas of target-specific divergence and are not, by themselves, contract
violations.

| Surface | Divergence allowed? | Notes |
| --- | --- | --- |
| Base distro or vendor BSP | Yes | Choose the most supportable substrate for the target. |
| Kernel line | Yes | HWE, vendor kernels, or target-specific kernels may be justified. |
| Boot chain / firmware | Yes | Secure boot, QSPI, EEPROM, bootloader, and vendor requirements may differ. |
| GPU or accelerator stack | Yes | NVIDIA and other target-specific driver/runtime stacks may require repo-local handling. |
| Partitioning / storage layout | Yes | The stable outcome matters more than identical partition tables. |
| Flashing or installer transport | Yes | SD, USB, direct host flashing, recovery mode, network install, or airgap staging may all be valid. |
| Installer UX | Yes | Interactive installer, host-side flasher, or prebuilt image writing can all fit. |

Divergence is acceptable when it is:
- explicit,
- justified,
- documented,
- and does not break the common seams above the hardware boundary.

## 7. Recommended repo-local documentation pattern

Each `img-*` repository SHOULD eventually carry a small, repeatable documentation pattern:

1. A repo-local ADR that says the image repo consumes the platform contract from `sw-ourbox-os`.
2. A repo-local reference doc describing platform-contract provenance and update procedure.
3. A repo-local contracts doc describing the target-specific realization of this target integration
   contract.

This keeps the central model clean while still making each target's implementation legible.

## 8. Conformance questions

A target-specific repo should be able to answer all of the following:

- What substrate does this target use, and why?
- How does it consume the platform contract?
- Where does it record installed-system provenance?
- What is the persistent data contract?
- How does bootstrap happen?
- How does an operator inspect health and status?
- What is intentionally divergent, and why?

The companion checklist in `new-hardware-target-checklist.md` is intended to make those questions
routine rather than ad hoc.

## 9. Summary

The target integration contract exists so that:
- target-specific repos can make practical hardware choices,
- the platform stays coherent above the hardware seam,
- and future target discussions stay grounded in named seams rather than vague instincts.
