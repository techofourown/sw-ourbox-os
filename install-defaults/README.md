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

Each profile must keep `OS_CATALOG_TAG` aligned with the actually published catalog lane for that
target. Current official examples:

- Matchbox: `rpi-catalog`
- Woodbox: `x86-catalog`

Channel tags must follow the same published target lanes:

- Matchbox: `rpi-stable`, `rpi-beta`, `rpi-nightly`, `rpi-exp-labs`
- Woodbox: `x86-stable`, `x86-beta`, `x86-nightly`, `x86-exp-labs`

Recommended pattern:

1. Keep `OS_DEFAULT_REF` empty while validating new payloads.
2. When promoting a known-good build, set `OS_DEFAULT_REF` to a digest-pinned ref.
3. Keep channel tags available for interactive installer choices.

CI publishing strategy:
- `install-defaults:edge` updates on `main`
- version tags can be published from release/tag events
- `install-defaults:stable` is intended to be curated via the `Install Defaults Promote` workflow

Baked installer defaults and boot-media overrides remain fallback/override controls.

A baked non-empty `OS_DEFAULT_REF` remains authoritative unless the remote profile explicitly
replaces it with another non-empty `OS_DEFAULT_REF`.
