# Demo Apps Profile

This directory contains the local fixture inputs for the `demo-apps` platform
contract profile.

## Files

- `profile.env`
  - profile-level render inputs used by the platform-contract renderer
- `platform-images.lock.json`
  - source of truth for the platform-owned image refs consumed by both
    `render-contract.py` and `ourbox-substrate`
- `images.lock.json`
  - fixture image-lock data kept for local validation and negative tests
- `catalog.json`
  - fixture catalog data kept for local validation and negative tests

## Where this profile is used

`platform-contract` publication still uses the local `catalog.json` and
`images.lock.json` fixtures as render inputs. `ourbox-substrate` now consumes
only `profile.env` plus `platform-images.lock.json` from this directory and no
longer re-renders the demo application fixtures just to derive platform-owned
image refs.

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

- local render-contract validation coverage
- negative test fixtures for catalog/image-lock behavior
- profile-level routing knobs in `profile.env`
- platform-owned image refs in `platform-images.lock.json`

Changing the production application catalog or image defaults should happen in
the standalone `sw-ourbox-catalog-*` repositories instead.

See also:

- [platform-contract/README.md](../../README.md)
- [tools/ourbox-substrate/README.md](../../../tools/ourbox-substrate/README.md)
