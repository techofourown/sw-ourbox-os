# Repository Layout and Authority

- Status: Stable
- Audience: maintainers, contributors, assistants maintaining this repository, and downstream readers who need to understand what is authoritative

## Purpose

This document defines:

- what each major part of the repository is for,
- which directories are authoritative,
- which outputs are generated,
- which paths are stable consumer surfaces,
- and where future files belong.

This document exists so repository organization does not have to be rediscovered.

---

## 1. Core principle

This repository separates four different kinds of things:

1. authoritative source content,
2. published artifact source and toolchains,
3. stable downstream-consumed modules and helpers,
4. generated outputs.

The repository is organized around those boundaries.

---

## 2. Top-level layout

The following directory map is the repository contract.

| Path | Class | Authority status | Stable downstream surface? | Purpose |
|---|---|---|---|---|
| `docs/` | documentation source | authoritative | selected docs only | architecture, contracts, provenance, reference material |
| `records/` | GraphMD source | authoritative | no | requirements and document records |
| `types/` | GraphMD source | authoritative | no | GraphMD types |
| `platform-contract/` | artifact source | authoritative | indirectly, via published artifact | source inputs for the platform-contract artifact |
| `install-defaults/` | artifact source | authoritative | indirectly, via published artifact | data content for the install-defaults artifact |
| `release/` | control-plane source | authoritative | yes, for selected files | approved upstream snapshot and release-control inputs |
| `tools/platform-contract/` | artifact toolchain | authoritative repo-local tooling | no direct downstream contract | build/publish/validate toolchain for platform-contract |
| `tools/airgap-platform/` | artifact toolchain | authoritative repo-local tooling | no direct downstream contract | build/publish/promote toolchain for airgap-platform |
| `tools/install-defaults/` | artifact toolchain + shared helper ownership | authoritative | selected files yes | build/publish toolchain plus upstream-owned installer selection helper |
| `tools/approved-upstream-inputs/` | control-plane toolchain | authoritative | no direct downstream contract | validation and downstream-sync tooling for approved upstream snapshot |
| `tools/release-control/` | vendorable shared module | authoritative | yes | downstream shared release-control module |
| `tools/installer-ssh-helper.sh` | shared helper | authoritative | yes | installer SSH shared helper |
| `tools/requirements/` | repo-local toolchain | authoritative repo-local tooling | no | requirements build/validation toolchain |
| `tools/policy/` | repo-local toolchain | authoritative repo-local tooling | no | repo-local CI policy and safety checks |
| `tools/publish-records/` | repo-local toolchain | authoritative repo-local tooling | no direct downstream contract | shared writer for upstream publish-record JSON outputs |
| `schemas/` | schema source | authoritative | yes, for named schemas | stable repo-owned JSON schemas |
| `generated/requirements/` | generated output | generated | no | compiled requirements artifacts |
| `dist/` | generated build output | generated | selected named files only | build/publish output staging |

---

## 3. Authoritative source of truth by area

### 3.1 Requirements and architecture
Authoritative source:

- `records/`
- `types/`
- `docs/`

Generated outputs under `generated/requirements/` are not source of truth.

### 3.2 Platform-contract artifact
Authoritative source:

- `platform-contract/`
- `tools/platform-contract/`

Published artifact identity is the consumer surface, not the raw source tree.

### 3.3 Install-defaults artifact
Authoritative source:

- `install-defaults/`
- `tools/install-defaults/`

### 3.4 Airgap-platform artifact
Authoritative source:

- `tools/airgap-platform/`
- relevant platform-contract profile inputs used by that build

### 3.5 Downstream official upstream approval
Authoritative source:

- `release/approved-upstream-inputs.json`

### 3.6 Shared downstream release-control module
Authoritative source:

- `tools/release-control/`

### 3.7 Shared installer helpers
Authoritative source:

- `tools/install-defaults/installer-selection-resolver.sh`
- `tools/installer-ssh-helper.sh`

---

## 4. Generated outputs

The repository intentionally distinguishes generated outputs from source.

### 4.1 Requirements outputs
All compiled requirements outputs belong under:

- `generated/requirements/`

This directory contains generated human-readable artifacts only.

Generated requirements outputs must not be emitted at repo root.

