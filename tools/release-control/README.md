# Release Control Module

This directory contains the canonical shared downstream release-control module
owned by `sw-ourbox-os`.

Unlike `platform-contract`, `ourbox-substrate`, and `install-defaults`, this is
not published as an OCI artifact. It is consumed by downstream repos through
vendoring at a pinned upstream revision.

## Why this exists

Downstream image repos need the same logic for:

- candidate provenance generation and validation
- promotion eligibility lookup
- digest-only promotion behavior
- shared metadata serialization
- shared catalog update behavior

Keeping that logic here gives Matchbox and Woodbox one source of truth above the
hardware seam without collapsing their target-specific build mechanics.

## Key files

- `release_control.py`
  - main shared implementation
- `candidate-provenance.schema.json`
  - schema for the canonical `candidate-provenance.json` handoff bundle
- `resolve-promotable-release.sh`
  - shared release lookup helper
- `resolve-promotion-context.sh`
  - shared promotion-context helper
- `find-successful-candidate-run.sh`
  - candidate discovery helper
- `lib.sh`
  - shared shell helpers
- `tests/test_release_control.py`
  - upstream tests for the module

## What downstream repos do with it

Downstream image repos vendor this directory at a pinned commit and then:

- CI-diff the vendored copy against the upstream pin
- use the shared logic in candidate workflows
- emit one `candidate-provenance.json`
- consume that provenance bundle during stable or `exp-labs` promotion

The important rule is that promotion consumes candidate provenance, not ad hoc
artifact sidecars or locally invented metadata paths.

## What stays local downstream

This module does not own:

- heavy build mechanics
- target-specific installer behavior
- target-specific payload validation
- hardware-specific flashing or image build steps

Those remain local to the `img-*` repositories.

## Validation

From the repo root:

```bash
python3 -m unittest discover -s tools/release-control/tests -p 'test_*.py'
```

## Related docs

- [ARTIFACT_PROVENANCE.md](../../docs/ARTIFACT_PROVENANCE.md)
- [image-build-repo-ci-setup.md](../../docs/reference/image-build-repo-ci-setup.md)
