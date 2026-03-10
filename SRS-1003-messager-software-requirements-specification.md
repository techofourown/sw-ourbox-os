# SRS-1003: Messager Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-02-25
**Status:** Draft

This specification defines the software requirements for the **Messager** application.

Messager is a shipped, tenant-scoped messaging experience for OurBox OS. It is designed for multi-user
communication within a tenant without introducing “private compartments” inside the tenant boundary,
aligning with the principle that the tenant is the social boundary.

## Normative Language

The key words **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, and **MAY** are to be interpreted as
requirements.

OurBox OS vocabulary and normative definitions are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

## Introduction

This SRS defines requirements for the **Messager** app experience.

Scope includes:
- tenant-scoped channels and messages
- offline-first behavior consistent with ADR-0001 posture
- shared local tenant replica usage (`tenant_local`)
- message document model and attachment handling using the tenant blob store
- optional voice/video calls within the tenant boundary
- optional bot/automation behavior within tenant membership semantics

Out of scope:
- interoperability with external messaging ecosystems (e.g., SMS, email, Matrix, ActivityPub)
- privacy compartments inside a tenant (DMs, secret channels) — use separate tenants instead

## Referenced Documents

- `docs/00-Glossary/Terms-and-Definitions.md`
- [[spec:SyRS-0001]]
- [[arch_doc:AD-0001]]
- [[adr:ADR-0001]]
- [[adr:ADR-0002]]
- [[adr:ADR-0003]]
- [[adr:ADR-0004]]
- [[adr:ADR-0005]]
- [[adr:ADR-0006]]
- [[spec:SRS-0201]]
- [[spec:SRS-0204]]
- [[spec:SRS-0205]]
- [[spec:SRS-0206]]

## Requirements

Allocated system requirements from `[[spec:SyRS-0001]]` are included here for traceability; Messager-specific requirements follow.

### Allocated System Requirements (from SyRS)

#### APP-001: Shipped apps SHALL provide full installable-PWA posture in public custom-domain mode

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Aligns shipped-app installability guarantees with mode-specific browser behavior.

In public custom-domain mode, shipped OurBox apps SHALL be installable PWAs that can load from cache after the first successful online session.

#### APP-002: Shipped apps SHALL persist working data locally

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Offline writes depend on local persistence.

Shipped apps SHALL store working data locally in the tenant origin using PouchDB-backed IndexedDB.

#### APP-003: Shipped apps SHALL sync opportunistically

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Supports sporadic connectivity while keeping data consistent.

Shipped apps SHALL initiate incremental replication with the tenant DB when connectivity is available.

#### APP-004: Apps SHALL operate within a mode-aware tenant origin

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Tenant origins define storage isolation and routing in both access modes.

Shipped apps SHALL be served under mode-aware tenant origins:
- local-only mode: `http://<tenant_id>.local/<app_slug>`
- public custom-domain mode: `https://<tenant_id>.<box-host>/<app_slug>`

Tenant context SHALL be derived from the full host; `tenant_id` is the leftmost DNS label.

#### APP-005: Apps SHALL share one local tenant replica per origin

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Ensures apps share doc kinds offline.

All shipped apps under the same tenant origin SHALL read and write through a single local tenant
replica database on that device.

#### APP-006: Apps SHALL honor doc-kind contracts

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Shared storage requires strict doc-kind boundaries.

Shipped apps SHALL only create and update documents whose `_id` prefixes match the stable doc-kind
vocabulary defined for OurBox OS.

#### APP-007: Local-only mode SHALL be HTTP-only

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Local-only mode is designed for HTTP-only access on `.local` routes without TLS requirements.

Local-only mode SHALL use `http://<tenant_id>.local/<app_slug>` and SHALL NOT require or imply HTTPS/TLS for app access in that mode.

#### APP-008: Local-only mode documentation SHALL NOT promise public-mode-equivalent full PWA posture

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Product and app documentation must accurately describe local-only browser capability limits versus public custom-domain mode.

Local-only mode SHALL NOT be documented as guaranteeing installability or reopen-offline behavior equivalent to public custom-domain mode.

### Functional and Data Requirements (Messager-specific)

#### MSG-001: Messager SHALL treat the tenant as the social boundary

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Avoid private compartments; tenant is the unit of social trust.

Messager SHALL treat the tenant boundary as the only privacy/social boundary.

All tenant members with `messager:read` capability SHALL be able to read all messages in the tenant.

If users require a private compartment, they SHALL create a separate tenant instead of creating DMs inside a tenant.

#### MSG-002: Messager SHALL NOT implement private compartments within a tenant

**Status:** Draft  
**Testable:** true  
**Area:** security  
**Rationale:** Private compartments inside a tenant are confusing and dangerous; use tenants instead.

Messager SHALL NOT implement:
- direct/private messages scoped to a subset of tenant members,
- “secret” channels with per-channel membership ACLs,
- per-message encryption keys that exclude some tenant members.

Any feature that materially restricts message visibility MUST be implemented by using a separate tenant.

