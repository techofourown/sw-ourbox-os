# Assistant Repository Finalization Contract

Assistant, you are responsible for completing the repository finalization work described in this document.

Treat every instruction here as mandatory. Do not leave partial cleanup, competing organizational models, undocumented exceptions, or TODO placeholders. The purpose of this work is to make the repository obvious, stable, and boring to navigate so maintainers and downstream consumers do not need to reverse-engineer it again.

This contract is intentionally decisive. Do not turn it back into a menu of options.

---

## 1. Purpose

This repository already works. Your job is to make its structure and consumer surfaces legible enough that:

1. downstream repos know exactly what they are allowed to consume,
2. maintainers know exactly what is authoritative,
3. generated outputs are separated from source,
4. machine-readable publication metadata exists for every published upstream artifact,
5. and future additions land in the correct place without another organizational rewrite.

When this contract is complete, the repository should be easy to explain in one sentence:

> `sw-ourbox-os` contains the upstream platform definition, the upstream published artifacts, the approved upstream snapshot consumed by downstream image repos, and the stable shared modules they vendor.

---

## 2. Non-negotiable end state

By the time you are done, all of the following SHALL be true.

### 2.1 Stable consumer surfaces are explicitly documented
The repository SHALL contain a short, direct reference document that defines the stable downstream consumer surfaces and nothing else.

### 2.2 Generated requirements artifacts are no longer emitted at repo root
Compiled requirements outputs SHALL live under `generated/requirements/`, not at repo root.

### 2.3 Repo-local toolchain files are grouped by purpose
The requirements toolchain SHALL live under `tools/requirements/`.

The CI/policy safety checks SHALL live under `tools/policy/`.

### 2.4 Stable downstream-consumed paths remain stable
Do **not** move the following stable surfaces during this cleanup:

- `tools/release-control/`
- `tools/install-defaults/installer-selection-resolver.sh`
- `tools/installer-ssh-helper.sh`
- `tools/platform-contract/`
- `tools/ourbox-substrate/`
- `tools/install-defaults/`
This is deliberate. Path stability for downstream consumers now outranks cosmetic symmetry.

### 2.5 There is one public machine-readable publish record contract
Every published upstream artifact family in this repository SHALL emit a JSON publish record that matches one shared schema.

The publish record SHALL become the canonical machine-readable publication surface.

Existing `.meta.env`, `.ref`, and `.push.log` outputs SHALL remain in place for shell compatibility and human inspection.

### 2.7 Repository boundaries are documented once, clearly
The repository SHALL contain one reference document explaining:

- what each top-level or major directory is for,
- whether it is authoritative or generated,
- whether it is a stable surface or a repo-local implementation detail,
- and where future files of each class belong.

### 2.8 The repository root is no longer carrying generated requirements noise
The repo root SHALL not contain generated `SRS-*.md`, `SyRS-*.md`, or `OurBox-OS-Requirements-Omnibus.md` artifacts.

---

## 3. Required structural decisions

These decisions are now fixed. Implement them exactly.

### 3.1 Keep stable downstream surfaces where they already are
Do not introduce a new top-level `shared/` directory. Do not relocate vendorable downstream modules just to make the tree prettier.

The stable vendorable paths listed in section 2.4 are now part of the repository’s organizational contract.

### 3.2 Move repo-local requirements tooling into `tools/requirements/`
Move these files:

- `tools/compile-all-specs.cjs`
- `tools/load-graphmd-snapshot.cjs`
- `tools/validate-dataset.cjs`
- `tools/verify-spec-artifacts.cjs`

to:

- `tools/requirements/compile-all-specs.cjs`
- `tools/requirements/load-graphmd-snapshot.cjs`
- `tools/requirements/validate-dataset.cjs`
- `tools/requirements/verify-spec-artifacts.cjs`

Update every internal reference to the new paths.

Do not leave duplicate canonical copies.

### 3.3 Move repo-local policy checks into `tools/policy/`
Move these files:

- `tools/check-public-sanitization.sh`
- `tools/check-workflow-safety.sh`

to:

- `tools/policy/check-public-sanitization.sh`
- `tools/policy/check-workflow-safety.sh`

Update every internal reference to the new paths.

Do not leave duplicate canonical copies.

### 3.4 Create `generated/requirements/` and move compiled outputs there
The compiler SHALL write all generated requirements outputs into `generated/requirements/`.

That includes:

- one compiled file per spec,
- the omnibus.

The generated requirements directory SHALL contain a tracked `README.md` explaining its purpose.

Generated artifacts SHALL no longer be placed at repo root.

### 3.5 Create `schemas/`
Create a top-level `schemas/` directory.

It SHALL contain, at minimum:

- `schemas/artifact-publish-record.schema.json`

This directory is for stable repo-owned JSON schemas that define machine-readable contract surfaces.

Do not bury these schemas inside tool-specific directories unless the schema is exclusively owned by that tool/module. The existing `tools/release-control/candidate-provenance.schema.json` remains where it is because it belongs to that vendorable module.

### 3.6 Add one shared publish-record writer
Create a small shared helper under:

- `tools/publish-records/`

This helper SHALL be the single writer for upstream artifact publish records.

Do not duplicate record-writing logic separately in each publish script if it can be centralized safely.

The shell publish scripts may continue to orchestrate the build and push, but JSON record emission SHALL be centralized.

---

## 4. Required files to add

You SHALL add the following files and keep them current:

- `docs/reference/downstream-consumer-surfaces.md`
- `docs/reference/repository-layout-and-authority.md`
- `docs/reference/artifact-publish-record-contract.md`
- `generated/requirements/README.md`
- `schemas/artifact-publish-record.schema.json`

