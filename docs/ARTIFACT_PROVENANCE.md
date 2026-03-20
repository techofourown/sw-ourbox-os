# Artifact Provenance — sw-ourbox-os

This document is the required audit record for `sw-ourbox-os` per the
[Official Artifact Build and Provenance Policy](https://github.com/techofourown/org-techofourown/blob/main/docs/policies/OFFICIAL_ARTIFACT_BUILD_AND_PROVENANCE_POLICY.md)
and
[ADR-0008](https://github.com/techofourown/org-techofourown/blob/main/docs/decisions/ADR-0008-adopt-organization-controlled-build-infrastructure-for-heavy-artifacts.md).

---

## Artifact types produced

| Artifact | Registry path | Description |
|---|---|---|
| Platform contract | `ghcr.io/techofourown/sw-ourbox-os/platform-contract` | Baseline manifests, platform configuration, gateway/access-mode defaults, and contract metadata baked into every OurBox OS image |
| OurBox Substrate (arm64) | `ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate` (official lanes: `beta-arm64`, `nightly-arm64`, `stable-arm64`, `exp-labs-arm64`) | k3s binary + airgap images + platform images for ARM64 devices (Matchbox, Cinderbox) |
| OurBox Substrate (amd64) | `ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate` (official lanes: `beta-amd64`, `nightly-amd64`, `stable-amd64`, `exp-labs-amd64`) | k3s binary + airgap images + platform images for x86-64 devices (Woodbox) |
| Install defaults | `ghcr.io/techofourown/sw-ourbox-os/install-defaults` | Installer configuration defaults baked into installer media |

All are published as ORAS OCI artifacts (non-runnable) to GHCR. Canonical identity is by digest.

---

## Official release channels

| Channel tag | Artifact | Trigger |
|---|---|---|
| `edge` | Platform contract, install-defaults | Push to `main` (source-filtered) |
| `beta-arm64` / `beta-amd64` | OurBox Substrate | Push to `main` (source-filtered) from the immutable candidate digest |
| `nightly-arm64` / `nightly-amd64` | OurBox Substrate | Scheduled integration publish from the immutable nightly digest |
| `stable-arm64` / `stable-amd64` | OurBox Substrate | Promotion after both candidate completion and matching GitHub Release `published` authorization are true; whichever arrives second wakes the retag |
| `exp-labs-arm64` / `exp-labs-amd64` | OurBox Substrate | Promotion after both candidate completion and matching GitHub Release `prereleased` authorization are true; whichever arrives second wakes the retag |
| `v*` | Platform contract | Promotion after both successful `OurBox Substrate` candidate completion and matching GitHub Release `published` authorization are true; whichever arrives second wakes the retag |
| `v*` | Install defaults | `release` event (published) |
| `v*-arm64` / `v*-amd64` | OurBox Substrate | Versioned retag of the same already-published digest during stable or exp-labs promotion |
| `stable` | Install defaults | Promotion after the successful `Install Defaults` release publish for the matching published GitHub Release tag; uses that publish run's artifact outputs instead of racing a sibling release workflow |

---

## Trusted release contexts

- Push to `main` branch (beta candidate publication)
- Scheduled nightly integration publication
- Candidate completion on `main` plus GitHub Release event with `published` type (stable + versioned promotion); either event may wake promotion when the other condition is already satisfied
- Candidate completion on `main` plus GitHub Release event with `prereleased` type (exp-labs + versioned promotion); either event may wake promotion when the other condition is already satisfied

`workflow_dispatch` is intentionally absent from all official publish workflows.

---

## Public build entrypoints

| Operation | Entrypoint |
|---|---|
| Build platform contract | `./tools/platform-contract/build.sh` |
| Publish platform contract | `./tools/platform-contract/publish.sh [tag]` |
| Build ourbox-substrate | `OURBOX_PLATFORM_CONTRACT_REF=ghcr.io/techofourown/sw-ourbox-os/platform-contract@sha256:... OURBOX_PLATFORM_CONTRACT_DIGEST=sha256:... ARCH=arm64 ./tools/ourbox-substrate/build.sh` |
| Publish ourbox-substrate | `OURBOX_PLATFORM_CONTRACT_REF=ghcr.io/techofourown/sw-ourbox-os/platform-contract@sha256:... OURBOX_PLATFORM_CONTRACT_DIGEST=sha256:... ARCH=arm64 ./tools/ourbox-substrate/publish.sh arm64 [tag]` |
| Build install defaults | `./tools/install-defaults/build.sh` |
| Publish install defaults | `TAG=edge ./tools/install-defaults/publish.sh [tag]` |
| Validate GraphMD dataset | `npm test` |

All build logic lives in this repository. Official and compatible builds use the
same entrypoints.

Official `ourbox-substrate` and `platform-contract` publication both use the
in-repo `demo-apps` fixtures exclusively. No external application-catalog
ref is accepted or required.

---

## Official release workflows

| Workflow | File | Runner | Trigger |
|---|---|---|---|
| OurBox Substrate | `.github/workflows/ourbox-substrate.yml` | `[self-hosted, official-heavy, airgap-builder]` | Push to `main` (source-filtered) + scheduled nightly integration publish |
| OurBox Substrate Promote Release | `.github/workflows/ourbox-substrate-promote.yml` | `ubuntu-latest` | Candidate completion or release publication; promotes only when both candidate success and matching GitHub Release `published` or `prereleased` authorization are present |
| Platform Contract | `.github/workflows/platform-contract.yml` | `ubuntu-latest` | Push to `main` (source-filtered) |
| Platform Contract Promote Release | `.github/workflows/platform-contract-promote.yml` | `ubuntu-latest` | Candidate completion or release publication; promotes only when both OurBox Substrate candidate success and matching GitHub Release `published` authorization are present |
| Install Defaults | `.github/workflows/install-defaults.yml` | `ubuntu-latest` | Push to `main` (source-filtered) + release |
| Install Defaults Promote Stable | `.github/workflows/install-defaults-promote.yml` | `ubuntu-latest` | `workflow_run` after successful `Install Defaults` release publication for a matching non-prerelease `v*` tag |

`ourbox-substrate.yml` runs on organization-controlled build infrastructure in the
`official-heavy-artifacts` runner group, publishes the bound platform-contract
artifact first, then publishes one immutable candidate digest per source revision
and tags either `beta-<arch>` or `nightly-<arch>` from that digest. It appends
catalog rows only from those official channel moves. `ourbox-substrate-promote.yml`
is lightweight and promotes the exact push-main candidate digest into
`stable-<arch>`, `exp-labs-<arch>`, and `v*-<arch>` only after both the
candidate run and a matching GitHub Release authorization exist; whichever
arrives second wakes promotion. `platform-contract-promote.yml` follows that
same dual-condition model for the bound platform-contract digest uploaded by
the successful `OurBox Substrate` candidate run, so `platform-contract:v*` is
the same artifact identity the promoted substrate bundles were built against.
`platform-contract.yml` and `install-defaults.yml` run on GitHub-hosted runners
(they are lightweight and do not require dedicated hardware).

`install-defaults-promote.yml` is also lightweight. It follows the successful
`Install Defaults` release publish workflow for the same release tag so it does
not race sibling release publication. It promotes the already-published
versioned bundle into `install-defaults:stable` by digest using the publish
run's artifact outputs.

This repo also carries the canonical shared downstream release-control module in
`tools/release-control/`. Downstream image repos vendor that directory at a pinned
upstream revision, CI diff-checks the vendored copy, candidate workflows emit a
single authoritative `candidate-provenance.json`, and stable / exp-labs promotion
consumes that provenance bundle only. Promotion does not inspect artifact-carried
`.env` sidecars, and shared catalog updates flow through the same vendored module.

---

## Provenance metadata

Every published artifact carries the following provenance in its OCI annotations:

| Field | Value source |
|---|---|
| `org.opencontainers.image.source` | `https://github.com/techofourown/sw-ourbox-os` |
| `org.opencontainers.image.revision` | Git commit SHA |
| `org.opencontainers.image.version` | `VERSION` env or `dev` |
| `org.opencontainers.image.created` | Build timestamp (UTC, ISO 8601) |
| `techofourown.artifact.kind` | `ourbox-substrate`, `platform-contract`, or `install-defaults` |
| `techofourown.substrate.arch` | `arm64` or `amd64` (ourbox-substrate only) |

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
generated/requirements/SyRS-*.md
generated/requirements/SRS-*.md
generated/requirements/OurBox-OS-Requirements-Omnibus.md
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

`.github/workflows/revalidate-ourbox-substrate.yml` runs the full ourbox-substrate bundle build
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

Image build repos (`img-ourbox-matchbox`, `img-ourbox-woodbox`) consume these artifacts by
resolving channel tags (`:edge`, `:latest`) dynamically at build time via `oras resolve`.

The recommended downstream heavy-artifact model is now promote-first:

- push to protected `main` publishes a promotable `beta` artifact from pinned upstream refs
- matching GitHub Release `published` authorization plus candidate success promotes that digest into `stable`, with whichever condition arrives second waking the retag
- scheduled integration nightly builds resolve floating upstream `edge` refs and publish `nightly`
- matching GitHub Release `prereleased` authorization plus candidate success can promote the same digest into `exp-labs`, with whichever condition arrives second waking the retag

This keeps heavy rebuilds attached to meaningful input-policy changes rather than rebuilding the
same curated input set a second time just to stamp a release channel.

The canonical downstream release-control plane lives in `tools/release-control/`
in this repo. It defines the shared release authorization lookup, candidate-run
lookup, candidate provenance schema, metadata serialization, catalog rendering,
and digest-only promotion behavior that downstream image repos vendor and pin by
commit SHA.

---

## References

- [OFFICIAL_ARTIFACT_BUILD_AND_PROVENANCE_POLICY](https://github.com/techofourown/org-techofourown/blob/main/docs/policies/OFFICIAL_ARTIFACT_BUILD_AND_PROVENANCE_POLICY.md)
- [ADR-0008: Organization-Controlled Build Infrastructure](https://github.com/techofourown/org-techofourown/blob/main/docs/decisions/ADR-0008-adopt-organization-controlled-build-infrastructure-for-heavy-artifacts.md)
- [ADR-0009: Package Platform Contract as OCI Artifact](./decisions/ADR-0009-package-the-platform-contract-as-an-oci-artifact.md)
- [Artifact Distribution and Integration Contract](./architecture/artifact-distribution-and-integration.md)
- `release/REVALIDATION_TRIGGER` — documented republish escape hatch


## Canonical machine-readable publish records

Each upstream artifact publish also emits a JSON publish record in `dist/` (`*.publish-record.json`) while preserving `.meta.env`, `.ref`, and `.push.log` compatibility outputs.
