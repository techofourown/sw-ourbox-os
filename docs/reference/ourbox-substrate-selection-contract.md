# OurBox Substrate Selection Contract

- Status: Draft
- Audience: `sw-ourbox-os` maintainers, `img-*` maintainers, downstream builders
- Related:
  - `../reference/installer-selection-contract.md`
  - `../reference/target-integration-contract.md`
  - `../architecture/official-image-production-and-consumption.md`
  - `../reference/artifact-publish-record-contract.md`

## 1. Purpose

This document defines the shared policy for choosing an `ourbox-substrate` bundle
after the OS payload has already been selected.

It exists because:

- the selected OS payload already carries one baked substrate bundle,
- operators may want to browse newer or different substrate bundles,
- and installed systems need a consistent provenance vocabulary describing which
  bundle actually won.

This is the shared contract above the hardware seam for:

- baked-versus-remote bundle selection,
- substrate catalog resolution,
- digest resolution,
- bundle-source determination,
- and installed-system substrate provenance.

## 2. Non-goals

This contract does **not** standardize:

- OS payload selection,
- installer UI framing or confirmation wording,
- exact runtime cache paths,
- exact file-copy mechanics for the mutable bundle subset,
- target-specific overlay timing,
- host-side flashing workflows such as current Tinderbox provisioning.

Those remain target-specific below the hardware seam.

## 3. Upstream Reference Implementation

The shared shell reference resolver lives at:

- `tools/install-defaults/installer-selection-resolver.sh`

It owns both:

- the existing OS payload selection lane,
- and the ourbox-substrate selection lane added by this contract.

Host-side installer tooling may source that file directly. If a downstream
consumer still carries a copy, the normative behavior is defined here and owned
by `sw-ourbox-os`.

## 4. Inputs

The shared substrate selection lane uses the following installer control fields:

- `OURBOX_SUBSTRATE_REPO`
- `OURBOX_SUBSTRATE_ARCH`
- `OURBOX_SUBSTRATE_CHANNEL`
- `OURBOX_SUBSTRATE_REF` (optional exact ref override)
- `OURBOX_SUBSTRATE_CATALOG_ENABLED`
- `OURBOX_SUBSTRATE_CATALOG_TAG`

The following are local-only installer inputs and MUST NOT appear in the
published `install-defaults` artifact:

- `OURBOX_SUBSTRATE_REGISTRY_USERNAME`
- `OURBOX_SUBSTRATE_REGISTRY_PASSWORD`

## 5. OurBox Substrate Artifact Shape

The selected substrate bundle is an OCI artifact whose payload shape is:

- `dist/ourbox-substrate.tar.gz`

That tarball expands to:

- `k3s/`
- `platform/`
- `manifest.env`

Consumers must treat this as the authoritative upstream shape.

`manifest.env` is required and must be self-describing. It must carry at least:

- `OURBOX_SUBSTRATE_SOURCE`
- `OURBOX_SUBSTRATE_REVISION`
- `OURBOX_SUBSTRATE_VERSION`
- `OURBOX_SUBSTRATE_CREATED`
- `OURBOX_PLATFORM_CONTRACT_REF`
- `OURBOX_SUBSTRATE_ARCH`
- `K3S_VERSION`
- `OURBOX_PLATFORM_PROFILE`
- `OURBOX_PLATFORM_IMAGES_LOCK_PATH`
- `OURBOX_PLATFORM_IMAGES_LOCK_SHA256`

## 6. Catalog Shape

Catalogs are published in the same OCI repo as the bundle:

- `ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate:catalog-arm64`
- `ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate:catalog-amd64`

The TSV schema for both arch catalogs is:

```tsv
channel	tag	created	version	revision	arch	platform_profile	k3s_version	platform_images_lock_sha256	artifact_digest	pinned_ref
```

Rules:

- `channel` uses only `stable`, `beta`, `nightly`, `exp-labs`
- `arch` is `arm64` or `amd64`
- `pinned_ref` must be digest-pinned
- resolver picks the newest matching row by explicit `created`

Append order is not the contract.

## 7. Selection Precedence

Shared precedence is:

1. `OURBOX_SUBSTRATE_REF`
2. newest valid catalog row for `OURBOX_SUBSTRATE_CHANNEL`

## 8. Digest Resolution Rules

If the selected ref is already digest-pinned, it is used directly.

If the selected ref is floating:

1. resolve it to an immutable digest with `oras resolve`,
2. pull by digest,
3. preserve the original ref separately for operator-facing provenance.

If `oras resolve` fails:

- default behavior is **fail closed**
- `OURBOX_ALLOW_UNRESOLVED_PULL=1` is the only allowed escape hatch, and it is
  for development or testing only
- when that escape hatch is used, provenance must explicitly record
  `OURBOX_SUBSTRATE_DIGEST=unresolved`

## 9. Bundle-Source Rule

Installers should compare the selected substrate ref with the baked substrate bundle
already described by the selected OS payload metadata.

If the selected ref equals the baked bundle ref:

- the final bundle source is `baked`
- no remote bundle pull is needed

If the selected ref differs:

- the installer may pull the selected bundle from the registry
- the extracted bundle must pass arch validation before use
- the final bundle source is `registry`

In either case, the installed-system provenance must record the final selected
bundle and the actual selection source.

## 10. Standard Provenance Vocabulary

Installed systems should write the following fields to `/etc/ourbox/release`:

- `OURBOX_SUBSTRATE_SOURCE`
- `OURBOX_SUBSTRATE_REVISION`
- `OURBOX_SUBSTRATE_VERSION`
- `OURBOX_SUBSTRATE_CREATED`
- `OURBOX_SUBSTRATE_ARCH`
- `OURBOX_SUBSTRATE_PROFILE`
- `OURBOX_SUBSTRATE_K3S_VERSION`
- `OURBOX_SUBSTRATE_IMAGES_LOCK_SHA256`
- `OURBOX_SUBSTRATE_ARTIFACT_SOURCE`
- `OURBOX_SUBSTRATE_REF`
- `OURBOX_SUBSTRATE_DIGEST`
- `OURBOX_SUBSTRATE_SELECTION_SOURCE`
- `OURBOX_SUBSTRATE_RELEASE_CHANNEL`

Shared value expectations:

- `OURBOX_SUBSTRATE_ARTIFACT_SOURCE`
  - `baked`
  - `registry`
- `OURBOX_SUBSTRATE_SELECTION_SOURCE`
  - `ourbox-substrate-ref`
  - `catalog`
  - `operator-override`

`OURBOX_SUBSTRATE_RELEASE_CHANNEL` should be populated only when channel
semantics actually participated in selection, typically for `catalog`.

## 11. Current Adoption Boundary

Woodbox and legacy direct-selection consumers may realize this shared contract
directly.

Matchbox no longer carries the shared substrate-selection lane inside installer
runtime media. Matchbox now consumes host-composed local mission media from
`sw-ourbox-installer`, so the application bundle has already been selected and
staged before the target boots.

Tinderbox is intentionally outside the first runtime browser rollout because its
current flow is still a host-side Jetson flasher rather than a catalog-driven
payload installer. Tinderbox should reserve the same control and provenance
vocabulary now, and can adopt the shared runtime lane later.
