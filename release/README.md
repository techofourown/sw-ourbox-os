# Release Control Files

This directory contains small release-control inputs used by the official
publication workflows and by manual downstream refresh steps.

These files are intentionally lightweight, human-reviewable control surfaces.

## Files

- `REVALIDATION_TRIGGER`
  - documented escape hatch for forcing an official republish without a substantive
    source change

## How each file is used

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
