# Platform Contract Source

This directory contains the checked-in source inputs for the published
`platform-contract` artifact.

Published artifact:

- `ghcr.io/techofourown/sw-ourbox-os/platform-contract`

## What lives here

This tree is the source of truth for the platform contract content that gets
rendered, linted, bundled, and later consumed by downstream image repos.

Key inputs:

- `landing/`
  - legacy fixture static assets retained for local validation only
- `todo-bloom/`
  - legacy fixture static assets retained for local validation only
- `profiles/`
  - named profile inputs used by the contract renderer

What does not live here:

- the build/publish scripts themselves
- render/lint utilities
- OCI publication logic

Those live under `tools/platform-contract/`.

## What becomes published

`tools/platform-contract/build.sh` copies this source tree into a temporary build
area, writes `contract.env`, renders the current published `demo-apps` profile,
lints the render, and produces `dist/platform-contract.tar.gz`.

The published artifact contains:

- this source content
- generated `manifests/`
- generated `rendered/defaults/...`
- verification and helper tools copied from `tools/platform-contract/`
- contract metadata in `contract.env`

`platform-contract/manifests/` in the published bundle is generated output. The
checked-in source of truth remains this directory plus the toolchain under
`tools/platform-contract/`.

## Why this matters

This directory defines the contract consumed above the hardware seam:

- generated data surfaces and contract metadata
- rendered manifests and verification surfaces
- profile-specific render controls

It should no longer be the production authority for live application HTML/JS
or for copied standalone catalog/image-lock defaults. Published application
catalogs are expected to ship their own static app content in the selected app
images rather than via `asset_dir` overlays from this tree.

The same source tree is also used when building the substrate bundle, because
that bundle re-renders the contract and then filters the result down to
platform-owned image refs only.

## Build and validation

From the repo root:

```bash
./tools/platform-contract/build.sh
./tools/platform-contract/validate.sh
```

The build always uses the in-repo `profiles/demo-apps/` fixtures as render
inputs. No external catalog ref is required.

## Related directories

- `tools/platform-contract/` for the render, lint, publish, and verification scripts
- `platform-contract/profiles/demo-apps/` for local fixture inputs and profile metadata
- `platform-contract/manifests/` for generated output inside published bundles
