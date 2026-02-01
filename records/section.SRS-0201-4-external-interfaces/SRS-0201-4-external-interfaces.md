---
typeId: section
recordId: SRS-0201-4-external-interfaces
parent: spec:SRS-0201
fields:
  title: "External Interfaces"
  order: 4
  level: 1
---
Gateway external interfaces are HTTP(S) surfaces on tenant origins, including:
- wildcard tenant hosts: `*.<box-host>`
- app paths: `/<app_slug>`
- replication path: `/db`
- API paths: `/api/...` (when present)

The authoritative definition of these external surfaces (host routing, paths, routing objects, and service bindings)
is the versioned deployment baseline (rendered Kubernetes manifests) and the running cluster state, verified by
conformance/integration tests (see ADR-0008).

This SRS intentionally does not define internal identity/session wire details (header names, claim keys, token formats).
Those concrete wire details are defined as versioned contract artifacts (e.g., OpenAPI security schemes and/or JSON schemas)
and are enforced by automated tests.
