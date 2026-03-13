# Application Repo Template

This template shows the intended shape of an OurBox application repository.

## What this repo class owns

- one application's source code
- container build inputs
- CI for publishing OCI images
- machine-readable publish metadata for the published image digest

## Expected outputs

- one or more OCI images for this application
- pinned image digests
- publish metadata that an application catalog repo can consume

## Template contents

- `.github/workflows/publish-image.yml`
  - placeholder CI workflow for build + publish
- `app-manifest.json`
  - example machine-readable metadata describing the application id and image

## Recommended next steps when instantiating

1. Replace the placeholder image repo and tags with the real app image name.
2. Add the real build/test steps for the application.
3. Emit canonical publish metadata for the published digest.
4. Point an application catalog repo at that digest-pinned image.
