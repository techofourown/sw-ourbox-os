# Approved Upstream Inputs Tooling

This directory contains the control-plane tooling for the approved upstream
snapshot consumed by downstream image-build repos.

Primary data file:

- `release/approved-upstream-inputs.json`

## Why this exists

`sw-ourbox-os` is the source of truth for which published upstream artifacts are
approved for official downstream image builds.

The approved snapshot records:

- one approved versioned `platform-contract` ref plus digest
- one approved versioned `airgap-platform` ref plus digest for `arm64`
- one approved versioned `airgap-platform` ref plus digest for `amd64`
- a required landing-page route marker used as a sanity check on the approved
  platform contract

This replaced duplicated hand-maintained approval ledgers in downstream repos.

## Scripts

- `validate.py`
  - validates `release/approved-upstream-inputs.json`
  - confirms versioned refs and pinned refs resolve to the recorded digests
  - pulls the approved platform-contract artifact and checks required marker and
    rendered route expectations
- `sync_downstream_official_inputs.py`
  - rewrites downstream `release/official-inputs.env` files from the approved
    snapshot
  - currently knows how to map Matchbox to `arm64` and Woodbox to `amd64`

## Official workflow

`.github/workflows/approved-upstream-inputs-sync.yml` is the automation around
this directory.

When the approved snapshot changes on `main`, the workflow:

1. validates the snapshot with `validate.py`
2. regenerates downstream `release/official-inputs.env`
3. opens downstream PRs with the refreshed lockfiles

## What this is not

This is not a published OCI artifact by itself. It is a repo-contained release
control surface that drives what downstream official builds are allowed to consume.

## Entrypoints

From the repo root:

```bash
python3 tools/approved-upstream-inputs/validate.py \
  --approved-inputs release/approved-upstream-inputs.json
```

Example downstream sync:

```bash
python3 tools/approved-upstream-inputs/sync_downstream_official_inputs.py \
  --approved-inputs release/approved-upstream-inputs.json \
  --target matchbox \
  --file /path/to/img-ourbox-matchbox/release/official-inputs.env
```

## Related docs

- [ARTIFACT_PROVENANCE.md](../../docs/ARTIFACT_PROVENANCE.md)
- [image-build-repo-ci-setup.md](../../docs/reference/image-build-repo-ci-setup.md)


The approved snapshot is defined by `schemas/approved-upstream-inputs.schema.json`.
Validation is two-stage:
1. schema validation (`npm run validate:schemas`),
2. semantic/digest/content validation (`python3 tools/approved-upstream-inputs/validate.py --approved-inputs release/approved-upstream-inputs.json`).
