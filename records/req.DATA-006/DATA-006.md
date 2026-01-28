---
typeId: req
recordId: DATA-006
parent: section:2-data-and-replication
fields:
  title: "Blobs SHALL be stored outside CouchDB by default"
  testable: true
  status: "Draft"
  rationale: "Large binary content should not be default CouchDB attachments."
  area: "data"
  order: 6
---
Large binary assets (photos/video/audio) SHALL be stored outside CouchDB by default with references
stored in application documents.
