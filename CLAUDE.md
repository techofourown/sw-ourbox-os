# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A **GraphMD dataset** defining the OurBox OS platform — a local-first application platform for user-owned hardware. Two distinct things live here:

1. **Requirements dataset** — structured Markdown with YAML frontmatter: system requirements (SyRS), software requirements (SRS), architecture docs, ADRs, RFCs, types. Validated in CI by `@graphmd/dataset`.
2. **OCI artifact producers** — tooling in `tools/` that builds and publishes the platform contract bundle and OurBox substrate bundle to GHCR.

## Key Commands

```bash
npm ci                         # Install validator
npm test                       # Validate dataset + build compiled spec artifacts
```

Platform contract:
```bash
./tools/platform-contract/build.sh           # Build tarball into dist/
./tools/platform-contract/publish.sh [tag]   # Publish to GHCR (default: edge)
```

OurBox substrate (requires Docker/Podman, large download):
```bash
ARCH=arm64 ./tools/ourbox-substrate/publish.sh arm64 [tag]
```

Workflow safety check:
```bash
bash tools/check-workflow-safety.sh          # Run locally; also runs in CI on every PR/push
```

## Architecture

### Dataset surface

GraphMD YAML frontmatter types are defined in `types/`. Records live in `records/`, `docs/`, and top-level `SyRS-*.md`/`SRS-*.md` files. All cross-references use `[[type:recordId]]` wikilink syntax. Broken links and missing required fields fail `npm test`.

### OCI artifact outputs

| Artifact | Registry path | Trigger |
|---|---|---|
| Platform contract | `ghcr.io/techofourown/sw-ourbox-os/platform-contract` | push to `main`, `v*` tag |
| OurBox substrate (arm64/amd64) | `ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate` | push to `main`, `v*` tag |
| Install defaults | `ghcr.io/techofourown/sw-ourbox-os/install-defaults` | push to `main`, `v*` tag |

Channel tags: `edge` (main), `v*` (releases). All artifacts are digest-addressable.

Image build repos (e.g., `img-ourbox-matchbox`) pin the upstream approved
snapshot location in `tools/approved-upstream-inputs.upstream.env`, then
resolve exact digest-pinned refs at workflow start.

### Workflow safety

`tools/check-workflow-safety.sh` enforces:
1. No self-hosted workflow triggered by `pull_request`/`pull_request_target` — prevents untrusted PR code on privileged heavy-artifact builders
2. No official publish workflow exposes `workflow_dispatch` — official publication flows only from push-to-main or tag push

Official publish workflows (`ourbox-substrate.yml`) run on the dedicated self-hosted heavy-artifact
label set per [ADR-0008](https://github.com/techofourown/org-techofourown/blob/main/docs/decisions/ADR-0008-adopt-organization-controlled-build-infrastructure-for-heavy-artifacts.md). Lightweight workflows (`platform-contract.yml`, `install-defaults.yml`) run on `ubuntu-latest`.

## Conventions

- Commit messages: Conventional Commits with required body (see root CLAUDE.md)
- ADRs in `docs/decisions/`, RFCs in `docs/rfcs/` — follow 0000-template pattern
- Architecture documentation in `docs/architecture/`
- `dist/` outputs are gitignored; `platform-contract/` and `install-defaults/` contain the source bundles
