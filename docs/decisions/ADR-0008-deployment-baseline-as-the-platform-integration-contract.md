# ADR-0008: Deployment Baseline as the Platform Integration Contract

## Date
2026-01-31

## Context
OurBox OS is deployed as an appliance on a k3s cluster. The system has critical integration seams:
- local-only HTTP tenant-host routing for `<tenant_id>.local`
- optional reserved local landing host routing (`ourbox.local`)
- public HTTPS wildcard host routing for `*.<box-host>`
- gateway path routing (`/<app_slug>`, `/db`, `/api/...`)
- CouchDB workload topology and persistence (PVC/PV)
- namespace posture (namespaces are operational; not tenant boundaries)
- versioned governance of the deployed platform configuration

Traditional Interface Control Documents (ICDs) risk duplicating information already present in
deployment manifests and frequently become stale.

We must create deployment manifests regardless, and we intend to build strong integration and
conformance tests. We prefer a single, inspectable, versioned source of truth for platform wiring.

This ADR is intentionally about the deployed platform wiring above the hardware seam. It does not
decide host distro, kernel, firmware, flashing path, or other hardware enablement details. Those
target-specific concerns belong to the image repo boundary described in ADR-0011.

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
   - mode-aware host routing and posture (`<tenant_id>.local` HTTP, `*.<box-host>` HTTPS),
   - same-origin `/db` routing in both modes,
   - and a deployed cluster matches the baseline in the expected ways.
5) We will not produce standalone ICD documents for Kubernetes wiring. Where non-Kubernetes interfaces
   exist (e.g., HTTP APIs), the contract will be expressed as machine-readable artifacts
   (e.g., OpenAPI/JSON schema) and verified by tests.
6) This ADR governs deployed platform wiring only.
   - It does not define base OS selection, kernel policy, boot chain, storage layout, installer
     mechanics, or target-specific hardware enablement.
   - Those concerns are handled by hardware image repos and the target integration contract
     boundary defined in ADR-0011.

SRS documents remain the source of normative invariants and constraints; the deployment baseline and
tests provide the concrete, inspectable wiring contract and verification evidence.

## Consequences
### Benefits
- Single source of truth for platform wiring
- Reduced doc drift and duplicated interface definitions
- Inspectable running system via `kubectl` and contract metadata
- Stronger governance and reproducibility of releases
- Clearer scope boundary between platform wiring and hardware enablement

### Costs / Tradeoffs
- Requires disciplined naming conventions and pinned versions
- Requires CI to enforce deterministic rendering and conformance tests
- Some interface semantics still require contract artifacts beyond Kubernetes manifests
  (e.g., HTTP API schemas), but these are versioned and testable

## Implementation Notes
- Establish `deploy/` baseline structure and deterministic render tooling
- Add standard labels/annotations and a contract metadata ConfigMap
- Add policy checks, access-mode route conformance checks, and runtime conformance tests in CI
- Pair this ADR with the target integration contract documentation so cross-target debates stay at
  the correct architectural layer

## References
- ADR-0011: Separate Hardware Enablement from the Platform Contract
