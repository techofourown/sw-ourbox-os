---
typeId: req
recordId: DATA-005
parent: section:2-data-and-replication
fields:
  title: "Large blobs MUST NOT be stored as CouchDB attachments by default"
  testable: true
  area: data
  order: 4
---
Large blobs (photos/video/audio/etc.) MUST be stored outside CouchDB by default, and documents MUST store references/hashes to those blobs.

Derived from [[adr:ADR-0002]].
