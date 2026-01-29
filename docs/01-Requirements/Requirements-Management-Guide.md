# OurBox OS Requirements Management Guide

**Applies to:** this repository’s GraphMD dataset + the CI compiler scripts in `tools/`  
**Source of truth:** GraphMD records in `types/`, `records/`, `blocks/`, `plugins/`  
**Generated outputs:** one Markdown file per spec + an omnibus + glossary (published as the `requirements-artifacts` CI artifact)

---

## 1) The mental model

### What is “authoritative” vs “generated”

* **Authoritative:** GraphMD dataset content (records + types). This is where you **add/edit requirements**.
* **Generated:** compiled Markdown files written by `tools/compile-all-specs.cjs`.

  * These are **build artifacts**. Do **not** hand-edit them.
  * If something looks wrong in a generated file, fix the underlying GraphMD records and recompile.

### How compilation works (high level)

* The compiler discovers **all `spec` records** (`typeId === "spec"`).
* For each spec, it renders:

  1. Spec title + metadata (`version`, `lastUpdated`, `status`)
  2. The spec’s `body` (freeform Markdown)
  3. Any **child “section” records** (determined by `parent`)
  4. Any **child “requirement” records** under each section (also determined by `parent`)
* It writes:

  * One file per spec at repo root:
    `"<specId>-<slugified-title>.md"`
  * One omnibus at repo root:
    `OurBox-OS-Requirements-Omnibus.md`
  * The omnibus embeds:
    * `docs/00-Glossary/Terms-and-Definitions.md`
    * `docs/architecture/Glossary.md`
    * `docs/architecture/AD-0001-ourbox-os-architecture-description.md`
    * All compiled specs

### The one rule that makes everything "click"

GraphMD records form a tree using the `parent` field:

* **Spec record**: `parent: "doc_area:spec"` (all specs share this parent)
* **Section record**: `parent: "spec:<SPEC_ID>"`
* **Requirement record**: `parent: "section:<SECTION_RECORD_ID>"`

That `"<typeId>:<recordId>"` pair is the canonical identifier everywhere:

* used in `parent`
* used in crossrefs like `[[spec:SyRS-0001]]`, `[[adr:ADR-0004]]`, etc.

---

## 2) Repository layout

### Canonical dataset directories (scanned by the loader)

The compiler loads GraphMD content from these directories at repo root:

* `types/`
* `records/`
* `blocks/`
* `plugins/`

Anything outside those directories won't be seen by the dataset snapshot loader (unless the upstream GraphMD loader does something special).

### Record directory naming convention

Each record lives in a directory named `<typeId>.<recordId>/` containing a file named `<recordId>.md`:

```
records/
  spec.SyRS-0001/SyRS-0001.md
  section.1-application-requirements/1-application-requirements.md
  req.APP-001/APP-001.md
  adr.ADR-0001/ADR-0001.md
```

Follow this convention when creating new records.

### Narrative docs (non-GraphMD or hybrid)

* Normal Markdown docs (glossary, architecture writeups, etc.) live under `docs/`.
* **The glossary is mandatory** at:

  * `docs/00-Glossary/Terms-and-Definitions.md`
* Specs commonly reference:

  * `[[arch_doc:AD-0001]]`
  * `[[adr:ADR-0001]]` etc.

Whether ADRs/ADs are fully modeled as GraphMD records or are “just docs” with optional GraphMD index records depends on how this repo is set up (see §6).

---

## 3) Build + CI artifact contract

### Local build (authoritative way to regenerate outputs)

Run:

```bash
npm test
```

This runs validation followed by compilation (equivalent to `npm run validate:dataset && npm run build:specs`).

To skip validation and only compile:

```bash
node tools/compile-all-specs.cjs
```

What the compiler does:

* Loads the dataset snapshot (prefers upstream `@graphmd/dataset` loaders; falls back to filesystem snapshot).
* Validates the snapshot (`validateDatasetSnapshot`).
* Compiles **every** `spec:*` record it finds.
* Writes:

  * `SyRS-*.md`, `SRS-*.md`, etc. at **repo root**
  * `OurBox-OS-Requirements-Omnibus.md` at **repo root**

