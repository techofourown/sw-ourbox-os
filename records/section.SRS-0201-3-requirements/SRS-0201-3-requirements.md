---
typeId: section
recordId: SRS-0201-3-requirements
parent: spec:SRS-0201
fields:
  title: "Requirements"
  order: 3
  level: 1
---
Gateway requirements are mode-aware:
- TLS requirements apply to public custom-domain mode.
- Local-only tenant-host access is HTTP-only.
- Host routing covers `<tenant_id>.local` and `*.<box-host>`.
- Same-origin `/db` mapping is provided in both modes.
