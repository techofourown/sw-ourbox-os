# ADR-0008: Deployment Baseline as the Platform Integration Contract

## Status
Draft

## Date
2026-01-31

## Context
OurBox OS is deployed as an appliance on a k3s cluster. The system has critical integration seams:
- wildcard host ingress for tenant origins
- gateway path routing (`/<app_slug>`, `/db`, `/api/...`)
- CouchDB workload topology and persistence (PVC/PV)
- namespace posture (namespaces are operational; not tenant boundaries)
- versioned governance of the deployed platform configuration

Traditional Interface Control Documents (ICDs) risk duplicating information already present in
deployment manifests and frequently become stale.

We must create deployment manifests regardless, and we intend to build strong integration and
conformance tests. We prefer a single, inspectable, versioned source of truth for platform wiring.

## Decision
We will treat the versioned Kubernetes deployment baseline (rendered manifests) as the authoritative
platform integration contract for k3s wiring concerns.

Specifically:
1) The platform deployment SHALL be defined declaratively in version-controlled artifacts.
2) A deterministic rendering process SHALL produce a canonical manifest bundle for a given release.
3) Platform resources SHALL carry standard labels/annotations sufficient for operator inspection
   (component identity, contract version/source revision).
4) A conformance/integration test suite SHALL verify:
   - the baseline satisfies the platform requirements (e.g., K8S-00x, GW-00x),
   - and a deployed cluster matches the baseline in the expected ways.
5) We will not produce standalone ICD documents for Kubernetes wiring. Where non-Kubernetes interfaces
   exist (e.g., HTTP APIs), the contract will be expressed as machine-readable artifacts
   (e.g., OpenAPI/JSON schema) and verified by tests.

SRS documents remain the source of normative invariants and constraints; the deployment baseline and
tests provide the concrete, inspectable wiring contract and verification evidence.

## Consequences
### Benefits
- Single source of truth for platform wiring
- Reduced doc drift and duplicated interface definitions
- Inspectable running system via `kubectl` and contract metadata
- Stronger governance and reproducibility of releases

### Costs / Tradeoffs
- Requires disciplined naming conventions and pinned versions
- Requires CI to enforce deterministic rendering and conformance tests
- Some interface semantics still require contract artifacts beyond Kubernetes manifests
  (e.g., HTTP API schemas), but these are versioned and testable

## Implementation Notes
- Establish `deploy/` baseline structure and deterministic render tooling
- Add standard labels/annotations and a contract metadata ConfigMap
- Add policy checks and runtime conformance tests in CI
