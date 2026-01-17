# ADR-0001: Adopt Flatnotes for Notes

## Status
Accepted

## Context

OurBox OS requires a bundled **Notes** app (SPEC R8) that fits the platform posture:

- **Mobile-first, full-screen web UX** (SPEC R2)
- **Deployable as an independent Kubernetes service** (SPEC R5)
- **Local-first + privacy-first by default**, with data staying on the user's appliance (SPEC R9)
- **Authentication required for private apps/data**, supporting a single user or small trusted group (SPEC R10)

The Notes app is not meant to be "a full productivity suite." The target experience is closer to:
- a fast scratchpad
- a pastebin-like "transfer text between devices"
- a personal note list with simple search

We have already validated that Flatnotes matches the intended user workflow in real use: it is quick to capture notes, pleasant on mobile, and low-friction to run.

## Decision

We will adopt **Flatnotes** as the v0.1 bundled **Notes** app for OurBox OS.

Flatnotes will be packaged as a first-class OurBox app (a Kubernetes workload + persistent storage),
and exposed via a stable URL/route in the OurBox OS launcher model.

### Repository locations

This decision is recorded here:

- **Decision record (this file):**  
  `docs/decisions/ADR-0001-adopt-flatnotes-for-notes.md`

Related docs that should reference this decision:

- **App dossier:** `docs/apps/notes/README.md` (update Status to **Selected** and list Flatnotes as the pick)
- **App suite matrix:** `docs/apps/app-suite.md` (update Notes row candidate/pick)
- Optional but recommended: create a candidate evaluation doc at  
  `docs/apps/notes/candidates/flatnotes.md` (so the dossier has a durable "why" summary close to the app)

### Physical locations (runtime)

**On the appliance (persistent data):**
- Flatnotes must use a Kubernetes **PersistentVolumeClaim** so notes survive pod restarts and upgrades.
- Notes are stored as plain **Markdown files** in the mounted data directory.
- Standardize an OurBox OS path convention for app data. Proposed baseline:
  - Host path / storage target: `/var/lib/ourbox/apps/notes/` (or a storage-class-backed equivalent)
  - Mounted into the container at: `/data`

**In Kubernetes (logical placement):**
- Namespace: `ourbox-notes` (or `ourbox-apps` with a clear label set)
- Workload: a single Deployment is sufficient for v0.1
- Service exposure: via the OurBox ingress/reverse proxy under a stable route (e.g., `/notes`)

**Authentication:**
- v0.1 may use Flatnotes' built-in password auth or proxy-layer auth (whichever is simpler to operate).
- Longer-term, Notes should integrate with the shared OurBox identity/session model (SPEC R10).

## Rationale

Flatnotes is selected because it matches the non-negotiable product posture:

- **Simple and flat:** intentionally minimal UX with low cognitive overhead.
- **Web-first and mobile-friendly:** works well from a phone browser in a "quick capture" mode.
- **Local-first data model:** notes are persisted on the appliance; file-based storage is easy to back up,
  export, and migrate.
- **Operational simplicity:** can run as a single service with persistent storage and minimal dependencies.
- **Fast path to shipping:** we can provide a solid Notes experience early without blocking on heavier
  platform decisions.

This selection prioritizes "works reliably with minimal friction" over maximum features.

## Consequences

### Positive
- Notes app can ship early as a reliable baseline.
- Minimal operational burden on the appliance (good for small always-on devices).
- Data remains user-controlled and straightforward to back up/export.

### Negative
- Flatnotes is intentionally not a full "knowledge base" system (limited structure/hierarchy).
- Attachments support is not a substitute for a general file shelf or file transfer tool.
- Does not, by itself, solve cross-device offline capture without additional platform work.

### Mitigation
- Provide a separate minimal **Files/Drop** app for file transfer (see ADR-0002).
- Define an OurBox backup/export UX that works consistently across apps (snapshots + download).
- Treat Notes as a fast "inbox" by default; offer organization via tags/naming conventions.

## References
- `SPEC.md` (R2, R5, R8, R9, R10)
- `docs/apps/notes/README.md`
- `docs/apps/app-suite.md`
- ADR-0002: Adopt Dufs for Files (paired capability)
