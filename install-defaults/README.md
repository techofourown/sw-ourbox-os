# Install Defaults Profiles

These profiles are bundled into the `install-defaults` OCI artifact and consumed by installer
runtimes.

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

- `OS_REPO`
- `OS_CATALOG_TAG`
- `OS_DEFAULT_REF` (optional digest-pinned default)
- `CHANNEL_STABLE_TAG`, `CHANNEL_BETA_TAG`, `CHANNEL_NIGHTLY_TAG`, `CHANNEL_EXP_LABS_TAG`

Out of scope:

- any `OURBOX_INSTALLER_SSH_*` key
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

Channel tags must follow the same published target lanes:

- Matchbox: `rpi-stable`, `rpi-beta`, `rpi-nightly`, `rpi-exp-labs`
- Woodbox: `x86-stable`, `x86-beta`, `x86-nightly`, `x86-exp-labs`

Recommended pattern:

1. Use `OS_DEFAULT_REF` for the casual-user default when promoting a known-good stable artifact.
2. Keep `CHANNEL_STABLE_TAG` available as the human-readable stable lane.
3. Publish `beta` as the latest official mainline build from pinned inputs.
4. Reserve `nightly` for true integration previews built from floating upstream `edge` inputs.
5. Keep `exp-labs` available for explicit experimental/promoted artifacts.

CI publishing strategy:
- `install-defaults:edge` updates on `main`
- version tags can be published from release/tag events
- `install-defaults:stable` is promoted by `.github/workflows/install-defaults-promote.yml`
  after the successful `Install Defaults` release publish for the same published release tag
- `release/install-defaults-stable.env` carries the optional curated pinned
  `OS_DEFAULT_REF` values used for that promotion
- if every override in `release/install-defaults-stable.env` is empty, the
  workflow re-tags the already-published versioned bundle into `stable`
- if any override is non-empty, the workflow rebuilds `install-defaults:stable`
  from the checked-out release tag with those curated pinned defaults

Baked installer defaults and boot-media overrides remain fallback/override controls.

A baked non-empty `OS_DEFAULT_REF` remains authoritative unless the remote profile explicitly
replaces it with another non-empty `OS_DEFAULT_REF`.