Hard requirements:

* `docs/00-Glossary/Terms-and-Definitions.md` must exist or the build fails.
* `docs/architecture/Glossary.md` must exist or the build fails.
* `docs/architecture/AD-0001-ourbox-os-architecture-description.md` must exist or the build fails.

> Note: Generated files are listed in `.gitignore` — they are build artifacts, not committed to the repository.

### CI artifact: `requirements-artifacts`

CI publishes an artifact containing:

* one compiled Markdown file per spec (SyRS + each SRS)
* `OurBox-OS-Requirements-Omnibus.md` (which embeds the glossary, architecture glossary, and architecture description inline)
* `docs/00-Glossary/Terms-and-Definitions.md` (also included as a standalone file)
* `docs/architecture/Glossary.md` (also included as a standalone file)
* `docs/architecture/AD-0001-ourbox-os-architecture-description.md` (also included as a standalone file)

If CI is green, you can assume the compiled outputs are consistent with the GraphMD source.

---

## 4) Adding or editing a requirement (the common workflow)

### Step 0 — Pick the “home” spec and section

1. Decide which **spec** owns the requirement:

   * System-level norms → **SyRS** (e.g., `SyRS-0001`)
   * Gateway-specific → `SRS-0201`
   * Data/replication → `SRS-0202`
   * K8s/deployment → `SRS-0203`
   * App-specific → `SRS-1001`, `SRS-1002`, etc.
2. Decide the **section** it belongs in (or create a new section).

### Step 1 — Create (or locate) the parent section record

To create a new section:

* Create a directory `records/section.<RECORD_ID>/` containing `<RECORD_ID>.md`

* Set:

* `parent: "spec:<SPEC_ID>"`

* `fields.title`: the section heading text

* `fields.level`: heading depth offset (the compiler renders at `level + 1`, so `level: 1` → `##`)

* `fields.order`: numeric sort order (existing sections use sequential integers: 0, 1, 2, …)

> The compiler sorts sections by `fields.order` then by `recordId`.

**Template (SyRS section)**

```md
---
typeId: section
recordId: 5-verification
parent: "spec:SyRS-0001"
fields:
  title: "Verification"
  level: 1
  order: 5
---

Optional section narrative goes here.
Keep it short and stable; requirements live in child records.
```

**Template (SRS section)**

```md
---
typeId: section
recordId: SRS-0204-3-requirements
parent: "spec:SRS-0204"
fields:
  title: "Requirements"
  level: 1
  order: 3
---

Optional section narrative goes here.
```

> Notes:
>
> * SyRS sections use `<order>-<slug>` as their `recordId` (e.g., `1-application-requirements`).
> * SRS sections use `<SPEC_ID>-<order>-<slug>` (e.g., `SRS-0201-3-requirements`).
> * `recordId` must be **stable**, because child records refer to it via `parent`.

### Step 2 — Add the requirement record under that section

Create a directory `records/req.<RECORD_ID>/` containing `<RECORD_ID>.md` with:

* `recordId`: the requirement identifier (e.g., `APP-007`, `DATA-010`, `GW-004`)
* `parent`: `"section:<SECTION_RECORD_ID>"` (e.g., `"section:1-application-requirements"`)
* `fields.title`: short human-readable title (shown in headings)
* `fields.status`: `Draft`, etc.
* `fields.testable`: `true`/`false`
* `fields.area`: `app`, `data`, `gateway`, `k8s`, etc.
* `fields.rationale`: one sentence on "why"
* `fields.order`: numeric sort order within the section

**Template (requirement record)**

File: `records/req.APP-007/APP-007.md`

```md
---
typeId: req
recordId: APP-007
parent: "section:1-application-requirements"
fields:
  title: "Apps SHALL <do the thing>"
  status: "Draft"
  testable: true
  area: "app"
  rationale: "Short why statement that ties to an ADR/AD or system need."
  order: 7
---

Shipped OurBox apps SHALL ...
```

### Step 3 — Write the requirement body correctly

A good requirement body is:

* **Atomic:** one “thing” per requirement
* **Normative:** uses SHALL/SHALL NOT/SHOULD/…
* **Testable:** can be verified by test/analysis/inspection/demo (even if not implemented yet)
* **Unambiguous:** avoid “fast”, “easy”, “etc.”

