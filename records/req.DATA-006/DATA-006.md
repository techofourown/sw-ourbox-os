---
typeId: req
recordId: DATA-006
parent: section:2-data-and-replication
fields:
  title: "Blobs SHALL be stored outside CouchDB by default"
  testable: true
  status: "Draft"
  rationale: "Large binary content should not be default CouchDB attachments; tenant-scoped blob stores enable legible tenant operations."
  area: "data"
  order: 6
---
Large binary assets (photos/video/audio) SHALL be stored outside CouchDB by default in the tenant blob store (one blob store per tenant), with references stored in application documents.
