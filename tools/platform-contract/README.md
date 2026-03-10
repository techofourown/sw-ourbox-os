# Platform Contract Tooling

This directory contains the build, validation, publication, and verification
tooling for the published `platform-contract` artifact.

Published artifact:

- `ghcr.io/techofourown/sw-ourbox-os/platform-contract`

## Script roles

- `build.sh`
  - assembles `dist/platform-contract.tar.gz`
  - copies checked-in source from `platform-contract/`
  - writes `contract.env`
  - renders the current published `demo-apps` profile
  - lints the rendered output
- `publish.sh`
  - pushes the tarball to GHCR with OCI annotations
  - records the digest-pinned ref in `dist/platform-contract.ref`
- `validate.sh`
  - local validation entrypoint used by CI
- `render-contract.py`
  - renders the contract into a concrete output tree
- `lint-rendered-contract.py`
  - validates the rendered result
- `check-target-prereqs.sh`
  - target-side prerequisite checks
- `contract-identity.sh`
  - helper for surfacing contract identity
- `verify-runtime.sh`
  - runtime verification helper
- `verify-persistence.sh`
  - optional persistence verification helper

## What gets published vs what stays repo-local

The platform-contract tarball includes more than just rendered manifests. It
also carries several helper scripts from this directory so downstream consumers
and targets can inspect and verify the contract at runtime.

Copied into the published bundle today:

- `render-contract.py`
- `lint-rendered-contract.py`
- `check-target-prereqs.sh`
- `contract-identity.sh`
- `verify-runtime.sh`
- `verify-persistence.sh`

That means this directory is both:

- the repo-local build/publish toolchain
- part of the published contract surface

## Entrypoints

From the repo root:

```bash
./tools/platform-contract/build.sh
./tools/platform-contract/publish.sh edge
./tools/platform-contract/validate.sh
```

Key outputs:

- `dist/platform-contract.tar.gz`
- `dist/platform-contract.meta.env`
- `dist/platform-contract.push.log`
- `dist/platform-contract.ref`

## Official workflows

- `.github/workflows/platform-contract.yml`
  - publishes `edge` from `main`
  - publishes `v*` from release/tag context

This is a lightweight lane and runs on GitHub-hosted runners.

## Source inputs

The checked-in source content for the artifact lives under `platform-contract/`.
This directory is the toolchain that turns that source into the published OCI
artifact.

See also:

- [platform-contract/README.md](../../platform-contract/README.md)
- [ARTIFACT_PROVENANCE.md](../../docs/ARTIFACT_PROVENANCE.md)


`publish.sh` now also emits a canonical machine-readable publish record JSON in `dist/` (see `docs/reference/artifact-publish-record-contract.md`).
