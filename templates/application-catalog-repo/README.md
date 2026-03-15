# Application Catalog Repo Template

This template is the reference starter for a new
`sw-ourbox-catalog-<catalog>` repository.

Use it together with:

- [`docs/reference/app-authoring-guide.md`](../../docs/reference/app-authoring-guide.md)
- [`docs/reference/application-catalog-repository-contract.md`](../../docs/reference/application-catalog-repository-contract.md)
- [`schemas/application-catalog.schema.json`](../../schemas/application-catalog.schema.json)
- [`schemas/application-catalog-bundle-publish-record.schema.json`](../../schemas/application-catalog-bundle-publish-record.schema.json)

## What this repo class owns

- the application catalog definition
- the default app set for that catalog
- the digest-pinned OCI images included in that catalog
- CI that validates and publishes the catalog bundle

## What this repo class does not own

- per-application source code
- container build logic
- app-repo publish workflows
- target runtime mechanics

## Template contents

- `.github/workflows/ci.yml`
  - validates bundle rendering and pinned image refs
- `.github/workflows/publish-catalog-bundle.yml`
  - publishes the rendered catalog bundle to GHCR
- `catalog/catalog.json`
  - example catalog definition with route and health metadata
- `catalog/images.lock.json`
  - example digest-pinned image lock file
- `catalog/profile.env`
  - installer-facing default metadata
- `scripts/render-catalog-bundle.sh`
  - renders the published tarball
- `scripts/check-catalog-bundle-smoke.sh`
  - validates bundle shape and metadata coherence
- `scripts/check-image-refs-exist.sh`
  - verifies the pinned image refs resolve

## Recommended next steps when instantiating

1. Replace the example catalog metadata with the real app entries.
2. Update `images.lock.json` to the real published digests from your app repos.
3. Keep `profile.env` in sync with `catalog.json`.
4. Publish the bundle and hand its pinned ref to the installer flow.
