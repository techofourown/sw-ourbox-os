# Installer Selection Contract

- Status: Draft
- Audience: `sw-ourbox-os` maintainers, `img-*` maintainers, downstream builders
- Related:
  - `../decisions/ADR-0012-centralize-installer-selection-contract-above-the-hardware-seam.md`
  - `../decisions/ADR-0013-centralize-installer-ssh-contract-above-the-hardware-seam.md`
  - `../decisions/ADR-0011-separate-hardware-enablement-from-the-platform-contract.md`
  - `../architecture/official-image-production-and-consumption.md`
  - `../reference/target-integration-contract.md`
  - `../reference/installer-ssh-contract.md`

## 1. Purpose

This document defines the shared policy for choosing an installable OS payload before target-
specific installer UX and flashing logic take over.

It exists because:

- the choice of payload determines which exact bits get installed,
- that choice must be immutable and inspectable when possible,
- the policy should be the same across compatible installers even when their hardware flows differ.

This is the contract above the hardware seam for:

- install-defaults overlay behavior,
- default-selection precedence,
- catalog resolution,
- digest resolution,
- and installed-system provenance vocabulary.

## 2. Non-goals

This contract does **not** standardize:

- installer UI or prompting flow,
- disk discovery or destructive-action confirmation,
- embedded/offline payload staging,
- Subiquity/cloud-init integration,
- Raspberry Pi image flashing,
- NVIDIA Force Recovery or initrd flash flows,
- target-specific payload file formats.

Those remain target-specific below the hardware seam.

## 3. Upstream Reference Implementation

The upstream shell reference resolver lives at:

- `tools/install-defaults/installer-selection-resolver.sh`

Targets may vendor or otherwise carry that file into installer media, but the normative behavior is
defined here and owned by `sw-ourbox-os`.

## 4. Inputs

The shared selection contract is defined in terms of the following inputs:

- `INSTALLER_ID`
- `OS_REPO`
- `OS_TARGET`
- `OS_CHANNEL`
- `OS_REF` (optional exact ref override)
- `OS_DEFAULT_REF` (optional pinned default)
- `OS_CATALOG_ENABLED`
- `OS_CATALOG_TAG`
- `INSTALL_DEFAULTS_REF` (optional remote install-defaults bundle)
- `CHANNEL_STABLE_TAG`
- `CHANNEL_BETA_TAG`
- `CHANNEL_NIGHTLY_TAG`
- `CHANNEL_EXP_LABS_TAG`
- `OURBOX_ALLOW_UNRESOLVED_PULL` (dev/test escape hatch only)

Targets may have additional local inputs for hardware-specific behavior, but those are outside this
shared contract.

## 5. Install-defaults Artifact Shape

The remote install-defaults bundle is an OCI artifact whose payload shape is:

- `dist/install-defaults.tar.gz`

That tarball expands to:

- `install-defaults/schema.env`
- `install-defaults/manifest.env`
- `install-defaults/defaults/<installer-id>.env`

Consumers must treat this as the authoritative upstream shape.

### Remote overlay rule

If a remote profile is fetched successfully:

1. baked defaults are loaded first,
2. the matching remote profile overlays those baked defaults,
3. local operator overrides are applied last.

### Pinned baked default preservation rule

If baked defaults already carry a non-empty `OS_DEFAULT_REF`, that baked pinned ref remains
authoritative unless the remote profile explicitly replaces it with another non-empty
`OS_DEFAULT_REF`.

This preserves deterministic official-installer behavior while still allowing remote defaults to
override other selection controls.

## 6. Selection Precedence

Shared precedence is:

1. `OS_REF`
2. `OS_DEFAULT_REF`
3. newest valid catalog row for `OS_CHANNEL`
4. channel-tag fallback using `CHANNEL_*_TAG`

This contract defines the default selection path. Hardware-specific operator prompts may still allow
the user to choose a different exact ref, but those overrides must be recorded distinctly in
provenance.

## 7. Catalog Resolution Rules

Catalog resolution must be explicit and row-order independent.

Rules:

1. filter rows by the selected `channel`,
2. require a valid digest-pinned `pinned_ref`,
3. choose the newest matching row by explicit `created` timestamp,
4. if no valid matching row exists, fall back to the configured channel tag.

Append order is not the contract.

Expected minimum columns used by the resolver:

- `channel`
- `tag`
- `created`
- `version`
- `platform_contract_digest`
- `pinned_ref`

Additional catalog columns are allowed.

## 8. Digest Resolution Rules

If the selected ref is already digest-pinned, it is used directly.

If the selected ref is floating:

1. resolve it to an immutable digest with `oras resolve`,
2. pull by digest,
3. preserve the original ref separately for operator-facing provenance.

If `oras resolve` fails:

- default behavior is **fail closed**
- `OURBOX_ALLOW_UNRESOLVED_PULL=1` is the only allowed escape hatch, and it is for development or
  testing only
- when that escape hatch is used, provenance must explicitly record
  `OURBOX_OS_ARTIFACT_DIGEST=unresolved`

## 9. Standard Provenance Vocabulary

Installed systems should use the following shared selection/provenance fields:

- `OURBOX_INSTALLER_ID`
- `OURBOX_INSTALLER_VERSION`
- `OURBOX_INSTALLER_GIT_HASH`
- `OURBOX_OS_ARTIFACT_SOURCE`
- `OURBOX_OS_ARTIFACT_REF`
- `OURBOX_OS_ARTIFACT_DIGEST`
- `OURBOX_OS_IMAGE_SHA256` (for file-shaped payloads)
- `OURBOX_INSTALL_DEFAULTS_SOURCE`
- `OURBOX_INSTALL_DEFAULTS_REF`
- `OURBOX_INSTALL_SELECTION_SOURCE`
- `OURBOX_RELEASE_CHANNEL`

Shared value expectations:

- `OURBOX_OS_ARTIFACT_SOURCE`
  - `registry`
  - `embedded`
- `OURBOX_INSTALL_DEFAULTS_SOURCE`
  - `baked`
  - `remote`
- `OURBOX_INSTALL_SELECTION_SOURCE`
  - `os-ref`
  - `os-default-ref`
  - `catalog`
  - `channel-tag`
  - `operator-override`
  - `embedded`

`OURBOX_RELEASE_CHANNEL` should be populated only when channel semantics actually participated in
selection, typically for `catalog` or `channel-tag`.

## 10. Local Responsibilities That Stay Out Of Scope

Targets remain free to differ in:

- how they present the selection to the operator,
- when they offer destructive confirmations,
- how they copy or pull the payload bits,
- how they validate payload file shape,
- how they flash or install the payload,
- how they hand off to first boot.

This is deliberate. The contract exists so that those local flows still produce comparable artifact
selection behavior and provenance.

## 11. Current Adoption Boundary

Matchbox and Woodbox are expected to realize this shared contract directly.

Tinderbox is not yet required to consume the shared resolver because its current flow is still a
host-side Jetson flasher rather than a catalog-driven installer. Tinderbox should document that
boundary explicitly and can adopt this contract later if it grows the same payload-selection lane.
