---
typeId: req
recordId: DATA-006
parent: section:2-data-and-replication
fields:
  title: "Large blobs are stored outside CouchDB"
  testable: true
  status: "Draft"
  rationale: "Large binaries should not be CouchDB attachments by default."
  area: "data"
  order: 6
---
Large binary content MUST be stored outside CouchDB by default, with documents referencing blobs
via metadata or content hashes.