### 4.2 Build and publish staging outputs
Transient or generated build/publish outputs belong under:

- `dist/`

This includes:

- tarballs,
- `.meta.env`,
- `.ref`,
- `.push.log`,
- `.publish-record.json`,
- and similar build/publish artifacts.

Do not treat `dist/` as a source directory.

---

## 5. Stable versus repo-local paths

### 5.1 Stable paths
Stable consumer surfaces are documented in:

- `docs/reference/downstream-consumer-surfaces.md`

If a path is not named there as a stable surface, downstream consumers should treat it as unstable.

### 5.2 Repo-local paths
The following are repo-local toolchain paths and may evolve without downstream contract guarantees:

- `tools/requirements/`
- `tools/policy/`
- `tools/publish-records/`

These exist to keep the repository internally organized.

---

## 6. Placement rules for future files

These rules are mandatory for future additions.

### 6.1 Requirements-toolchain files
If a file exists to:

- load GraphMD snapshots,
- validate the dataset,
- compile requirements outputs,
- verify generated requirement artifacts,

it belongs under:

- `tools/requirements/`

### 6.2 Repo-local policy or safety checks
If a file exists to:

- enforce workflow safety,
- enforce public sanitization,
- check repository-local CI policy,

it belongs under:

- `tools/policy/`

### 6.3 Publish-record helpers
If a file exists to:

- write JSON publish records,
- validate publish-record fixtures,
- support shared publish-record generation across artifact families,

it belongs under:

- `tools/publish-records/`

### 6.4 Stable repo-owned schemas
If a file defines a stable JSON schema for a repository contract surface, it belongs under:

- `schemas/`

unless it is exclusively owned by an existing vendorable module and travels with that module.

### 6.5 Generated requirements outputs
Generated requirements outputs belong under:

- `generated/requirements/`

Never place them at repo root.

### 6.6 Artifact-family build/publish logic
If a file exists to build, publish, promote, or validate one specific artifact family, it belongs under:

- `tools/<artifact-family>/`

Examples:
- `tools/platform-contract/`
- `tools/airgap-platform/`
- `tools/install-defaults/`

### 6.7 Stable vendorable downstream modules
If a file or directory is intended to be vendored by downstream repositories as a shared module, it MUST:

1. live at a path chosen for long-term stability,
2. be documented in `docs/reference/downstream-consumer-surfaces.md`,
3. and carry its own README explaining its contract.

Do not create silent vendorable modules.

---

## 7. Files that intentionally stay where they are

This repository intentionally preserves certain asymmetries because path stability matters more than cosmetic perfection.

The following paths remain in place by design:

- `tools/release-control/`
- `tools/install-defaults/installer-selection-resolver.sh`
- `tools/installer-ssh-helper.sh`

These are already stable downstream surfaces. They are not being relocated merely to make the tree more symmetrical.

---

## 8. What not to do again

The repository should not return to any of the following states:

- generated compiled requirements at repo root,
- requirements compiler files scattered at `tools/` root,
- CI policy checks scattered at `tools/` root,
- undocumented stable downstream-consumed paths,
- machine-readable contract files with no schema,
- duplicate canonical copies of moved repo-local toolchain files.

---

## 9. Quick mental model

Use this mental model and keep it intact.

### 9.1 Docs and GraphMD
`docs/`, `records/`, and `types/` explain the system.

### 9.2 Artifact source trees and toolchains
`platform-contract/`, `install-defaults/`, and the artifact-specific `tools/*/` directories define what gets built and published.

### 9.3 Release-control surfaces
`release/` and `tools/approved-upstream-inputs/` control what downstream official consumers are allowed to use.

### 9.4 Shared downstream modules
`tools/release-control/` and the shared installer helpers are the stable code surfaces that downstream repos may vendor.

### 9.5 Generated outputs
`generated/requirements/` and `dist/` are outputs, not sources.

---

## 10. Summary

This repository is now organized around authority, stability, and generation boundaries:

- source stays in source directories,
- published artifacts have clear source and toolchain ownership,
- stable consumer surfaces are documented once,
- repo-local toolchains are grouped,
- generated outputs are kept out of the root,
- and future additions have a single obvious landing place.
