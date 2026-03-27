# Application Catalog Repo Template

This template is the reference starter for a new catalog repository.

First-party repos follow the naming convention `sw-ourbox-catalog-<catalog>`.
External orgs may use any repository name — the publish workflows are fully
parameterized from `${GITHUB_REPOSITORY}`.

Use it together with:

- [`docs/reference/app-authoring-guide.md`](../../docs/reference/app-authoring-guide.md)
- [`docs/reference/application-catalog-repository-contract.md`](../../docs/reference/application-catalog-repository-contract.md)
- [`schemas/application-catalog.schema.json`](../../schemas/application-catalog.schema.json)
- [`schemas/application-catalog-bundle-publish-record.schema.json`](../../schemas/application-catalog-bundle-publish-record.schema.json)

## What this repo class owns

- the application catalog definition
- the default app set for that catalog
- the source refs that should be resolved into the published image lock
- CI that validates and publishes the catalog bundle

## What this repo class does not own

- per-application source code
- container build logic
- app-repo publish workflows
- target runtime mechanics

## Template contents

- `bootstrap.sh`
  - pulls the catalog-tooling OCI artifact and extracts shared scripts
- `.github/workflows/ci.yml`
  - bootstraps tooling, then runs `validate-catalog-repo.sh`
- `.github/workflows/publish-catalog-bundle.yml`
  - bootstraps tooling, then runs `publish-catalog-bundle.sh`
- `catalog/catalog.json`
  - example catalog definition with route and health metadata
- `catalog/image-sources.json`
  - example image-source file resolved into the published `images.lock.json`
- `catalog/profile.env`
  - installer-facing default metadata

## How shared tooling works

All business logic scripts come from the **catalog-tooling** OCI artifact
published by `sw-ourbox-os`. The `bootstrap.sh` script:

1. Pulls the artifact from `ghcr.io/techofourown/sw-ourbox-os/catalog-tooling:stable`
2. Validates the interface version for compatibility
3. Extracts scripts into `scripts/` (gitignored)

To override the tooling channel for testing:
```bash
OURBOX_CATALOG_TOOLING_REF=ghcr.io/techofourown/sw-ourbox-os/catalog-tooling:edge bash bootstrap.sh
```

## Recommended next steps when instantiating

1. Replace the example catalog metadata with the real app entries.
2. Update `image-sources.json` to the real source refs from your app repos.
3. Keep `profile.env` in sync with `catalog.json`.
4. Publish the bundle and its `catalog.tsv` rows so installers can resolve it by contract.

## Working examples

- [`techofourown/sw-ourbox-catalog-demo`](https://github.com/techofourown/sw-ourbox-catalog-demo) — first-party, multi-source
- [`techofourown/sw-ourbox-catalog-hello-world`](https://github.com/techofourown/sw-ourbox-catalog-hello-world) — first-party, minimal
- [`johnbenac/calculator-catalog`](https://github.com/johnbenac/calculator-catalog) — third-party example