Recommended pattern:

* **Subject** + **modal** + **verb** + **object** + **constraints**
* Include measurable qualifiers when relevant
* If you reference other records (`[[adr:...]]`, `[[arch_doc:...]]`, `[[spec:...]]`), you’re pulling them into the normative context—do that deliberately.

### Step 4 — Recompile and check the rendered output

Run:

```bash
npm test
```

Then inspect:

* the specific spec file (`SyRS-0001-*.md`, `SRS-0202-*.md`, etc.)
* `OurBox-OS-Requirements-Omnibus.md`

You should see:

* your new section heading (if you added one)
* your new requirement as a heading like:

  * `### APP-007: Apps SHALL <do the thing>`
* your metadata lines (`Status`, `Testable`, `Area`, `Rationale`) rendered under the requirement heading

### Step 5 — Commit only the source

Commit:

* the GraphMD record(s) you added/changed
* any referenced docs you created/updated (ADR, glossary, etc.)

Do **not** "fix" a generated file by editing it directly. Generated files (`SyRS-*.md`, `SRS-*.md`, `OurBox-OS-Requirements-Omnibus.md`) are listed in `.gitignore` so Git won't track them.

---

## 5) Adding a new spec (new SyRS or new SRS)

### What the compiler expects

A spec must be a GraphMD record with:

* `typeId === "spec"`
* `recordId` like `SyRS-0002` or `SRS-0204` etc.
* `fields.title` (used as the `# ...` heading)
* optional metadata fields:

  * `fields.version`
  * `fields.lastUpdated`
  * `fields.status`
* optional `body` (Markdown)

The compiler automatically includes **every** `spec` record it can find, so:

* adding a spec is “add records, rerun” (no CI edits)

### Spec file naming (important for stability)

Generated filename is:

```
<specId>-<slugified-title-without-leading-"<specId>: ">.md
```

Example:

* `recordId: "SRS-1002"`
* `fields.title: "SRS-1002: RichNote Software Requirements Specification"`
  → `SRS-1002-richnote-software-requirements-specification.md`

**Implication:** If you change the spec title, the generated filename can change.

* That’s okay, but be aware if other tooling/bookmarks depend on the exact filename.

### Recommended structure for a spec in this repo

To keep compiled sections in the right place, use this pattern:

* Keep the **spec record body** for short preamble only (or even empty).
* Put major headings (Normative Language, Introduction, Referenced Documents, requirement groupings, External Interfaces, Verification) into **section records** ordered with `fields.order`.

Why: the compiler appends section records *after* the spec body. If you put “Verification” in the spec body and later add requirement sections as records, they’ll show up *after verification*, which is backwards.

**Section order convention (matches existing SRS specs)**

* 0 — Normative Language
* 1 — Introduction
* 2 — Referenced Documents
* 3 — Requirements
* 4 — External Interfaces
* 5 — Verification

SyRS sections use a similar sequential scheme but with domain-specific groupings (Application Requirements, Data and Replication, etc.).

### Minimal spec record template

File: `records/spec.SRS-0204/SRS-0204.md`

```md
---
typeId: spec
recordId: SRS-0204
parent: doc_area:spec
fields:
  title: "SRS-0204: <Component> Software Requirements Specification"
  version: "0.1 (Draft)"
  lastUpdated: "YYYY-MM-DD"
  status: "Draft"
---

One-paragraph scope statement for this SRS.
(Everything else goes in section records.)
```

Then add section records under it:

File: `records/section.SRS-0204-1-introduction/SRS-0204-1-introduction.md`

```md
---
typeId: section
recordId: SRS-0204-1-introduction
parent: "spec:SRS-0204"
fields:
  title: "Introduction"
  level: 1
  order: 1
---

This SRS defines requirements for ...
```

And requirements under the appropriate sections.

---

## 6) Adding “new documents” (ADRs, Architecture Docs, ICDs, plans)

There are two supported patterns; use whichever matches how the repo currently models docs.

### Pattern A — Docs as Markdown under `docs/` (simplest)

