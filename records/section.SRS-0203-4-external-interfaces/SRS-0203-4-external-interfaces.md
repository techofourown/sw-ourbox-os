---
typeId: section
recordId: SRS-0203-4-external-interfaces
parent: "spec:SRS-0203"
fields:
  title: "External Interfaces"
  level: 1
  order: 4
---
The k3s platform is treated as internal infrastructure on the OurBox instance.

External interfaces include:
- Kubernetes deployment artifacts (manifests/charts) used to define the platform baseline
- operational inspection surfaces (e.g., `kubectl`-visible resources, logs, events)

Operational procedures and any operator-facing commands are documented as operational runbooks and validated by conformance tests
where feasible. The deployment baseline manifests are the authoritative definition of platform topology and configuration (ADR-0008).
