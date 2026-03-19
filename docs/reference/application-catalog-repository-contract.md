# Application Catalog Repository Contract

This document defines the second new class of repository in the OurBox
application distribution model: the application catalog repository.

## Purpose

An application catalog repository consumes published OCI images from one or
more apps repositories and publishes the artifact currently transported as
`airgap-platform`.

User-facing meaning:

- `application catalog`
- `application catalog bundle`

Current transport name:

- `airgap-platform`

## Responsibilities

An application catalog repository owns:

- the catalog definition (`catalog.json`)
- the default app set for that catalog
- stable app identity for each app entry (`app_uid`)
- the mapping from app ids to published OCI images
- the authoring inputs:
  - `catalog.json`
  - `image-sources.json`
  - `profile.env`
- the rendered bundle outputs:
  - `images.lock.json`
  - `manifest.env`
- CI for building and publishing the catalog bundle artifact
- catalog rows that let installers browse available catalog bundles

An application catalog repository does not own:

- per-application source code
- apps-repository source code and image-build logic
- OS payload publication
- installer media composition
- target-side install/runtime logic

## Required bundle semantics

Each published application catalog bundle should:

- be bound to an exact `OURBOX_PLATFORM_CONTRACT_DIGEST`
- be architecture-specific when the downstream transport requires it
- carry the current rendered image set for that catalog
- carry `catalog.json` so the host-side installer can present:
  - the catalog identity
  - the catalog default app set
  - the list of selectable applications

## Installer-facing model

The installer now has three distinct host-side choices:

1. OS artifact
2. one or more application catalog bundles
3. selected applications from the merged effective catalog

The low-friction default path remains:

- default OS lane
- default application catalog set
- default app set from the merged effective catalog

## Stable app identity and multi-catalog merge

Application catalogs are expected to support host-side multi-catalog selection.
That means each app entry should carry a stable machine identity:

- `app_uid`

Recommended shape:

- `<publisher>/<app>`

Examples:

- `techofourown/todo-bloom`
- `techofourown/hello-world`
- `thirdparty/dufs`

Why this matters:

- the host installer merges one or more selected catalogs into one effective
  catalog before prompting for app selection
- deconfliction happens by stable app identity, not by display name
- identical `app_uid` entries with identical metadata and image refs are
  deduped
- identical `app_uid` entries with conflicting metadata are treated as
  conflicts and resolved deterministically by source-catalog order

## Expected outputs

An application catalog repository should publish:

- the bundle artifact currently named `airgap-platform`
- a canonical publish record for that bundle
- channel-tag and version-tag refs
- catalog rows for installer browsing

## Relationship to `sw-ourbox-os`

Today `sw-ourbox-os` still contains the reference implementation of this
pattern through the `demo-apps` profile and the `tools/airgap-platform/`
pipeline.

That should be treated as the prototype for future standalone application
catalog repositories, not as the final location for every catalog.

## Naming

Recommended user-facing terms:

- `application catalog`
- `application catalog bundle`
- `selected applications`

Recommended repository family:

- `sw-ourbox-catalog-<catalog>`

Examples:

- `sw-ourbox-catalog-demo`
- `sw-ourbox-catalog-hello-world`
- `sw-ourbox-catalog-core`

Expected upstream inputs:

- published images from one or more `sw-ourbox-apps-*` repositories

Current concrete repos:

- `sw-ourbox-catalog-demo`
- `sw-ourbox-catalog-hello-world`

## Shared tooling consumption

Application catalog repositories consume shared business logic from the
**catalog-tooling** OCI artifact published by `sw-ourbox-os`.

### Bootstrap mechanism

Each catalog repo checks in a single `bootstrap.sh` (~25 lines) that pulls
the catalog-tooling artifact from GHCR and extracts the scripts into
`scripts/`. The default channel is `stable`.

### Interface version compatibility

The tooling artifact carries an interface version in `manifest.env`
(`OURBOX_CATALOG_TOOLING_INTERFACE_VERSION`). Bootstrap validates this
against the expected interface version and fails loudly if they do not match.

Breaking changes bump the interface version and require consumer repos to
update `EXPECTED_INTERFACE_VERSION` in `bootstrap.sh`.

### Tooling provenance

Catalog-bundle publish records include both the requested tooling ref and
the resolved digest, providing full traceability of which tooling version
produced each published bundle.

### What stays per-catalog (not extracted)

- `catalog/catalog.json` — app definitions
- `catalog/image-sources.json` — image refs
- `catalog/profile.env` — catalog identity env vars
- `.github/workflows/*.yml` — truly thin CI wrappers
- `bootstrap.sh` — tooling artifact pull and validation

## Naming

Recommended user-facing terms:

- `application catalog`
- `application catalog bundle`
- `selected applications`

Recommended repository family:

- `sw-ourbox-catalog-<catalog>`

Examples:

- `sw-ourbox-catalog-demo`
- `sw-ourbox-catalog-hello-world`
- `sw-ourbox-catalog-core`

Expected upstream inputs:

- published images from one or more `sw-ourbox-apps-*` repositories

Current concrete repos:

- `sw-ourbox-catalog-demo`
- `sw-ourbox-catalog-hello-world`

Avoid using:

- `airgap bundle` as the primary user-facing term
- `app store` when no purchase or account model exists