1. Create the document file under a sensible `docs/...` folder.
2. Use stable IDs in filenames:

   * `docs/02-Architecture/AD-0002-<slug>.md`
   * `docs/03-Decisions/ADR-0005-<slug>.md`
3. Reference them from specs using:

   * a normal Markdown link, or
   * a GraphMD crossref if you also have a record (Pattern B).

### Pattern B — Docs as GraphMD records (best for crossrefs + indexing)

If the repo uses `[[adr:ADR-0001]]` / `[[arch_doc:AD-0001]]` as first-class GraphMD records, then:

1. Create a GraphMD record:

   * `typeId: adr` with `recordId: ADR-0005`, or
   * `typeId: arch_doc` with `recordId: AD-0002`
2. Put the document body in the record **or** store it in `docs/` and have the record point to it (repo convention).

**Template (ADR record, illustrative)**

```md
---
typeId: adr
recordId: ADR-0005
fields:
  title: "ADR-0005: <Decision Title>"
  status: "Proposed"
  lastUpdated: "YYYY-MM-DD"
---

## Context
...

## Decision
...

## Consequences
...
```

> Even if ADRs aren’t compiled into the requirements artifact today, having them as GraphMD records keeps crossrefs consistent and future-proofs indexing/search.

---

## 7) Conventions and quality bar

### IDs

* **Specs:** `SyRS-####`, `SRS-####`
* **Requirements:** `<AREA>-###` (examples already in use: `APP-001`, `DATA-001`, `GW-001`, `K8S-001`)
* Never reuse an ID for a different meaning.
* If a requirement is obsolete, prefer:

  * keep it and mark `status: Deprecated` (or similar), rather than deleting/renumbering.

### Ordering

* Use `fields.order` to control ordering.
* Existing records use sequential integers (0, 1, 2, …). You may use gaps (10, 20, 30…) if you anticipate frequent insertions, but keep it consistent within a spec.
* If `fields.order` is absent the compiler treats it as `0`.

### Requirement writing rules

* One requirement per record.
* Start the body with a single normative statement when possible.
* Avoid multiple SHALLs in one requirement unless they’re tightly coupled.
* If a requirement depends on an assumption, either:

  * state the assumption explicitly in the requirement body, or
  * reference an ADR/AD where it’s defined.

### Metadata expectations (minimum)

For every requirement record:

* `status`: `Draft` (at minimum)
* `testable`: `true` unless you have a clear reason it isn’t verifiable yet
* `area`: matches the owning subsystem/domain
* `rationale`: one sentence tied to architecture/decision/system need

### Glossary discipline

* If you introduce a new term or use a word in a specialized way, add it to:

  * `docs/00-Glossary/Terms-and-Definitions.md`
* Remember: this glossary is embedded into the omnibus and is part of the normative context.

---

## 8) Troubleshooting (what to check when something “doesn’t show up”)

### “My new spec didn’t compile”

* Confirm the spec record has `typeId: spec`.
* Confirm dataset validation passes (the compiler exits non-zero on validation errors).
* Confirm the record is in a scanned directory (`records/`, etc.).

### “My section/requirement didn’t render under the spec”

* Confirm `parent` is correct:

  * Section parent must be exactly: `spec:<SPEC_ID>`
  * Requirement parent must be exactly: `section:<SECTION_RECORD_ID>`
* Confirm you didn’t typo the parent string (case, punctuation, etc.).

### “Ordering is weird”

* Ensure `fields.order` is a number (or a numeric string).
* Remember sorting is:

  1. `order` ascending
  2. `recordId` ascending

### “The build fails saying Terms-and-Definitions is missing”

* The compiler requires:

  * `docs/00-Glossary/Terms-and-Definitions.md`
* Fix the file path or restore the file.

---

## 9) Optional improvements (if/when you want them)

Not required for day-to-day work, but worth knowing:

* **Placeholder injection:** modify the compiler to insert rendered sections at a marker like `<!-- SECTIONS -->` inside a spec body.
* **Nested sections:** modify the compiler to support sections under sections (true hierarchy).
* **RTM/VCD support:** add fields like `verifies`, `allocatedTo`, `derivedFrom`, and render them into output for traceability.

---
