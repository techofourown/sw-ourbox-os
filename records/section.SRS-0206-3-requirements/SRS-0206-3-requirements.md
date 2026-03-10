---
typeId: section
recordId: SRS-0206-3-requirements
parent: spec:SRS-0206
fields:
  title: "Requirements"
  order: 3
  level: 1
---
Identity requirements derive tenant context from the leftmost DNS label of the full host in both modes.
`tenant_id` constraints are DNS-label-safe and mode-neutral.
