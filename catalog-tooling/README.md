# Catalog Tooling

This directory contains the authoritative source for the **catalog-tooling**
OCI artifact — shared business logic scripts consumed by all application
catalog repositories (`sw-ourbox-catalog-*`).

## What this artifact contains

| Script | Purpose |
|---|---|
| `render-catalog-bundle.sh` | Validate catalog data, resolve image refs, generate bundle tarball |
| `render-catalog-rows.py` | Append release row to TSV-based catalog index |
| `publish-catalog-bundle.sh` | Push bundle, manage tags, update catalog index, write publish record |
| `validate-catalog-repo.sh` | CI validation orchestrator: syntax checks, smoke test, image ref checks |
| `check-catalog-bundle-smoke.sh` | Offline integration test for bundle rendering |
| `check-publish-workflow.sh` | Validate publish workflow YAML invariants |
| `check-image-refs-exist.sh` | Validate all image refs resolve in registry |

## OCI artifact details

| Property | Value |
|---|---|
| Registry path | `ghcr.io/techofourown/sw-ourbox-os/catalog-tooling` |
| Artifact type | `application/vnd.techofourown.ourbox.catalog-tooling.v1.tar+gzip` |
| Channel tags | `edge` (every main push), `stable` (after self-test) |

## Consumption model

Consumer repos follow a producer-managed channel tag (`stable` by default).
Each catalog repo runs `bootstrap.sh` which pulls the artifact, validates
the interface version, and extracts scripts into `scripts/`.

See `templates/application-catalog-repo/bootstrap.sh` for the reference
consumer implementation.

## Build and publish

```bash
./tools/catalog-tooling/build.sh             # Build tarball into dist/
./tools/catalog-tooling/publish.sh [tag]     # Publish to GHCR (default: edge)
./tools/catalog-tooling/promote.sh           # Promote edge -> stable
./tools/catalog-tooling/self-test.sh         # Validate published artifact
```
