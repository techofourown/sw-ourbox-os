# ADR-0006: Deterministic sharded path layout for blob payloads

## Status

Accepted

## Date

2026-01-29

## Deciders

Founder (initial); future Board + Members (ratification/amendment per `docs/policies/founding/CONSTITUTION.md`)

## Context

OurBox stores large binary payloads (photos, audio, video, etc.) outside CouchDB (ADR-0005, ADR-0002 Rule 9; SyRS DATA-006). Payloads are addressed content-wise (CID) and stored under a canonical **Blob Key** derived from the CID’s multihash bytes (ADR-0005).

A blob store can contain hundreds of thousands (or millions) of payloads over time. Storing all payloads in a single directory (filesystem) or a single prefix (object store) is undesirable:

* Large directories can degrade filesystem performance.
* Hot prefixes can degrade performance in some object stores.

We need a deterministic mapping from a blob identifier to a sharded storage path so that any component can locate payload bytes without additional indexes.

## Decision

### 1) Terminology

* **Storage root**: an implementation-chosen filesystem directory or object-store prefix under which blob payloads are stored.

  * The storage root is resolved in tenant context. Practically, each tenant has a tenant-scoped storage root (the tenant boundary remains the access boundary).
* **Payload**: the raw bytes addressed by a CID.
* **Blob Key**: the canonical base32 string derived from a CID’s multihash bytes (ADR-0005).
* **Shard**: a short string derived from the Blob Key used as a directory/prefix component.
* **Blob Path**: a relative path (from the storage root) at which a payload is stored.

### 2) Default sharding function: next-to-last/2

The blob store SHALL shard payloads using a “next-to-last/2” rule over the Blob Key.

To derive the shard:

1. Accept a Blob Key string `key`.
2. Let `N = 2`.
3. If `len(key) < N + 1`, prefix `key` with enough underscore (`_`) characters so that its length is exactly `N + 1`.
4. Let `shard` be the substring consisting of the `N` characters immediately preceding the last character.
5. Return `shard`.

For `next-to-last/2`, after underscore padding if needed:

* `shard = key[-3:-1]`

### 3) Blob Path construction

To derive the Blob Path:

1. Accept a CID.
2. Derive `key` (Blob Key) from the CID as specified in ADR-0005.
3. Derive `shard` from `key` using `next-to-last/2`.
4. Construct the relative path:

```
<shard>/<key>.data
```

5. Return that relative path as the Blob Path.

The full storage location is the concatenation of:

```
<storage-root>/<blob-path>
```

**Filename suffix rule:** The payload filename MUST use the Blob Key as the name stem and MUST use a `.data` suffix. The `.data` suffix leaves room for implementation-specific temporary files or sidecars without colliding with the payload name stem. This ADR does not define any sidecar formats.

### 4) Store behavior

* The blob store SHALL store exactly the payload bytes at the derived full storage location.
* Implementations SHOULD write payloads atomically (e.g., via a temp file + rename) to avoid partial/corrupt reads.
* Implementations MAY maintain additional indexes or metadata, but those are not required to locate payloads and do not change the derived Blob Path.

### 5) Security considerations

Implementations SHOULD treat incoming CIDs (and any caller-provided strings) as untrusted unless they are produced locally.

Implementations MUST ensure the computed Blob Path is joined to the storage root in a way that prevents directory traversal.

Because Blob Keys are restricted to uppercase RFC 4648 base32 characters (`A–Z` and `2–7`) and the shard is derived from the key, Blob Paths contain no path separators other than the single `/` between shard and filename.

## Example

Given the CID:

```
bafkreifn5yxi7nkftsn46b6x26grda57ict7md2xuvfbsgkiahe2e7vnq4
```

The derived Blob Key (base32 of the multihash bytes, unpadded, uppercase, no multibase prefix) is:

```
CIQK33ROR62ULHE3Z4D5PV4NCGB36QFH6YHVPJKKDEMUQAOJUJ7K3BY
```

Apply `next-to-last/2`:

* Shard: `3B`

Blob Path:

```
3B/CIQK33ROR62ULHE3Z4D5PV4NCGB36QFH6YHVPJKKDEMUQAOJUJ7K3BY.data
```

If the chosen storage root is `blocks`, the full path is:

```
blocks/3B/CIQK33ROR62ULHE3Z4D5PV4NCGB36QFH6YHVPJKKDEMUQAOJUJ7K3BY.data
```

## Rationale

* Deterministic path derivation avoids the need for a separate lookup index just to locate bytes.
* Sharding prevents pathological filesystem behavior from enormous single directories and mitigates hot-prefix issues in object stores.
* The rule is simple and widely interoperable: the same CID always maps to the same Blob Key, shard, and Blob Path.

## Consequences

### Positive

* **Predictable layout**: any component can derive the exact storage location from a CID.
* **Scales to large blob counts**: sharding distributes payloads across many directories/prefixes.
* **Operational simplicity**: the layout is deterministic and requires no coordination.

### Negative

* **Path is not human-meaningful** beyond the key itself; debugging is primarily via CID/Blob Key.
* **Renaming storage roots** is an operational concern (root choice is environmental), though relative paths remain stable.

## Out of scope

This ADR defines storage layout only. It does not define:

* authorization/access control,
* transport protocols,
* replication policy,
* garbage collection, accounting, or lifecycle policy,
* offline staging/sync pipeline behavior.

## References

* ADR-0005: Store blobs in a content-addressed blob store keyed by a canonical multihash key (no chunking)
* ADR-0001, ADR-0002, ADR-0003, ADR-0004
* SyRS-0001 DATA-006
* `docs/architecture/AD-0001-ourbox-os-architecture-description.md`
* `docs/00-Glossary/Terms-and-Definitions.md`
