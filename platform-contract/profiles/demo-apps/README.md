# Demo Apps Profile

This directory contains the local fixture inputs for the `demo-apps` platform
contract profile.

## Files

- `profile.env`
  - profile-level render inputs used by the platform-contract renderer
- `catalog.json`
  - checked-in application intent consumed by platform-contract rendering
- `image-sources.json`
  - checked-in application image source refs resolved into a generated
    `images.lock.json` during build and validation
- `platform-image-sources.json`
  - checked-in platform-owned third-party image source refs resolved into a
    generated `platform-images.lock.json` during build and validation

## Where this profile is used

`platform-contract` publication uses the local `catalog.json`,
`image-sources.json`, and `platform-image-sources.json` intent surfaces, then
resolves them into generated image lockfiles at build time.
`ourbox-substrate` consumes only `profile.env` plus
`platform-image-sources.json` from this directory and no longer re-renders the
demo application catalog just to derive platform-owned image refs.

Changes here affect the published platform-contract shape and image set.
Production application catalogs and their image sets are owned by the
standalone `sw-ourbox-catalog-*` repositories and selected at install time.

## Who consumes the output

Downstream image repos do not consume this directory directly. They consume the
published artifacts that were built from it:

- `platform-contract`
- `ourbox-substrate`

## Updating this profile

Use this directory when you need to change:

- local render-contract application intent
- application image source intent in `image-sources.json`
- platform-owned image source intent in `platform-image-sources.json`
- profile-level routing knobs in `profile.env`

Changing the production application catalog or image defaults should happen in
the standalone `sw-ourbox-catalog-*` repositories instead.

See also:

- [platform-contract/README.md](../../README.md)
- [tools/ourbox-substrate/README.md](../../../tools/ourbox-substrate/README.md)
