# Application Repository Contract

This document defines the first new class of repository in the OurBox
application distribution model: the application repository.

## Purpose

An application repository owns one application's source code and the CI needed
to publish one or more OCI images for that application.

This is the repo class that replaces today's implicit dependency on a shared
`demo-apps` image set checked into `sw-ourbox-os`.

## Responsibilities

An application repository owns:

- application source code
- container image build inputs
- CI for lint, test, build, and publish
- machine-readable publish metadata for the published image digests
- release notes and versioning for that application

An application repository does not own:

- OS payload composition
- installer behavior
- target runtime install logic
- app-catalog selection UX
- cross-app bundle composition

## Expected outputs

Each application repository should publish:

- one or more digest-pinned OCI images
- a canonical publish record or equivalent machine-readable release artifact

The important downstream truth surface is the pinned image digest, not a moving
tag.

## Consumer

Application repositories are consumed by the second new repo class:

- application catalog repositories

Those repos decide which published application images are bundled together and
which apps are exposed as defaults.

## Minimal CI posture

At minimum, an application repository should provide CI that:

- builds the application image reproducibly
- publishes digest-pinned OCI images
- records the published ref and digest in machine-readable output
- makes that published image available to an application catalog repository

## Naming

Recommended user-facing term:

- `application`

Recommended repository role term:

- `application repository`

Avoid using:

- `store`
- `bundle repo`

Those are downstream concepts.
