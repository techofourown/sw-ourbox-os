# Demo Apps Profile

This directory contains the local fixture inputs for the `demo-apps` platform
contract profile.

## Files

- `profile.env`
  - profile-level render inputs used by the platform-contract renderer
- `images.lock.json`
  - fixture image-lock data kept for local validation and negative tests
- `catalog.json`
  - fixture catalog data kept for local validation and negative tests

## Where this profile is used

Both `platform-contract` and `airgap-platform` publication use these fixtures
as their render inputs. No external application catalog ref is accepted or
required.

Changes here affect the published platform-contract shape and image set.
Production application catalogs and their image sets are owned by the
standalone `sw-ourbox-catalog-*` repositories and selected at install time.

## Who consumes the output

Downstream image repos do not consume this directory directly. They consume the
published artifacts that were built from it:

- `platform-contract`
- `airgap-platform`

## Updating this profile

Use this directory when you need to change:

- local render-contract validation coverage
- negative test fixtures for catalog/image-lock behavior
- profile-level routing knobs in `profile.env`

Changing the production application catalog or image defaults should happen in
the standalone `sw-ourbox-catalog-*` repositories instead.

See also:

- [platform-contract/README.md](../../README.md)
- [tools/airgap-platform/README.md](../../../tools/airgap-platform/README.md)