#### MSG-003: Messager SHALL operate within a tenant origin

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Tenant origins define storage isolation and routing (AD-0001).

Messager SHALL be served under tenant-origin mode-aware routes (`http://<tenant_id>.local/messager` and `https://<tenant_id>.<box-host>/messager`) and SHALL derive tenant context from the full host (leftmost DNS label = `tenant_id`).

#### MSG-004: Messager SHALL use the shared local tenant replica

**Status:** Draft  
**Testable:** true  
**Area:** app  
**Rationale:** Shared local tenant replica is required for offline-first behavior and cross-app doc sharing (SyRS APP-005).

Messager SHALL read and write its documents through the shared local tenant replica `tenant_local` within the tenant origin.

#### MSG-005: Messager SHALL provide tenant-wide channels

**Status:** Draft  
**Testable:** true  
**Area:** messaging  
**Rationale:** Provide organization without introducing private compartments.

Messager SHALL provide one or more tenant-wide message channels.

Channel membership SHALL NOT be restricted within the tenant.

Messager SHALL provide a default channel (e.g., `general`).

#### MSG-006: Messager SHALL support real-time-ish updates via replication

**Status:** Draft  
**Testable:** true  
**Area:** messaging  
**Rationale:** Leverages CouchDB/PouchDB replication for incremental updates without custom protocols.

Messager SHOULD use live/continuous replication (or periodic incremental replication) to deliver near-real-time updates when the box is reachable.

Messager SHALL remain functional when the box is unreachable after first load.

#### MSG-007: Messager SHALL support end-to-end offline messaging

**Status:** Draft  
**Testable:** true  
**Area:** offline  
**Rationale:** Offline-first posture: messages must be creatable and viewable without connectivity.

Messages composed offline SHALL be persisted locally immediately and appear in the UI.

When connectivity returns, messages SHALL replicate automatically to the tenant DB via `/db` without user intervention.

#### MSG-008: Messager SHALL support file and media attachments

**Status:** Draft  
**Testable:** true  
**Area:** messaging  
**Rationale:** Messaging commonly includes images/audio/files; blob store is the canonical posture.

Messager SHALL support attaching files/media to messages.

Attachment metadata (filename, MIME type, size, and blob reference) SHALL be stored in message documents.

Attachment payload bytes SHALL be stored in the tenant blob store by default (see MSG-009).

#### MSG-009: Messager SHALL store attachment payload bytes in the tenant blob store by default

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Align with ADR-0002/ADR-0005 posture: blobs outside CouchDB, content-addressed, tenant-scoped.

Messager SHALL NOT store attachment payload bytes as CouchDB attachments by default.

Instead, Messager SHALL store attachment payload bytes in the tenant blob store and store only content-addressed references (e.g., multihash/CID) in message documents.

**Trace:** [[spec:SyRS-0001]] DATA-006, DATA-007; [[adr:ADR-0005]]; [[adr:ADR-0006]].

#### MSG-010: Messager SHOULD support offline staging of attachments

**Status:** Draft  
**Testable:** false  
**Area:** offline  
**Rationale:** Improves usability on unstable networks; staging may be complex due to blob-store APIs.

Messager SHOULD allow users to attach files while offline by staging payload bytes locally and uploading them to the tenant blob store when connectivity returns.

If offline staging is not supported, Messager SHALL communicate clearly that attachments require connectivity.

#### MSG-011: Messager SHALL support voice notes

**Status:** Draft  
**Testable:** true  
**Area:** messaging  
**Rationale:** Voice notes are a common low-friction messaging primitive.

Messager SHALL allow users to record and send voice notes.

Voice note audio payload bytes SHALL be stored as blobs in the tenant blob store, referenced from a message document.

#### MSG-012: Messager SHALL support sharing existing tenant documents by reference

**Status:** Draft  
**Testable:** true  
**Area:** integration  
**Rationale:** Apps share one local tenant replica; sharing should be references, not copies.

Messager SHALL allow messages to reference existing tenant documents by `_id`.

Example: a message may reference a `note:*` document or a `task:*` document.

Messager SHALL NOT duplicate the referenced document as a message payload.

#### MSG-013: Messager SHALL define messaging doc kinds and commit to stable doc-kind vocabulary tokens

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Shared storage requires stable doc kinds and clear contracts (AD-0001 §9.2).

Messager SHALL store its primary documents using doc kinds encoded in `_id`.

Messager SHALL introduce the following doc kinds (stable vocabulary tokens):
- `thread` — channel/thread metadata
- `msg` — message documents
- `call` — call history documents

Each doc kind SHALL be documented with:
- required and optional fields,
- indexing/query posture,
- conflict handling posture.

**Trace:** [[arch_doc:AD-0001]] §9.2 (Adding a new doc kind).

#### MSG-014: Messager message documents SHALL be immutable after creation

**Status:** Draft  
**Testable:** true  
**Area:** data  
**Rationale:** Append-only messaging avoids conflicts and reduces complexity.

After a `msg:*` document is created, Messager SHALL treat it as immutable.

Edits and deletions of messages SHOULD NOT be supported in the v0 posture.

