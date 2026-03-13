# Apps Repository Contract

This document defines the first new class of repository in the OurBox
application distribution model: the apps repository.

## Purpose

An apps repository owns the source code and CI needed to publish OCI images for
one or more applications collected together in a coherent publisher repo.

Typical collections include:

- a demo suite
- a first-party core app set
- a community-maintained set of related apps

This is the repo class that replaces today's implicit dependency on a shared
`demo-apps` image set checked into `sw-ourbox-os`.

## Responsibilities

An apps repository owns:

- source code for one or more related applications
- container image build inputs
- CI for lint, test, build, and publish
- machine-readable publish metadata for the published image digests
- release notes and versioning for that repo's published applications

An apps repository does not own:

- OS payload composition
- installer behavior
- target runtime install logic
- app-catalog selection UX
- cross-app bundle composition

## Expected outputs

Each apps repository should publish:

- one or more digest-pinned OCI images
- a canonical publish record or equivalent machine-readable release artifact for
  each published image
- optional collection metadata enumerating which app ids live in that repo

The important downstream truth surface is the pinned image digest, not a moving
tag.

## Consumer

Apps repositories are consumed by the second new repo class:

- application catalog repositories

Those repos decide which published application images are bundled together and
which apps are exposed as defaults.

## Minimal CI posture

At minimum, an apps repository should provide CI that:

- builds one or more application images reproducibly
- publishes digest-pinned OCI images
- records the published refs and digests in machine-readable output
- makes those published images available to an application catalog repository

## Naming

Recommended user-facing term:

- `application`

Recommended repository role term:

- `apps repository`

Recommended repository family:

- `sw-ourbox-apps-<collection>`

Examples:

- `sw-ourbox-apps-demo`
- `sw-ourbox-apps-core`

OCI examples:

- `ghcr.io/techofourown/sw-ourbox-apps-demo/todo-bloom`
- `ghcr.io/techofourown/sw-ourbox-apps-core/contacts`

Avoid using:

- `store`
- `bundle repo`

Those are downstream concepts.