Those files are part of this finalization contract and are not optional.

---

## 5. Required changes to existing files

You SHALL update the following existing materials so they agree with the final structure.

### 5.1 Root `README.md`
Add a short “Repository quick map” section that links directly to:

- downstream consumer surfaces,
- repository layout and authority,
- artifact publish record contract,
- requirements management guide.

This section should be short and prominent.

### 5.2 `docs/01-Requirements/Requirements-Management-Guide.md`
Update it so it reflects:

- `tools/requirements/*` as the canonical requirements toolchain paths,
- `generated/requirements/` as the generated output location.

Remove any language that still implies compiled outputs belong at repo root.

### 5.3 `docs/architecture/official-image-production-and-consumption.md`
Add links to:

- `docs/reference/downstream-consumer-surfaces.md`
- `docs/reference/artifact-publish-record-contract.md`

This architecture doc should remain the high-level model; the new reference docs carry the direct operational contract.

### 5.4 `docs/architecture/artifact-distribution-and-integration.md`
Update links and wording so the new consumer-surface and publish-record docs are the direct reference points for machine-readable interfaces.

### 5.5 `docs/ARTIFACT_PROVENANCE.md`
Update any artifact output descriptions that now include publish-record JSON outputs.

### 5.6 Per-artifact tool READMEs
Update all of the following so they document the new JSON publish record outputs:

- `tools/platform-contract/README.md`
- `tools/ourbox-substrate/README.md`
- `tools/install-defaults/README.md`

---

## 6. Required machine-readable outputs

### 6.1 Artifact publish records
Each published upstream artifact family SHALL emit the following JSON file:

- platform contract:
  - `dist/platform-contract.publish-record.json`
- install-defaults:
  - `dist/install-defaults.publish-record.json`
- ourbox-substrate:
  - `dist/ourbox-substrate.<arch>.publish-record.json`

These records SHALL match `schemas/artifact-publish-record.schema.json`.

### 6.3 Existing compatibility outputs stay
Do not remove these legacy-compatible sidecars:

- `*.meta.env`
- `*.ref`
- `*.push.log`

They are still valid shell/human surfaces.

The JSON publish record becomes the canonical machine-readable surface, not the only surface.

---

## 7. Validation and CI requirements

You SHALL update the validation flow so it covers the new structure.

At minimum:

1. requirements dataset validation still runs,
2. requirements compilation still runs,
3. schema validation runs,
4. spec artifact verification runs against `generated/requirements/`,
5. existing shell/Python tests still pass.

Add or update package scripts so there is an explicit schema-validation entrypoint.

The repository's CI should fail if:

- a publish record violates its schema,
- generated requirements outputs appear at repo root,
- docs reference stale moved tool paths.

---

## 8. Path stability rules after this cleanup

After this cleanup is merged, future maintainers SHALL follow these rules:

### 8.1 New requirements tooling
Any new GraphMD/requirements compiler, validator, or snapshot helper belongs under:

- `tools/requirements/`

### 8.2 New repo-local policy or safety checks
Any new repo-local CI policy or sanitization checks belong under:

- `tools/policy/`

### 8.3 New repo-owned stable schemas
Any new top-level stable JSON schema for a repo contract surface belongs under:

- `schemas/`

unless it is owned entirely by an existing vendorable submodule.

### 8.4 New generated requirements artifacts
Any new generated requirements outputs belong under:

- `generated/requirements/`

Never place generated requirements outputs back at repo root.

### 8.5 New stable downstream-consumed modules
Before creating a new vendorable module, first decide whether it is truly a stable downstream surface.

If it is, document it in `docs/reference/downstream-consumer-surfaces.md`.

Do not create silent downstream surfaces.

---

## 9. Explicitly forbidden outcomes

Do not do any of the following:

- do not leave both old and new canonical copies of moved repo-local tools,
- do not leave generated requirements artifacts at repo root,
- do not introduce a second competing consumer-surface doc,
- do not move existing stable vendorable module paths during this cleanup,
- do not make JSON publish records optional,
- do not make the new schemas “documentation only” with no validation path,
- do not close this work while the README and reference docs still point to old paths.

---

## 10. Acceptance criteria

This cleanup is not done until all of the following are true.

### 10.1 Structure
- `tools/requirements/` exists and contains the requirements toolchain.
- `tools/policy/` exists and contains the repo-local policy checks.
- `generated/requirements/` exists and is the only location for compiled requirements artifacts.
- `schemas/` exists and contains the required schema files.
- `tools/publish-records/` exists and owns publish-record generation.

### 10.2 Root cleanliness
Running a root-level file listing SHALL NOT show generated compiled requirement artifacts such as:

- `SRS-*.md`
- `SyRS-*.md`
- `OurBox-OS-Requirements-Omnibus.md`

at repo root.

### 10.3 Documentation
The required reference docs exist and are linked from the root README.

### 10.4 Validation
All existing test suites still pass, and the validation flow now includes schema validation.

### 10.5 Publication metadata
Each upstream publish path emits its JSON publish record in `dist/`.

### 10.6 Consumer clarity
A downstream maintainer must be able to answer all of the following by reading only the new reference docs:

- what artifacts are published here,
- what files are authoritative,
- what downstream repos should pin,
- what helper modules they may vendor,
- what they must not depend on.

When these criteria are satisfied, the repository organization work is complete.

---

## 11. Completion rule

Once this contract is satisfied, treat the repository organization as settled.

Future work should use the documented boundaries rather than reopening the structure debate.
