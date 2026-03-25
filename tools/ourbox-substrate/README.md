# OurBox Substrate Build And Publish

This directory contains the build and publish entrypoints for the `ourbox-substrate`
artifact published from `sw-ourbox-os`.

Published artifact:

- `ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate`

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

`ourbox-substrate` is the offline substrate bundle consumed by downstream image repos.
It packages:

- the `k3s` binary for one target architecture
- the matching upstream k3s images tar
- the platform-owned image archives listed in the generated
  `platform/images.lock.json`

The artifact is architecture-specific, but the source code is not split by
architecture. `arm64` and `amd64` both use the same scripts here with a different
`ARCH` value.

Official publication builds from the checked-in platform profile metadata and
generated platform-owned image lock in this repository. It does not carry a
separate contract-digest compatibility gate.

## What is checked in vs fetched at build time

Checked in here and elsewhere in this repo:

- `build.sh`, `publish.sh`, `promote.sh`
- `versions.env` for pinned upstream k3s version
- `tools/ourbox-substrate/profiles/demo-apps/profile.env`
- `tools/ourbox-substrate/profiles/demo-apps/platform-image-sources.json`

Fetched during the build:

- the upstream `k3s` binary for the selected architecture
- the upstream K3s images tar for the selected architecture
- each platform-owned image pinned in the generated `platform/images.lock.json`

There is intentionally no checked-in `ourbox-substrate/` payload tree in this
repository. The artifact is assembled by script from checked-in platform inputs
plus fetched upstream bytes. The substrate build now reads the checked-in
platform profile metadata plus platform image source intent and resolves the
platform-owned image lock at build time; it does not re-render the
`demo-apps` catalog fixtures and carries no application catalog payload. The
bundle stores the fetched K3s images tar as `k3s-images-<arch>.tar`.

## Output shape

`build.sh` writes:

- `dist/ourbox-substrate.tar.gz`
- `dist/ourbox-substrate.meta.env`

The tarball contains:

- `k3s/`
- `platform/`
- `manifest.env`

`platform/` includes the generated platform-owned `images.lock.json` and
`platform/profile.env` from the selected platform profile.

`manifest.env` is self-describing and includes:

- `OURBOX_SUBSTRATE_SOURCE`
- `OURBOX_SUBSTRATE_REVISION`
- `OURBOX_SUBSTRATE_VERSION`
- `OURBOX_SUBSTRATE_CREATED`
- `OURBOX_SUBSTRATE_ARCH`
- `K3S_VERSION`
- `OURBOX_PLATFORM_PROFILE`
- `OURBOX_PLATFORM_IMAGES_LOCK_PATH`
- `OURBOX_PLATFORM_IMAGES_LOCK_SHA256`

`publish.sh` also writes:

- `dist/ourbox-substrate.<arch>.push.log`
- `dist/ourbox-substrate.<arch>.ref`
- `dist/ourbox-substrate.<arch>.publish-record.json` (canonical machine-readable publish record)

Catalog maintenance:

- `tools/ourbox-substrate/update-catalog.sh`
  - appends a channel row into `catalog-arm64` or `catalog-amd64`
  - uses the canonical substrate publish record as input

`promote.sh` writes:

- `dist/ourbox-substrate.<arch>.promote.source.ref`
- `dist/ourbox-substrate.<arch>.promote.digest.ref`
- `dist/ourbox-substrate.<arch>.promote.target.ref`

## Entrypoints

Candidate publication behavior:

- the official substrate publish workflow builds a platform-owned substrate bundle from `main`
- installer-time application catalog selection remains a separate concern and is
  not resolved during official substrate publication

Build:

```bash
ARCH=arm64 ./tools/ourbox-substrate/build.sh
ARCH=amd64 ./tools/ourbox-substrate/build.sh
```

Build and publish:

```bash
ARCH=arm64 ./tools/ourbox-substrate/publish.sh arm64 beta
ARCH=amd64 ./tools/ourbox-substrate/publish.sh amd64 nightly
```

Guardrail:

```bash
OURBOX_APPLICATION_CATALOG_REF=... ./tools/ourbox-substrate/build.sh   # rejected
OURBOX_ALLOW_FIXTURE_APPLICATION_CATALOG=1 ./tools/ourbox-substrate/build.sh   # rejected
```

Promote an already-published candidate digest into a version tag:

```bash
PROMOTE_SOURCE_PINNED_REF=ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate@sha256:... \
  ./tools/ourbox-substrate/promote.sh arm64 v0.10.1
```

## How official publication works

- `.github/workflows/ourbox-substrate.yml` resolves the currently published
  `platform-contract` ref, then builds platform-owned substrate bundles from `main`.
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

This artifact is consumed downstream by image-build repos, which resolve the
appropriate channel tag dynamically at build time via `oras resolve`.

Primary consumers today:

- Matchbox uses the `arm64` bundle
- Woodbox uses the `amd64` bundle

See also:

- [ARTIFACT_PROVENANCE.md](../../docs/ARTIFACT_PROVENANCE.md)
- [official-image-production-and-consumption.md](../../docs/architecture/official-image-production-and-consumption.md)
- [ourbox-substrate-selection-contract.md](../../docs/reference/ourbox-substrate-selection-contract.md)
