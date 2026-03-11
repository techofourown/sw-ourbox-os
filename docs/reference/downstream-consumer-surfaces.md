# Downstream Consumer Surfaces

- Status: Stable
- Audience: downstream image-build repos, installer-maintainer repos, automation authors, and maintainers of `sw-ourbox-os`

## Purpose

This document defines the only stable surfaces that downstream automation and downstream repositories should treat as contracts when consuming `sw-ourbox-os`.

This is the direct answer to:

> What may a downstream process safely consume from this repository, and what must it treat as implementation detail?

If a path or output is not described in this document as a stable consumer surface, downstreams SHALL NOT depend on it as a contract.

---

## 1. Stable consumer surfaces

There are exactly five stable consumer-surface classes in this repository.

1. Published upstream OCI artifacts
2. The approved upstream snapshot
3. Vendored shared downstream release-control module
4. Vendored shared installer helpers
5. Reference contract documents

Everything else is either source material, repo-local tooling, or generated documentation.

---

## 2. Published upstream OCI artifacts

The following published artifact families are stable consumer surfaces.

| Artifact family | Canonical OCI repo | Authoritative source in this repo | Build/publish entrypoints | Canonical machine-readable publish record |
|---|---|---|---|---|
| platform-contract | `ghcr.io/techofourown/sw-ourbox-os/platform-contract` | `platform-contract/` + `tools/platform-contract/` | `tools/platform-contract/build.sh`, `tools/platform-contract/publish.sh` | `dist/platform-contract.publish-record.json` |
| airgap-platform | `ghcr.io/techofourown/sw-ourbox-os/airgap-platform` | `tools/airgap-platform/` + `platform-contract/profiles/demo-apps/` + rendered contract inputs | `tools/airgap-platform/build.sh`, `tools/airgap-platform/publish.sh`, `tools/airgap-platform/promote.sh` | `dist/airgap-platform.<arch>.publish-record.json` |
| install-defaults | `ghcr.io/techofourown/sw-ourbox-os/install-defaults` | `install-defaults/` + `tools/install-defaults/` | `tools/install-defaults/build.sh`, `tools/install-defaults/publish.sh` | `dist/install-defaults.publish-record.json` |

### Consumption rule
Downstreams SHALL consume published artifacts by digest or by an approved pinned ref, not by assuming a moving tag is stable.

### Compatibility outputs
The `.meta.env`, `.ref`, and `.push.log` outputs remain valid compatibility surfaces for shell and human inspection, but the JSON publish record is the canonical machine-readable publication surface.

---

## 3. Approved upstream snapshot

The approved upstream snapshot is a stable consumer surface.

**Path:**
- `release/approved-upstream-inputs.json`

This file is the single approved upstream-control snapshot for downstream official image-build repos.

It defines the approved:

- platform-contract artifact ref and digest,
- airgap-platform arm64 ref and digest,
- airgap-platform amd64 ref and digest,
- required route marker used for validation.

### Consumption rule
Official downstream image-build repos SHALL derive their pinned upstream lockfiles from this file rather than maintaining separate hand-written approval ledgers.

### Validation rule
This file is defined by:
- `schemas/approved-upstream-inputs.schema.json`

and validated by:
- `tools/approved-upstream-inputs/validate.py`

---

## 4. Vendored shared downstream module

The following path is a stable vendorable downstream module.

**Path:**
- `tools/release-control/`

This module is intentionally vendored by downstream image-build repos at a pinned upstream revision.

It owns the shared downstream control-plane logic for:

- candidate provenance generation and validation,
- promotion eligibility lookup,
- digest-only promotion behavior,
- shared metadata serialization,
- shared catalog update behavior.

### Consumption rule
Downstream repos that vendor this module SHALL pin it by upstream commit and SHALL diff-check their vendored copy against that pin in CI.

### Stability rule
The path `tools/release-control/` is stable. This repository does not relocate it during organization cleanup because downstream path stability outranks cosmetic symmetry.

---

## 5. Vendored shared installer helpers

The following shared helpers are stable consumer surfaces for installer implementations.

