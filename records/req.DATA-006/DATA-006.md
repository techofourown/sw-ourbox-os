---
typeId: req
recordId: DATA-006
parent: section:2-data-and-replication
fields:
  title: "Large blobs MUST NOT be stored as CouchDB attachments by default"
  testable: "Partial"
  status: "Draft"
  rationale: "ADR-0002 requires blobs stored outside CouchDB by default."
  area: "data"
  order: 6
---
Large binary blobs (photos, video, audio) MUST be stored outside CouchDB by default, with documents
storing references or hashes to the blob content.
