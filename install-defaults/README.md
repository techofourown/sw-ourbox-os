# Install Defaults Profiles

These profiles are bundled into the `install-defaults` OCI artifact and consumed by installer
selection/composition tooling.

This directory owns published profile data only. It does not own executable browsing logic; that
shared code surface lives in `tools/install-defaults/installer-selection-resolver.sh`.

The shared installer-selection contract for consuming these profiles is defined in:

- `docs/reference/installer-selection-contract.md`

The upstream shell reference resolver that implements that contract lives at:

- `tools/install-defaults/installer-selection-resolver.sh`

Artifact shape:

- OCI pull output contains `dist/install-defaults.tar.gz`
- the tarball expands to:
  - `install-defaults/schema.env`
  - `install-defaults/manifest.env`
  - `install-defaults/defaults/<installer-id>.env`

Each `defaults/<installer-id>.env` file can define:

- `INSTALLER_ID`
- `OS_REPO`
- `OS_CATALOG_TAG`
- `APPLICATION_CATALOG_DEFAULT_IDS` (optional comma-separated official catalog ids)
- `AIRGAP_PLATFORM_REPO`
- `AIRGAP_PLATFORM_ARCH`
- `AIRGAP_PLATFORM_CHANNEL`
- `AIRGAP_PLATFORM_CATALOG_ENABLED`
- `AIRGAP_PLATFORM_CATALOG_TAG`

Out of scope:

- `OS_REF`
- `AIRGAP_PLATFORM_REF`
- any `OURBOX_INSTALLER_SSH_*` key
- `AIRGAP_PLATFORM_REGISTRY_USERNAME`
- `AIRGAP_PLATFORM_REGISTRY_PASSWORD`
- SSH auth material
- installer access policy

`install-defaults` must not carry installer SSH behavior or auth inputs. Installer SSH is governed
by the separate installer SSH contract and vendored helper, not by a remote profile artifact.

Profile files are intentionally data-only. They must remain simple assignment-only
`KEY=VALUE` content with comments/blank lines only; shell constructs are not allowed.

Each profile must keep `OS_CATALOG_TAG` aligned with the actually published catalog lane for that
target. Current official examples:

- Matchbox: `rpi-catalog`
- Woodbox: `x86-catalog`

Each profile must also keep `AIRGAP_PLATFORM_CATALOG_TAG` aligned with the published airgap
catalog lane for that installer architecture:

- Matchbox: `catalog-arm64`
- Woodbox: `catalog-amd64`

Catalog rows store the short release channel names in the `channel` column:

- `stable`
- `beta`
- `nightly`
- `exp-labs`

Consumers should continue accepting legacy target-qualified catalog rows (for example
`rpi-stable` or `x86-beta`) during the transition, but official publishers now emit only the short
channel names above.
That compatibility rule does not widen the canonical provenance vocabulary: if a consumer reads a
legacy row such as `rpi-stable`, it should still record `OURBOX_RELEASE_CHANNEL=stable`.

Recommended pattern:

1. Publish digest-pinned catalog rows for each supported release lane.
2. Keep `OS_CATALOG_TAG` aligned with the official lane-specific catalog for that target.
3. Keep `AIRGAP_PLATFORM_CATALOG_TAG` aligned with the official lane-specific catalog for that installer architecture.
4. Let consumers resolve the newest contract-compatible pinned ref from those catalogs.
5. Fail closed when the required upstream catalog data is missing or incompatible.

CI publishing strategy:
- `install-defaults:edge` updates on `main`
- version tags can be published from release/tag events
- `install-defaults:stable` is promoted by `.github/workflows/install-defaults-promote.yml`
  after the successful `Install Defaults` release publish for the same published release tag
- stable promotion is a digest retag of the already-published versioned bundle
- the install-defaults artifact does not inject curated pinned default refs during promotion
