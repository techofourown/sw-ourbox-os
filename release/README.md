# Release Control Files

This directory contains small release-control inputs used by the official
publication workflows and by manual downstream refresh steps.

These files are intentionally lightweight, human-reviewable control surfaces.

## Files

- `approved-upstream-inputs.json`
  - the canonical approved upstream snapshot for downstream official image builds
  - records approved `platform-contract` and `airgap-platform` refs and digests
- `REVALIDATION_TRIGGER`
  - documented escape hatch for forcing an official republish without a substantive
    source change

## How each file is used

### `approved-upstream-inputs.json`

Validated by:

- `tools/approved-upstream-inputs/validate.py`

Consumed by:

- maintainers validating the approved tuple in place
- manual downstream lockfile refreshes, optionally via
  `tools/approved-upstream-inputs/sync_downstream_official_inputs.py`

Purpose:

- keeps official downstream image repos pinned to one approved upstream snapshot

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

- [tools/approved-upstream-inputs/README.md](../tools/approved-upstream-inputs/README.md)
- [tools/install-defaults/README.md](../tools/install-defaults/README.md)
- [ARTIFACT_PROVENANCE.md](../docs/ARTIFACT_PROVENANCE.md)
