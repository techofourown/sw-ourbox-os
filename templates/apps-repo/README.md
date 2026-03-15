# Apps Repo Template

This template is the reference starter for a new `sw-ourbox-apps-*` repository.

Use it together with:

- [`docs/reference/app-authoring-guide.md`](../../docs/reference/app-authoring-guide.md)
- [`docs/reference/apps-repository-contract.md`](../../docs/reference/apps-repository-contract.md)
- [`schemas/apps-manifest.schema.json`](../../schemas/apps-manifest.schema.json)
- [`schemas/application-image-publish-record.schema.json`](../../schemas/application-image-publish-record.schema.json)

## What this repo class owns

- application source code and build contexts
- OCI image build inputs
- CI for validation, build, and publish
- machine-readable publish records for the published image digests

## What this repo class does not own

- installer behavior
- landing-page routing
- default app selection
- app catalog composition
- target-side platform rendering

Those are catalog and platform-contract responsibilities.

## Template contents

- `.github/workflows/ci.yml`
  - generic validation and image-build smoke
- `.github/workflows/publish-images.yml`
  - generic publish workflow driven by `apps-manifest.json`
- `apps-manifest.json`
  - machine-readable list of apps published by this repo
- `scripts/check-apps-manifest.sh`
  - validates manifest shape and required source files
- `scripts/check-app-builds.sh`
  - builds each declared app image locally for CI smoke
- `apps/example-app/`
  - minimal example image build context

## Expected outputs

- one or more OCI images in GHCR
- digest-pinned published refs
- one publish-record JSON file per app

## Recommended next steps when instantiating

1. Rename the repo and update `apps-manifest.json` image repos.
2. Replace `apps/example-app/` with your real app source trees.
3. Keep `apps-manifest.json` in sync with those source trees.
4. Extend CI with app-specific runtime smokes where appropriate.
5. Point an application catalog repo at the published digests.
