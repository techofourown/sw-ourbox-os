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
- the mapping from app ids to published OCI images
- the rendered bundle inputs:
  - `catalog.json`
  - `images.lock.json`
  - `profile.env`
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
2. application catalog bundle
3. selected applications from that catalog

The low-friction default path remains:

- default OS lane
- default application catalog lane
- default app set from that catalog

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

Avoid using:

- `airgap bundle` as the primary user-facing term
- `app store` when no purchase or account model exists
