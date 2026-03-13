# Application Catalog Repo Template

This template shows the intended shape of an OurBox application catalog
repository.

## What this repo class owns

- the application catalog definition
- the default app set for that catalog
- the pinned OCI images included in that catalog
- CI that publishes the catalog bundle artifact currently transported as
  `airgap-platform`

## Expected outputs

- `catalog.json`
- rendered image lock input for the chosen applications
- the published application catalog bundle artifact
- machine-readable publish metadata
- catalog rows for installer browsing

## Template contents

- `.github/workflows/publish-catalog-bundle.yml`
  - placeholder CI workflow for bundle publication
- `catalog/catalog.json`
  - example catalog definition with app ids and defaults
- `scripts/render-catalog-bundle.sh`
  - placeholder renderer entrypoint

## Recommended next steps when instantiating

1. Replace the sample app ids with real application digests.
2. Generate the real `images.lock.json` and `profile.env` inputs.
3. Publish the bundle artifact with exact contract binding.
4. Update installer-facing catalog rows for the new catalog lanes.
