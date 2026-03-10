# Generated Requirements Artifacts

This directory contains generated requirements outputs.

These files are build artifacts. They are **not** authoritative source.

## Source of truth

Authoritative source content lives in:

- `records/`
- `types/`
- `docs/`

The requirements toolchain that generates this directory lives in:

- `tools/requirements/`

## What belongs here

This directory is the canonical location for generated requirements outputs such as:

- one compiled Markdown file per spec,
- the omnibus requirements document.

Examples:
- `SyRS-0001-*.md`
- `SRS-0201-*.md`
- `generated/requirements/OurBox-OS-Requirements-Omnibus.md`

## What does not belong here

Do not place source records here.

Do not hand-edit generated files here.

Do not treat these files as the source of truth for requirements editing.

## Build rule

To regenerate these outputs, use the repo’s requirements toolchain and package scripts.

The repo root must remain free of generated compiled requirement artifacts.

That is the purpose of this directory.
