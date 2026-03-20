# Release Control Files

This directory contains small release-control inputs used by the official
publication workflows and by manual downstream refresh steps.

These files are intentionally lightweight, human-reviewable control surfaces.

## Files

- `approved-upstream-inputs.json`
  - authoritative intent surface for downstream-approved upstream channels;
    workflows should resolve these selectors to immutable refs at runtime
- `REVALIDATION_TRIGGER`
  - documented escape hatch for forcing an official republish without a substantive
    source change

## How each file is used

### `approved-upstream-inputs.json`

Consumed by:

- downstream image-build workflow logic that needs the current approved
  upstream input policy without checking digest-pinned refs into downstream
  control-plane files

Purpose:

- records upstream input intent such as repository and approved release lane
- may record lane-specific intent such as `candidate` versus `nightly`
- candidate entries should point at immutable published snapshot tags such as
  `vX.Y.Z` or `vX.Y.Z-<arch>`, while nightly may intentionally remain on a
  floating nightly lane
- keeps approval separate from generated immutable ref materialization
- lets downstream workflows resolve digests at workflow start and record those
  exact identities only in generated provenance outputs

### `REVALIDATION_TRIGGER`

Consumed by:

- the normal official publish workflows through path filtering

Purpose:

- lets maintainers force an official republish after infrastructure work or
  revalidation, without making a fake source change elsewhere

## Ownership rule

These files are part of release control. Changes here should be treated as
artifact-affecting even if no application source changed.

See also:

- [tools/install-defaults/README.md](../tools/install-defaults/README.md)
- [ARTIFACT_PROVENANCE.md](../docs/ARTIFACT_PROVENANCE.md)
