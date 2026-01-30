# ADR-0005: Store blobs in a content-addressed blob store keyed by a canonical multihash key (no chunking)

## Status

Accepted

## Date

2026-01-29

## Deciders

Founder (initial); future Board + Members (ratification/amendment per `docs/policies/founding/CONSTITUTION.md`)

## Context

OurBox OS is an offline-first, browser-first system (ADR-0001) built on CouchDB (box) + PouchDB (browser) replication (ADR-0002). Tenant databases are the replication unit and are partitioned by doc kind (ADR-0002, ADR-0004). Tenant context is derived from hostname and enforced by the gateway (ADR-0003, AD-0001).

We have committed to the posture that **large blobs SHALL NOT be stored as CouchDB attachments by default** (ADR-0002 Rule 9; SyRS-0001 DATA-006). That pushes us toward a tenant blob store for large binary content (photos, audio, video, etc.) with documents storing references.

We need a canonical, stable way for OurBox application documents to reference blob content stored outside CouchDB that supports:

* **file-level deduplication within a tenant blob store** (same bytes should not be stored twice within that tenant's blob store),
* **end-to-end integrity** (the system can verify bytes are exactly what was referenced),
* and **simple, legible identifiers** that are safe to move around between components and devices.

We also need an internal blob-store key that is deterministic and stable for storage addressing, independent of any particular human-readable CID text representation.

Constraints and non-goals:

* OurBox is **not competing with Netflix**, and is **not trying to become a personal media server** (Jellyfin/Plex-like behavior is not a product requirement).
* Multi‑gigabyte uploads are **not expected to be a common or latency-sensitive steady-state workflow**.
* In poor connectivity situations, OurBox does **not** need to “heroically continue making progress”; it is acceptable to **retry later** when connectivity improves (offline-first posture).
* **Per-piece integrity guarantees** are not required when end-to-end integrity (hash check) is sufficient.
* **Partial/intra-file deduplication** is not required (no expectation of many large files sharing most content).
* Therefore, chunking, Merkle DAGs, and resumable-by-piece transfer are **not required** to satisfy OurBox’s goals.

## Decision

### 1) Blob identity is a CID string (content-addressed identity)

OurBox OS SHALL treat blob identity as a **content-derived CID string**.

* A blob’s identifier is computed from its bytes.
* If two blobs have identical bytes, they SHALL have the same CID.
* Blobs are immutable by identity: changing bytes results in a new CID.

This CID string is the identifier used in application documents, APIs, logs, and debugging.

### 2) Canonical CID profile for OurBox blobs

OurBox blob CIDs SHALL use the following profile:

* **CID version:** CIDv1
* **String encoding:** base32 lowercase (CIDv1 string form, multibase `b` prefix)
* **Multicodec:** `raw` (the CID commits directly to raw bytes)
* **Multihash:** `sha2-256` with 32-byte digest

A blob CID SHALL be computed as the CIDv1 of the SHA‑256 digest of the blob’s raw bytes (no decoding, no normalization).

Implementations that *produce* CIDs for OurBox-managed blobs SHALL produce canonical CID strings in this profile.

### 3) No chunking or Merkle DAG

OurBox OS SHALL NOT require chunking of blobs.

* A blob is stored as one contiguous byte sequence.
* The CID is computed over the entire blob bytes.
* OurBox SHALL NOT represent blobs as Merkle DAGs for storage or identity.
* OurBox SHALL NOT require piecewise verification, partial/intra-file dedupe, or resumable block transfer semantics.

### 4) Blob store key is a canonical base32 string derived from multihash bytes

The OurBox blob/file store SHALL be content-addressed and SHALL be keyed by a canonical string derived from the CID’s **multihash bytes** (hash function code + digest length + digest), not by the human-readable CID string itself.

Define the **Blob Key** as follows:

#### Deriving a Blob Key

To derive a Blob Key:

1. Accept a CID (bytes or string form).
2. Decode the CID and extract its **multihash bytes** (the complete multihash byte sequence contained in the CID).
3. Base32-encode the multihash bytes using the RFC 4648 base32 alphabet.
4. The base32 output MUST be **unpadded** (MUST NOT contain `=` padding).
5. The base32 output MUST be canonicalized to **uppercase ASCII** (`A–Z` and `2–7`).
6. The base32 output MUST NOT include any multibase prefix (it is a plain base32 string).
7. Return the resulting string as the Blob Key.

**Normative note:** The Blob Key is derived from multihash bytes so that storage addressing is stable and deterministic for a given content digest, independent of the CID’s textual form.

### 5) Blob store invariants (CAS semantics)

The OurBox **tenant blob store** SHALL act as a content-addressed store keyed by **Blob Key**:

1. **Idempotent put**

   * Storing bytes whose Blob Key already exists SHALL succeed without creating duplicates within that tenant's blob store.

2. **Verifiable persistence**

   * Implementations SHALL be able to verify stored bytes match the referenced CID by recomputing the digest and comparing to the CID.
   * Implementations SHALL be able to verify that stored bytes correspond to the referenced Blob Key by recomputing the multihash bytes and Blob Key.

3. **Immutability by address**

   * Implementations SHALL NOT support “updating” blob bytes in place under an existing Blob Key.
   * Replacements are represented as new blobs with new CIDs (and therefore new Blob Keys), and documents may update their references accordingly.

### 6) Documents reference blobs by CID; bytes remain outside CouchDB by default

In alignment with ADR-0002 / SyRS DATA-006:

* Application documents reference blobs using CID strings.
* Blob bytes SHALL be stored outside CouchDB by default.
* CouchDB documents store metadata and references; the blob/file store stores bytes.

Documents and schemas SHALL treat the CID as the authoritative blob reference. The Blob Key is derived from the CID and does not need to be stored in documents.

### 7) Tenant-scoped access posture

Blob access SHALL be evaluated in **tenant context** derived from hostname (ADR-0003, AD-0001).

* CIDs and Blob Keys are identifiers for integrity/dedupe and SHALL NOT be treated as secrets or access tokens.
* Authorization remains a gateway/platform responsibility, consistent with the OurBox posture that tenant membership gates access.
* Blob payload bytes are stored in the tenant blob store under a tenant-scoped storage root (ADR-0006).

## Rationale

* The primary goal for blob identity is **file-level deduplication and end-to-end integrity**. A CID computed from the full blob bytes provides exactly that.
* A separate canonical **Blob Key** derived from the CID’s multihash bytes provides a deterministic, storage-friendly key that is independent of the CID’s string representation.
* Operational simplicity is preserved: store a blob as one contiguous object; serve it as a stream.
* Chunking and Merkle DAGs add substantial complexity without being required for OurBox’s needs.

## Consequences

### Positive

* **File-level dedupe** is automatic: identical blob bytes yield identical CIDs (and identical Blob Keys).
* **End-to-end integrity** is straightforward: recompute hash and compare to CID.
* **Stable storage keying**: the Blob Key is deterministic and canonical for storage addressing.
* **Clear separation of concerns**:

  * CouchDB/PouchDB replication handles documents and offline-first app state.
  * The blob store handles large bytes outside CouchDB by default.

### Negative

* **No piecewise resume/progress:** failed transfers may restart from the beginning rather than resuming mid-stream.
* **No partial/intra-file dedupe:** two similar large files do not share storage unless their full bytes match.
* **Not an IPFS “file CID” model:** because we are not using Merkle DAG/UnixFS representations, these CIDs should not be assumed to match the CIDs produced by IPFS “add file” workflows.

## Out of scope

This ADR does not specify:

* the filesystem/object-store path layout for blob payloads (see ADR-0006),
* transport protocols, replication policies, authorization mechanisms,
* offline blob staging/sync pipeline details.

## References

* ADR-0001: Purpose-build Offline‑First PWAs for All Shipped OurBox Apps
* ADR-0002: Adopt CouchDB + PouchDB and Standardize OurBox Data Modeling (Tenant DBs + Partitions)
* ADR-0003: Standardize on Tenant as the OurBox OS Data Boundary Term
* ADR-0004: OurBox Document IDs
* `docs/architecture/AD-0001-ourbox-os-architecture-description.md`
* SyRS-0001: OurBox OS System Requirements Specification (DATA-006: Blobs stored outside CouchDB by default)
* `docs/00-Glossary/Terms-and-Definitions.md`
