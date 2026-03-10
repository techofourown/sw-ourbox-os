# Install Defaults Tooling

This directory contains the tooling and shared helper code around the published
`install-defaults` artifact.

Published artifact:

- `ghcr.io/techofourown/sw-ourbox-os/install-defaults`

The data content of that artifact lives under `install-defaults/`. This
directory is the build, publish, validation, and shared resolver layer.

## Script roles

- `build.sh`
  - packages `install-defaults/` into `dist/install-defaults.tar.gz`
  - can apply curated `OS_DEFAULT_REF` overrides during the stable-promotion lane
- `publish.sh`
  - pushes the tarball to GHCR with OCI annotations
  - records the digest-pinned ref in `dist/install-defaults.ref`
- `validate-assignment-only.sh`
  - enforces that profile files remain assignment-only env data
- `installer-selection-resolver.sh`
  - upstream shared reference resolver for the installer-selection contract
- `test-installer-selection-resolver.sh`
  - upstream resolver smoke/tests

## Important boundary

`install-defaults` is a data artifact, not a code-delivery artifact.

That means:

- installers may fetch the published profile bundle at runtime
- installers must not fetch executable selection logic from the bundle
- the shared resolver is vendored by consumers as source code, not shipped as a
  remotely fetched executable payload

This is why the data artifact lives in `install-defaults/`, while the shared
resolver lives here in `tools/install-defaults/`.

## Outputs

Build output:

- `dist/install-defaults.tar.gz`
- `dist/install-defaults.meta.env`

Publish output:

- `dist/install-defaults.push.log`
- `dist/install-defaults.ref`

## Stable promotion nuance

`release/install-defaults-stable.env` can provide curated digest-pinned
`OS_DEFAULT_REF` overrides for the moving `install-defaults:stable` lane.

- if all overrides are empty, the stable lane re-tags an already-published
  versioned artifact by digest
- if any override is set, the stable lane rebuilds the bundle from the checked-out
  release tag with those curated default refs injected

## Entrypoints

From the repo root:

```bash
./tools/install-defaults/build.sh
TAG=edge ./tools/install-defaults/publish.sh edge
bash ./tools/install-defaults/validate-assignment-only.sh
bash ./tools/install-defaults/test-installer-selection-resolver.sh
```

## Related docs

- [install-defaults/README.md](../../install-defaults/README.md)
- [installer-selection-contract.md](../../docs/reference/installer-selection-contract.md)
- [ARTIFACT_PROVENANCE.md](../../docs/ARTIFACT_PROVENANCE.md)

JSON publish record output: `dist/install-defaults.publish-record.json` (canonical machine-readable publish surface).
