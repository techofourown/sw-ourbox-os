---
typeId: req
recordId: DATA-005
parent: section:2-data-and-replication
fields:
  title: "Large blobs MUST NOT be stored as CouchDB attachments by default"
  testable: true
  status: "Draft"
  rationale: "Blob storage is external to CouchDB in the default posture."
  area: "data"
  order: 5
---
Large binary content MUST be stored outside CouchDB by default, with documents referencing blobs by hash or ID.
