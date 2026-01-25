# ADR-0003: Purpose-build Offline‑First PWAs for All Shipped OurBox Apps

## Status
Accepted (Updated)

## Date
2026-01-25

## Context

OurBox OS is explicitly browser-first to break App Store chokeholds and keep the system local-first.
The core UX target is:

- **Mobile-first** (works beautifully on a phone)
- **Offline-capable after first load** (keeps working from browser cache)
- **Sporadic sync** with OurBox (works on unreliable home Wi‑Fi; syncs when it can)
- **Local-first** as architecture, not a policy promise

Most existing “self-hosted apps” do not fit this posture:

- Many are not real PWAs (or treat PWA as a skin, not an offline-capable application).
- Many assume constant connectivity and fail hard offline.
- Many require native clients for a good mobile experience.
- Many ship UI/UX built for desktop admin panels, not phone-first everyday use.
- Many were not designed around cache-first behavior and local persistence.

We choose not to wrap or embed existing upstream tools, because “bolt-on offline” is usually incomplete,
brittle, expensive to maintain, and a poor UX.

We also maintain the **Operator Truth** posture: the device operator can access anything on the box,
and may be able to exfiltrate data from a client’s browser cache. Our security and privacy posture is
built around ownership and local control, not trustless hosting.

### Critical architectural constraint: shared tenant origin + shared local replica

OurBox encodes `tenant_id` into the hostname so that each tenant is a distinct **web origin**
(`origin = scheme + host + port`). Example tenant origins:

- `https://bob.<box-host>/...`
- `https://alice.<box-host>/...`

Within a given **tenant origin** on a given client device, shipped apps share a single local working
database in the browser (PouchDB backed by IndexedDB) and replicate with the tenant’s CouchDB database
on the box (see ADR-0004).

**Implication:** within a tenant origin, any JavaScript running in that origin can technically read
and write any documents in the tenant’s local working store (and may sync those changes back to the
box). Therefore, “app boundaries” are not a cryptographic or sandboxed isolation boundary in this
posture. Preventing accidental cross-doc-kind writes is an engineering discipline enforced by shared
libraries, conventions, and automated testing — not by permission prompts between shipped apps.

This ADR is paired with:
- ADR-0004 (CouchDB + PouchDB, tenant DBs, partitioned DB usage, local-first replication posture)
- ADR-0005 (tenant vocabulary and boundary semantics)
- ADR-0006 (OurBox document IDs)

## Decision

Being open source software, OS, and hardware, customers can build apps however they want, but OurBox OS
provides an opinionated (non-normative for third parties) stance for shipped apps:

We will **purpose-build example OurBox OS apps** as **offline-first Progressive Web Apps** designed
from the beginning to:

1) **Run from browser cache after first successful load**
   - installable PWA (service worker + offline assets)
   - resilient UI even when OurBox is unreachable (subject to browser/OS eviction)

2) **Persist working data locally**
   - local working data is stored in the browser via IndexedDB
   - shipped apps use PouchDB as the default local store (ADR-0004)

3) **Sync opportunistically**
   - sync is incremental and resumable
   - we try to sync whenever we can, within reasonable performance/bandwidth constraints
   - sync tolerates intermittent connectivity
   - shipped apps replicate with CouchDB on the box (ADR-0004)

4) **Operate within a tenant**
   - apps operate on a tenant-selected **tenant origin** (e.g., `https://bob.<box-host>/...`)
   - apps sync with the tenant’s **tenant DB** on the box (ADR-0004)
   - tenant context is derived from the hostname and enforced by the gateway/platform (ADR-0005)

5) **Remain product-coherent and blast-radius-aware**
   - shipped apps are views over tenant data, not silos
   - within a tenant origin, shipped apps share one local tenant replica on that device (ADR-0004),
     so apps can read the same documents offline without bothering the user
     - example: SimpleNote and RichNote both operate on the same `note:*` documents
   - app boundaries are not treated as a security boundary inside the browser:
     - within a tenant origin, any code can technically read/write any doc kinds
     - therefore, “this app does not write that doc kind” is enforced as engineering policy
       (discipline + tests), not via user permission prompts between shipped apps
   - shipped apps MUST adhere to stable doc-kind contracts (ADR-0004, ADR-0006):
     - doc kinds are encoded in `_id` as CouchDB partitions
     - doc kind vocabulary is intentionally stable
   - shipped apps SHOULD minimize unintended coupling by treating doc kinds as shared contracts,
     and by keeping cross-doc-kind behavior explicit (not “hidden writes”)

6) **Every shipped app must support offline writes for its doc kinds on day one**
   - if we can’t make the app’s core doc kinds work offline (create/update/delete),
     we don’t ship it

This ADR defines the posture for shipped first-party OurBox apps.

## Rationale

- App Store avoidance requires browser-first excellence. If the PWA experience is second-rate,
  users fall back to native apps and the gatekeepers win.
- Offline-first must be architectural. Retrofitting offline behavior onto server-rendered UIs or
  online-only web apps is unreliable and creates endless edge-case debt.
- Home networks are messy. People’s Wi‑Fi drops. Routers reboot. Phones roam between networks.
  OurBox apps must feel stable anyway.
- Consistency across the suite matters. A unified offline-first posture makes OurBox OS feel like a
  coherent product instead of a dashboard of unrelated tools.
- Sharing a tenant-local working store enables multi-app composition offline (e.g., two notes apps
  seeing the same notes on one device without extra user steps).

## Consequences

### Positive
- OurBox shipped apps remain usable during network outages and poor connectivity.
- Strong mobile UX becomes a core competency, not a bolt-on.
- OurBox OS avoids dependency on App Store distribution and native clients.
- A consistent offline-first architecture improves long-term maintainability.
- Multiple shipped apps can operate on the same doc kinds offline within a tenant origin
  (e.g., SimpleNote + RichNote share `note:*`) without requiring user permissions between apps.

### Negative
- Higher initial engineering cost: we are building more ourselves.
- Offline-first implies conflict handling and sync complexity for some doc kinds.
- **Shared-store blast radius:** because shipped apps share a tenant-local working store per tenant origin,
  a bug in one shipped app can corrupt tenant-wide data and sync that corruption back to the box.
  This is a reliability risk that must be managed via discipline and testing (not by relying on
  app sandboxing).

### Mitigation
- Start small: ship minimal, high-value workflows first (notes, tasks, files, messaging basics).
- Adopt strict data modeling rules upfront (ADR-0004, ADR-0006) to reduce conflicts and replication cost.
- Treat doc kinds as stable shared contracts and keep coupling explicit.
- Enforce “write hygiene” for shipped apps:
  - shipped apps SHOULD declare (in app metadata/manifest) which doc kinds they are intended to write
  - shared libraries SHOULD include runtime assertions/guards to prevent accidental writes outside intended doc kinds
  - CI SHOULD include unit + integration tests that detect cross-doc-kind writes and fail builds when they occur

## References
- `docs/policies/founding/VALUES.md` (local-first, user sovereignty, no lock-in)
- `docs/policies/founding/CONSTITUTION.md` (local-first forever; no hostage mechanics)
- ADR-0004: Adopt CouchDB + PouchDB and Standardize OurBox Data Modeling (Tenant DBs + Partitions)
- ADR-0005: Standardize on Tenant as the OurBox OS Data Boundary Term
- ADR-0006: OurBox Document IDs
- `docs/architecture/OurBox-OS-Terms-and-Definitions.md`