| Helper | Path | Role |
|---|---|---|
| Installer selection reference resolver | `tools/install-defaults/installer-selection-resolver.sh` | Shared-above-the-hardware-seam installer selection policy implementation |
| Installer SSH helper | `tools/installer-ssh-helper.sh` | Shared-above-the-hardware-seam installer SSH normalization, validation, and config rendering |

These helpers are designed to be vendored or carried into installer media by downstream or target-specific repos.

### Consumption rule
Consumers MAY vendor these files directly, but when they do, they SHALL treat the upstream copy in this repository as the source of truth.

### Stability rule
These paths are stable and intentionally preserved.

---

## 6. Reference contract documents

The following documents are stable human-readable contract surfaces for downstream maintainers.

| Document | Purpose |
|---|---|
| `docs/reference/target-integration-contract.md` | Stable seam between `sw-ourbox-os` and hardware-specific `img-*` repos |
| `docs/reference/installer-selection-contract.md` | Shared policy for choosing installable OS payloads |
| `docs/reference/airgap-platform-selection-contract.md` | Shared policy for choosing a contract-bound airgap-platform bundle after OS selection |
| `docs/reference/installer-ssh-contract.md` | Shared policy for installer SSH posture |
| `docs/architecture/official-image-production-and-consumption.md` | High-level public model for official and custom image flows |
| `docs/architecture/artifact-distribution-and-integration.md` | Artifact-distribution and integration model |
| `docs/reference/artifact-publish-record-contract.md` | Machine-readable publish record contract |
| `docs/reference/repository-layout-and-authority.md` | Repository layout, source-of-truth, and generated/output boundaries |

These documents are for people, not machines, but they are still contract surfaces. Downstream maintainers should rely on them when deciding what is stable.

---

## 7. What downstreams SHALL pin

Downstream consumers SHALL pin the following things explicitly.

### 7.1 Published artifact identities
- Platform-contract by digest or approved pinned ref
- Airgap-platform by digest or approved pinned ref
- Install-defaults by pinned ref when exact identity matters

### 7.2 Approved upstream snapshot
Official downstream image-build repos SHALL treat `release/approved-upstream-inputs.json` as the upstream approval source of truth.

### 7.3 Vendored shared module revision
Downstream repos that vendor `tools/release-control/` SHALL pin the upstream commit they vendor from.

---

## 8. What downstreams SHALL NOT depend on

Downstreams SHALL NOT treat any of the following as stable consumer contracts unless they are later added to this document.

### 8.1 Repo-local toolchain paths
Do not depend on:

- `tools/requirements/*`
- `tools/policy/*`
- repo-local helper scripts that are not explicitly listed in this document

These are repo-local implementation details.

### 8.2 Generated documentation outputs
Do not depend on:

- `generated/requirements/*`

These are generated human-readable outputs, not downstream control-plane inputs.

### 8.3 Arbitrary `dist/` contents
Do not depend on random files in `dist/` unless they are explicitly documented here or in the artifact publish record contract.

### 8.4 GraphMD source layout
Do not consume:

- `records/`
- `types/`
- `spec.*`
- `section.*`
- `req.*`

as a downstream runtime contract. Those are repository source and documentation-authoring surfaces.

### 8.5 Wrapper or convenience scripts
Do not depend on any root-level wrapper script unless it is documented here as a stable surface.

---

## 9. Stability policy

This repository distinguishes sharply between:

- stable consumer surfaces,
- repo-local tooling,
- generated artifacts.

Only the paths and outputs named in this document are stable downstream surfaces.

### Path-stability rule
When a path is named in this document as a stable consumer surface, it should be treated as path-stable. Maintainability changes elsewhere in the repository must not casually relocate it.

### Additive change rule
If a new stable downstream surface is introduced in the future, it MUST be added to this document in the same change that introduces it.

There must be no silent consumer surfaces.

---

## 10. Summary

Downstreams should remember exactly this:

- consume the published artifacts,
- pin the approved upstream snapshot,
- vendor the shared release-control module only by pinned revision,
- vendor the installer helpers only as upstream-controlled shared helpers,
- read the reference contracts for behavior,
- and do not build downstream automation on undocumented repo-local files.
