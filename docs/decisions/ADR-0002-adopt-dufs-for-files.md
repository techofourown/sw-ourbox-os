# ADR-0002: Adopt Dufs for Files

## Status
Accepted

## Context

OurBox OS needs a minimal, web-first way to move files between devices that fits the product posture:

- **Mobile-first, full-screen web UX** (SPEC R2)
- **Independently deployable as a Kubernetes service** (SPEC R5)
- **User-owned storage by default** with low tracking surface (SPEC R9)
- **Authentication required** for private apps/data (SPEC R10)

The desired user experience is explicitly not "Dropbox/Drive replacement."
We want something closer to:

- a flat "file shelf"
- a simple upload/download landing page
- a place where files are visible and persistent on the appliance

This complements the Notes experience: Flatnotes handles text well; we need the same "it is just there"
simplicity for files.

## Decision

We will adopt **Dufs** as the v0.1 bundled **Files** app (also referred to as "Drop" or "File Shelf")
for OurBox OS.

Dufs will provide a simple web UI for browsing and uploading files into a single backing directory
(or a small set of directories) on the appliance.

### Repository locations

This decision is recorded here:

- **Decision record (this file):**  
  `docs/decisions/ADR-0002-adopt-dufs-for-files.md`

Related docs that should reference this decision:

- Add an app dossier for Files:
  - `docs/apps/files/README.md` (new)
- Add/update the app suite matrix:
  - `docs/apps/app-suite.md` (add a **Files** row and mark Dufs as the pick)
- Optional but recommended: create a candidate evaluation doc at
  - `docs/apps/files/candidates/dufs.md`

### Physical locations (runtime)

**On the appliance (persistent data):**
- Dufs must use a Kubernetes **PersistentVolumeClaim** so files survive restarts and upgrades.
- Standardize an OurBox OS path convention for app data. Proposed baseline:
  - Host path / storage target: `/var/lib/ourbox/apps/files/`
  - Mounted into the container at: `/data`

**In Kubernetes (logical placement):**
- Namespace: `ourbox-files` (or `ourbox-apps` with clear labels)
- Workload: a single Deployment is sufficient for v0.1
- Service exposure: via the OurBox ingress/reverse proxy under a stable route (e.g., `/files`)

**Authentication and safety posture:**
- Require authentication (proxy-layer auth or Dufs auth).
- v0.1 should default to conservative permissions:
  - allow upload + download
  - consider disabling delete unless explicitly enabled

## Rationale

Dufs is selected because it matches the "minimal + flat + works" requirement:

- **Minimal mental model:** it is effectively "a web UI for a directory."
- **Low operational complexity:** can run as a single service with a mounted data directory.
- **Good fit for an appliance:** lightweight enough for small always-on hardware.
- **Complements Notes cleanly:** it becomes "Flatnotes, but for files" without dragging in a
  full sync platform.

This selection intentionally prioritizes reliability and simplicity over advanced collaboration,
sync, or sharing workflows.

## Consequences

### Positive
- Provides a clean, understandable file transfer/shelf feature for users without extra clients.
- Very low footprint and low administrative overhead.
- Files remain on the appliance in a straightforward directory suitable for backups.

### Negative
- Not a sync solution; does not manage multi-device state beyond "upload/download."
- Limited per-file sharing semantics compared to full platforms.
- Requires careful defaults to avoid becoming an accidental "public upload box" if misconfigured.

### Mitigation
- Enforce authenticated access by default (SPEC R10).
- Provide clear configuration knobs in OurBox OS UI (upload limits, delete allowed, max storage).
- Ship with safe defaults and explicit warnings when enabling risky features.

## References
- `SPEC.md` (R2, R5, R9, R10)
- `docs/apps/app-suite.md`
- ADR-0001: Adopt Flatnotes for Notes (paired capability)
