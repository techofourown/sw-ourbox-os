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
- `publish.sh`
  - pushes the tarball to GHCR with OCI annotations
  - records the digest-pinned ref in `dist/install-defaults.ref`
- `validate-assignment-only.sh`
  - enforces that profile files remain assignment-only env data
- `installer-selection-resolver.sh`
  - upstream shared reference resolver for the installer-selection and airgap-platform selection contracts
- `test-installer-selection-resolver.sh`
  - upstream resolver smoke/tests

## Important boundary

`install-defaults` is a data artifact, not a code-delivery artifact.

That means:

- installers may fetch the published profile bundle at runtime
- installers must not fetch executable selection logic from the bundle
- the shared resolver is consumed from source by installer tooling, not shipped
  as a remotely fetched executable payload

This is why the data artifact lives in `install-defaults/`, while the shared
resolver lives here in `tools/install-defaults/`.

## Stable seam in this area

The stable ownership split is:

- `install-defaults/`
  - authoritative published profile data
- `tools/install-defaults/installer-selection-resolver.sh`
  - authoritative shared code surface for both selection lanes
- target-specific `img-*` installer entrypoints
  - local UX, destructive confirmation flow, and payload install mechanics

This directory owns the upstream shared code side of that seam. The remote
artifact does not deliver executable browsing logic.

## Outputs

Build output:

- `dist/install-defaults.tar.gz`
- `dist/install-defaults.meta.env`

Publish output:
- `dist/install-defaults.publish-record.json` (canonical machine-readable publish record)

- `dist/install-defaults.push.log`
- `dist/install-defaults.ref`

## Stable promotion nuance

`install-defaults:stable` is a digest retag of the already-published release-tag
bundle. Stable promotion does not rebuild the artifact or inject curated pinned
default refs.

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
- [airgap-platform-selection-contract.md](../../docs/reference/airgap-platform-selection-contract.md)
- [downstream-consumer-surfaces.md](../../docs/reference/downstream-consumer-surfaces.md)
- [repository-layout-and-authority.md](../../docs/reference/repository-layout-and-authority.md)
- [ARTIFACT_PROVENANCE.md](../../docs/ARTIFACT_PROVENANCE.md)