If redaction/moderation is required in future, it SHALL be implemented via additional documents (not in-place mutation).

#### MSG-015: Messager SHALL provide deterministic message ordering

**Status:** Draft  
**Testable:** true  
**Area:** messaging  
**Rationale:** Replication and intermittent connectivity require stable ordering for rendering.

Messager SHALL render messages in a deterministic order.

Recommended ordering (normative):
1) `created_at` timestamp ascending,
2) tie-break by `_id` ascending.

Messager SHALL tolerate clock skew across devices by not assuming timestamps are globally accurate.

#### MSG-016: Messager SHALL support voice and video calls between tenant members

**Status:** Draft  
**Testable:** true  
**Area:** calling  
**Rationale:** Calls are a canonical “phone-like OS” primitive; tenant boundary keeps it legible.

Messager SHALL support initiating and receiving real-time voice and video calls between tenant members.

Call participation SHALL be limited to tenant members (per membership enforced by the Gateway).

#### MSG-017: Messager call signaling SHALL be same-origin with the tenant

**Status:** Draft  
**Testable:** true  
**Area:** calling  
**Rationale:** Avoid CORS/topology coupling; align with tenant-origin routing posture.

Call signaling (offer/answer/ICE exchange) SHALL occur over a tenant-origin surface:
- local-only mode: `http://<tenant_id>.local/api/messager/call/...`
- public custom-domain mode: `https://<tenant_id>.<box-host>/api/messager/call/...`

The Gateway SHALL enforce tenant membership on signaling endpoints.

(Exact signaling protocol is out of scope; WebRTC is assumed.)

#### MSG-018: Messager SHALL record durable call history in the tenant DB

**Status:** Draft  
**Testable:** true  
**Area:** calling  
**Rationale:** Call history is user-visible state and must replicate across devices.

Messager SHALL record call events (missed/received/placed, participants, start/end times) as durable documents in the tenant DB (doc kind `call`).

Call history SHALL be visible to all tenant members with `messager:read` capability.

#### MSG-019: Messager SHALL support bots as ordinary users

**Status:** Draft  
**Testable:** true  
**Area:** automation  
**Rationale:** Bots should be legible: they are users with memberships/capabilities.

Messager SHALL support bot accounts implemented as ordinary `user_id` identities with tenant membership.

Bots SHALL NOT bypass tenant membership enforcement.

Bots MAY post messages and attachments subject to the same capability checks as humans.

#### MSG-020: Messager SHALL NOT require external messaging networks or federation

**Status:** Draft  
**Testable:** true  
**Area:** constraint  
**Rationale:** Explicit product posture: no external interop requirement; keep implementation small and legible.

Messager SHALL NOT require interoperability with external messaging ecosystems.

Messager SHALL NOT implement federated identity, cross-instance message routing, or third-party network bridges in the v0 posture.

#### MSG-021: Messager SHOULD provide a tenant-scoped encryption mode without creating intra-tenant compartments

**Status:** Draft  
**Testable:** false  
**Area:** security  
**Rationale:** Encryption is desirable, but must not create intra-tenant compartments; operator truth still applies.

Messager SHOULD provide an encryption mode where message payloads are encrypted at rest in the tenant DB/blob store.

If implemented, encryption keys SHALL be tenant-scoped and available to all tenant members (subject to membership), not per-channel or per-DM.

This feature SHALL NOT claim confidentiality from the device operator (Operator Truth).

#### MSG-022: Messager SHOULD minimize client resource footprint

**Status:** Draft  
**Testable:** false  
**Area:** quality  
**Rationale:** Align with “low profile code” posture: minimal RAM/CPU and small bundle size.

Messager SHOULD minimize client resource usage by:
- using pagination/virtualized lists for long timelines,
- avoiding loading unbounded message history into memory,
- limiting background timers and watchers,
- keeping client bundle size small.

Resource budgets (exact numbers) are defined in performance test baselines, not in this SRS.

## External Interfaces

Messager external interfaces are tenant-origin app/replication surfaces in both access modes.

- App route (local-only mode): `http://<tenant_id>.local/messager`
- App route (public custom-domain mode): `https://<tenant_id>.<box-host>/messager`
- Replication endpoint (local-only mode): `http://<tenant_id>.local/db`
- Replication endpoint (public custom-domain mode): `https://<tenant_id>.<box-host>/db`
- Local storage: shared local tenant replica `tenant_local` within the current tenant origin
- Attachments: tenant blob store (accessed via platform services / gateway-mediated APIs when present)

Public custom-domain mode is the full installable-PWA posture. Local-only mode remains HTTP local mode with local data continuity and opportunistic sync, without equivalent full installability/reopen-offline guarantees.

## Verification

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:
- **Test:** offline send/receive behavior using the local tenant replica; then reconnect and replicate successfully.
- **Inspection:** confirm no DM/private-channel UI or enforcement exists within a tenant.
- **Test:** attachment upload/download round-trip with blob references in message docs.
- **Test (optional):** voice/video call signaling and call-history persistence.
