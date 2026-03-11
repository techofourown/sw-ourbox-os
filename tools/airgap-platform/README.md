# Airgap Platform Build And Publish

This directory contains the build and publish entrypoints for the `airgap-platform`
artifact published from `sw-ourbox-os`.

Published artifact:

- `ghcr.io/techofourown/sw-ourbox-os/airgap-platform`

Published lanes:

- `beta-arm64`
- `beta-amd64`
- `nightly-arm64`
- `nightly-amd64`
- `stable-arm64`
- `stable-amd64`
- `exp-labs-arm64`
- `exp-labs-amd64`
- `v*-arm64`
- `v*-amd64`

## What this artifact is

`airgap-platform` is the offline platform bundle consumed by downstream image repos.
It packages:

- the `k3s` binary for one target architecture
- the matching upstream k3s airgap image tar
- the platform app images listed in the rendered `images.lock.json`
- the current upstream `demo-apps` profile inputs used to build the bundle

The artifact is architecture-specific, but the source code is not split by
architecture. `arm64` and `amd64` both use the same scripts here with a different
`ARCH` value.

Official publication is also bound to the exact published platform-contract
artifact identity via:

- `OURBOX_PLATFORM_CONTRACT_REF`
- `OURBOX_PLATFORM_CONTRACT_DIGEST`

## What is checked in vs fetched at build time

Checked in here and elsewhere in this repo:

- `build.sh`, `publish.sh`, `promote.sh`
- `versions.env` for pinned upstream k3s version
- `platform-contract/profiles/demo-apps/profile.env`
- `platform-contract/profiles/demo-apps/images.lock.json`
- the platform-contract rendering and lint tooling under `tools/platform-contract/`

Fetched during the build:

- the upstream `k3s` binary for the selected architecture
- the upstream `k3s-airgap-images-<arch>.tar`
- each application image pinned in the rendered `images.lock.json`

There is intentionally no checked-in `airgap-platform/` payload tree in this
repository. The artifact is assembled by script from pinned repo inputs plus
fetched upstream bytes.

## Output shape

`build.sh` writes:

- `dist/airgap-platform.tar.gz`
- `dist/airgap-platform.meta.env`

The tarball contains:

- `k3s/`
- `platform/`
- `manifest.env`

`platform/` includes the rendered `images.lock.json` and
`platform/profile.env` from the current `demo-apps` build input.

`manifest.env` is self-describing and includes:

- `OURBOX_AIRGAP_PLATFORM_SOURCE`
- `OURBOX_AIRGAP_PLATFORM_REVISION`
- `OURBOX_AIRGAP_PLATFORM_VERSION`
- `OURBOX_AIRGAP_PLATFORM_CREATED`
- `OURBOX_PLATFORM_CONTRACT_REF`
- `OURBOX_PLATFORM_CONTRACT_DIGEST`
- `AIRGAP_PLATFORM_ARCH`
- `K3S_VERSION`
- `OURBOX_PLATFORM_PROFILE`
- `OURBOX_PLATFORM_IMAGES_LOCK_PATH`
- `OURBOX_PLATFORM_IMAGES_LOCK_SHA256`

`publish.sh` also writes:

- `dist/airgap-platform.<arch>.push.log`
- `dist/airgap-platform.<arch>.ref`
- `dist/airgap-platform.<arch>.publish-record.json` (canonical machine-readable publish record)

Catalog maintenance:

- `tools/airgap-platform/update-catalog.sh`
  - appends a channel row into `catalog-arm64` or `catalog-amd64`
  - uses the canonical airgap publish record as input

`promote.sh` writes:

- `dist/airgap-platform.<arch>.promote.source.ref`
- `dist/airgap-platform.<arch>.promote.digest.ref`
- `dist/airgap-platform.<arch>.promote.target.ref`

## Entrypoints

Build:

```bash
OURBOX_PLATFORM_CONTRACT_REF=ghcr.io/techofourown/sw-ourbox-os/platform-contract@sha256:... \
OURBOX_PLATFORM_CONTRACT_DIGEST=sha256:... \
ARCH=arm64 ./tools/airgap-platform/build.sh
OURBOX_PLATFORM_CONTRACT_REF=ghcr.io/techofourown/sw-ourbox-os/platform-contract@sha256:... \
OURBOX_PLATFORM_CONTRACT_DIGEST=sha256:... \
ARCH=amd64 ./tools/airgap-platform/build.sh
```

Build and publish:

```bash
OURBOX_PLATFORM_CONTRACT_REF=ghcr.io/techofourown/sw-ourbox-os/platform-contract@sha256:... \
OURBOX_PLATFORM_CONTRACT_DIGEST=sha256:... \
ARCH=arm64 ./tools/airgap-platform/publish.sh arm64 beta
OURBOX_PLATFORM_CONTRACT_REF=ghcr.io/techofourown/sw-ourbox-os/platform-contract@sha256:... \
OURBOX_PLATFORM_CONTRACT_DIGEST=sha256:... \
ARCH=amd64 ./tools/airgap-platform/publish.sh amd64 nightly
```

Promote an already-published candidate digest into a version tag:

```bash
PROMOTE_SOURCE_PINNED_REF=ghcr.io/techofourown/sw-ourbox-os/airgap-platform@sha256:... \
  ./tools/airgap-platform/promote.sh arm64 v0.10.1
```

## How official publication works

- `.github/workflows/airgap-platform.yml` publishes the platform-contract first,
  then builds contract-bound airgap bundles from `main`.
- Official mainline publication moves `beta-<arch>`.
- Scheduled integration publication moves `nightly-<arch>`.
- Promotion workflows later re-tag the exact published digest into:
  - `stable-<arch>`
  - `exp-labs-<arch>`
  - `v*-<arch>`
- Catalog rows are appended only from those official channel moves.

This is a promote-first lane. Stable / exp-labs / versioned release tags are
promotions of an already-published digest, not a second heavy rebuild.

## Consumers

This artifact is consumed downstream by image-build repos through digest-pinned
refs, now synchronized from `release/approved-upstream-inputs.json`.

Primary consumers today:

- Matchbox uses the `arm64` bundle
- Woodbox uses the `amd64` bundle

See also:

- [ARTIFACT_PROVENANCE.md](../../docs/ARTIFACT_PROVENANCE.md)
- [official-image-production-and-consumption.md](../../docs/architecture/official-image-production-and-consumption.md)
- [airgap-platform-selection-contract.md](../../docs/reference/airgap-platform-selection-contract.md)
