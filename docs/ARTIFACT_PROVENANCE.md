# Artifact Provenance — sw-ourbox-os

This document is the required audit record for `sw-ourbox-os` per the
[Official Artifact Build and Provenance Policy](https://github.com/techofourown/org-techofourown/blob/main/docs/policies/OFFICIAL_ARTIFACT_BUILD_AND_PROVENANCE_POLICY.md)
and
[ADR-0008](https://github.com/techofourown/org-techofourown/blob/main/docs/decisions/ADR-0008-adopt-organization-controlled-build-infrastructure-for-heavy-artifacts.md).

---

## Artifact types produced

| Artifact | Registry path | Description |
|---|---|---|
| Platform contract | `ghcr.io/techofourown/sw-ourbox-os/platform-contract` | Baseline manifests, platform configuration, and contract metadata baked into every OurBox OS image |
| Airgap platform (arm64) | `ghcr.io/techofourown/sw-ourbox-os/airgap-platform` (tag: `edge-arm64`) | k3s binary + airgap images + platform images for ARM64 devices (Matchbox, Cinderbox) |
| Airgap platform (amd64) | `ghcr.io/techofourown/sw-ourbox-os/airgap-platform` (tag: `edge-amd64`) | k3s binary + airgap images + platform images for x86-64 devices (Woodbox) |
| Install defaults | `ghcr.io/techofourown/sw-ourbox-os/install-defaults` | Installer configuration defaults baked into installer media |

All are published as ORAS OCI artifacts (non-runnable) to GHCR. Canonical identity is by digest.

---

## Official release channels

| Channel tag | Artifact | Trigger |
|---|---|---|
| `edge` | Platform contract, install-defaults | Push to `main` (source-filtered) |
| `edge-arm64` / `edge-amd64` | Airgap platform | Push to `main` (source-filtered) from the immutable candidate digest |
| `v*` | Platform contract, install-defaults | `release` event (published) |
| `v*-arm64` / `v*-amd64` | Airgap platform | Promotion after both candidate completion and matching GitHub Release `published` authorization are true; whichever arrives second wakes the retag |
| `stable` | Install defaults | Promotion after the successful `Install Defaults` release publish for the matching published GitHub Release tag; uses that publish run's artifact outputs instead of racing a sibling release workflow |

---

## Trusted release contexts

- Push to `main` branch (edge / nightly)
- Candidate completion on `main` plus GitHub Release event with `published` type (versioned promotion); either event may wake promotion when the other condition is already satisfied

`workflow_dispatch` is intentionally absent from all official publish workflows.

---

## Public build entrypoints

| Operation | Entrypoint |
|---|---|
| Build platform contract | `./tools/platform-contract/build.sh` |
| Publish platform contract | `./tools/platform-contract/publish.sh [tag]` |
| Build airgap platform | `ARCH=arm64 ./tools/airgap-platform/build.sh` |
| Publish airgap platform | `ARCH=arm64 ./tools/airgap-platform/publish.sh arm64 [tag]` |
| Build install defaults | `./tools/install-defaults/build.sh` |
| Publish install defaults | `TAG=edge ./tools/install-defaults/publish.sh [tag]` |
| Validate GraphMD dataset | `npm test` |

All build logic lives in this repository. Official and compatible builds use the same entrypoints.

---

## Official release workflows

| Workflow | File | Runner | Trigger |
|---|---|---|---|
| Airgap Platform | `.github/workflows/airgap-platform.yml` | `[self-hosted, official-heavy, airgap-builder]` | Push to `main` (source-filtered) |
| Airgap Platform Promote Release | `.github/workflows/airgap-platform-promote.yml` | `ubuntu-latest` | Candidate completion or release publication; promotes only when both candidate success and matching GitHub Release `published` authorization are present |
| Platform Contract | `.github/workflows/platform-contract.yml` | `ubuntu-latest` | Push to `main` (source-filtered) + release |
| Install Defaults | `.github/workflows/install-defaults.yml` | `ubuntu-latest` | Push to `main` (source-filtered) + release |
| Install Defaults Promote Stable | `.github/workflows/install-defaults-promote.yml` | `ubuntu-latest` | `workflow_run` after successful `Install Defaults` release publication for a matching non-prerelease `v*` tag |

`airgap-platform.yml` runs on organization-controlled build infrastructure in the
`official-heavy-artifacts` runner group and publishes one immutable candidate digest per
source revision, then tags `edge-<arch>` from that digest. `airgap-platform-promote.yml`
is lightweight and promotes the exact candidate digest into `v*-<arch>` only after both the
candidate run and a matching GitHub Release exist; whichever arrives second wakes promotion. `platform-contract.yml` and
`install-defaults.yml` run on GitHub-hosted runners (they are lightweight and do not require
dedicated hardware).

`install-defaults-promote.yml` is also lightweight. It follows the successful
`Install Defaults` release publish workflow for the same release tag so it does
not race sibling release publication. It reads optional curated `OS_DEFAULT_REF`
values from `release/install-defaults-stable.env` in the checked-out release tag.
If that file leaves all overrides empty, the workflow promotes the already-published
versioned bundle into `install-defaults:stable` by digest using the publish run's
artifact outputs.

---

## Provenance metadata

Every published artifact carries the following provenance in its OCI annotations:

| Field | Value source |
|---|---|
| `org.opencontainers.image.source` | `https://github.com/techofourown/sw-ourbox-os` |
| `org.opencontainers.image.revision` | Git commit SHA |
| `org.opencontainers.image.version` | `VERSION` env or `dev` |
| `org.opencontainers.image.created` | Build timestamp (UTC, ISO 8601) |
| `techofourown.artifact.kind` | `airgap-platform`, `platform-contract`, or `install-defaults` |
| `techofourown.airgap.arch` | `arm64` or `amd64` (airgap-platform only) |

Canonical artifact identity for consumption is **by digest**.

---

## Trigger filtering

All three publish workflows use `paths-ignore` to skip publication for changes that do not
affect the built artifacts.

The following paths do **not** trigger official publication when changed:

```
docs/**
records/**
types/**
SyRS-*.md
SRS-*.md
OurBox-OS-Requirements-Omnibus.md
CHANGELOG.md
README.md
CLAUDE.md
package.json
package-lock.json
```

All other paths are treated as potentially artifact-affecting and do trigger publication.
If a source change lands outside these ignored paths, it will trigger publication even if it
does not materially affect a specific artifact. This is intentional: `paths-ignore` fails open
(over-builds) rather than risking silent skips.

Release-event triggers are not filtered for the lightweight workflows that still use them.
Airgap version promotion no longer dispatches a second heavy release build; it waits for the
push-triggered candidate build to finish and then checks for matching release authorization.
`install-defaults:stable` promotion likewise follows the successful release-publish workflow
instead of racing it in parallel from the same release event.

### Forcing an official republish without source changes

Touch `release/REVALIDATION_TRIGGER` in a PR. That file is not in the `paths-ignore` list,
so merging a change to it will trigger all publish workflows. Use this when you need official
artifacts after infrastructure maintenance or runner migration, without making a substantive
source change. See `release/REVALIDATION_TRIGGER` for the documented procedure.

---

## Non-publishing revalidation

`.github/workflows/revalidate-airgap-platform.yml` runs the full airgap platform bundle build
(for both arm64 and amd64) on the official builder weekly (Sunday 04:00 UTC) and on
`workflow_dispatch`. It does NOT publish official artifacts. Use it to confirm the
release-capable path works after infrastructure changes, per the ADR-0008 revalidation
requirement.

---

## Cryptographic signatures and attestations

**No cryptographic signatures or attestations are currently used.**

Provenance is established via OCI annotations and digest-addressable artifact references.
Users should consume artifacts by digest to ensure they receive exactly what was published.

When signatures or attestations are adopted, they will be documented here.

---

## Downstream consumption

Image build repos (`img-ourbox-matchbox`, `img-ourbox-woodbox`) consume these artifacts via
digest-pinned refs in their `release/official-inputs.env`, but those lockfiles are no longer the
source of truth.

The single approved upstream snapshot now lives in
`release/approved-upstream-inputs.json` in this repo. It records:

- the approved versioned `platform-contract` ref and digest
- the approved versioned `airgap-platform` refs and digests for `arm64` and `amd64`
- the launcher marker that must remain present in the approved platform contract

`tools/approved-upstream-inputs/validate.py` is the approval gate for that snapshot. It verifies:

- each approved versioned ref resolves to the recorded digest
- each pinned ref embeds the same digest
- the approved platform contract still contains the launcher marker
- the rendered `verification/http-routes.tsv` inside the published contract still advertises that launcher marker for `landing-root`

When the approved snapshot changes on `main`, `.github/workflows/approved-upstream-inputs-sync.yml`
automatically opens downstream PRs that refresh `release/official-inputs.env` in the image repos.
That keeps official builds digest-pinned while eliminating duplicate hand-maintained approval ledgers
across the downstream repos.

The recommended downstream heavy-artifact model is now promote-first:

- push to protected `main` publishes a promotable `beta` artifact from pinned upstream refs
- matching GitHub Release `published` authorization plus candidate success promotes that digest into `stable`, with whichever condition arrives second waking the retag
- scheduled integration nightly builds resolve floating upstream `edge` refs and publish `nightly`
- matching GitHub Release `prereleased` authorization plus candidate success can promote the same digest into `exp-labs`, with whichever condition arrives second waking the retag

This keeps heavy rebuilds attached to meaningful input-policy changes rather than rebuilding the
same curated input set a second time just to stamp a release channel.

---

## References

- [OFFICIAL_ARTIFACT_BUILD_AND_PROVENANCE_POLICY](https://github.com/techofourown/org-techofourown/blob/main/docs/policies/OFFICIAL_ARTIFACT_BUILD_AND_PROVENANCE_POLICY.md)
- [ADR-0008: Organization-Controlled Build Infrastructure](https://github.com/techofourown/org-techofourown/blob/main/docs/decisions/ADR-0008-adopt-organization-controlled-build-infrastructure-for-heavy-artifacts.md)
- [ADR-0009: Package Platform Contract as OCI Artifact](./decisions/ADR-0009-package-the-platform-contract-as-an-oci-artifact.md)
- [Artifact Distribution and Integration Contract](./architecture/artifact-distribution-and-integration.md)
- `release/REVALIDATION_TRIGGER` — documented republish escape hatch
- `release/approved-upstream-inputs.json` — single approved upstream snapshot for downstream image repos
