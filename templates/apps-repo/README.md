# Apps Repo Template

This template shows the intended shape of an OurBox apps repository.

## What this repo class owns

- one or more applications collected into the same publisher repo
- container build inputs
- CI for publishing OCI images
- machine-readable publish metadata for the published image digests

## Expected outputs

- one or more OCI images for the applications in this repo
- pinned image digests
- publish metadata that an application catalog repo can consume

## Template contents

- `.github/workflows/publish-images.yml`
  - placeholder CI workflow for build + publish
- `apps-manifest.json`
  - example machine-readable metadata describing the applications published by
    this repo

## Recommended next steps when instantiating

1. Replace the placeholder image repos and tags with the real app image names.
2. Add the real build/test steps for the applications in this repo.
3. Emit canonical publish metadata for the published digests.
4. Point an application catalog repo at those digest-pinned images.
