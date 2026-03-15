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

This profile still drives local validation by default. Official publication no
longer needs to treat the checked-in catalog/image-lock copies as production
authority:

- official `platform-contract` publication can render against an external
  published application catalog bundle via `OURBOX_APPLICATION_CATALOG_REF`
- official `airgap-platform` publication can pull the same external bundle and
  enforce its `OURBOX_PLATFORM_CONTRACT_DIGEST` binding

That means changes here should now be treated as fixture maintenance unless you
are deliberately updating the local validation corpus.

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
