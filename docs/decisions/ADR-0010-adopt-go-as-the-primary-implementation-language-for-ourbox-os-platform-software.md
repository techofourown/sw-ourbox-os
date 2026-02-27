# ADR-0010: Adopt Go as the Primary Implementation Language for OurBox OS Platform Software

## Date

2026-02-27
## Context

OurBox OS is a Linux-based appliance deployed across multiple hardware targets and operated as a k3s-based platform (AD-0001; SRS-0203). The platform includes first-party software items responsible for:

* tenant-scoped routing and policy enforcement (Gateway; SRS-0201),
* identity and tenant membership enforcement (SRS-0206),
* tenant-scoped storage posture (CouchDB service + tenant blob store; SRS-0202, SRS-0205; ADR-0007),
* governance and verification of the deployed platform configuration baseline (ADR-0008, ADR-0009).

We need a clear default implementation language for **first-party OurBox OS platform services and operational tooling** that we build and maintain.

Without a default, the repository risks becoming a multi-language mosaic that increases:

* build/release complexity (especially multi-architecture),
* operational burden (multiple runtimes to patch, diagnose, and support),
* security surface area (multiple dependency ecosystems and update lanes),
* contributor friction and inconsistent service patterns.

Constraints and drivers:

* OurBox OS ships across multiple CPU architectures (at minimum `linux/amd64` and `linux/arm64`).
* OurBox OS is k3s/Kubernetes-native; many platform seams are expressed and verified via Kubernetes resources and conformance tests (ADR-0008).
* Platform components are primarily networked services and controllers (HTTP(S), routing-adjacent logic, identity enforcement, storage orchestration), where concurrency and reliability matter.
* Appliance operations favor small, inspectable, reproducible artifacts (pinned versions, deterministic builds, minimal runtime dependencies).

This ADR records the language posture for OurBox OS platform code.

## Decision

We will adopt **Go** as the **primary implementation language** for **first-party OurBox OS platform software** (on-box services and tooling) that we develop and ship as part of OurBox OS.

Specifically:

1. **Default language**

   * New first-party platform services and operational tooling authored in `sw-ourbox-os` SHOULD be implemented in Go by default.

2. **Scope**

   * This ADR applies to on-box platform services and tooling (e.g., platform services, controllers/operators, install/upgrade helpers, and conformance test harnesses).
   * This ADR does **not** change the shipped-app posture in ADR-0001 (offline-first PWAs). Browser apps will continue to use appropriate web languages/tooling.

3. **Exceptions**

   * Other languages MAY be used for specific components when there is a clear, documented reason.
   * Any non-Go production platform component SHOULD be justified with an ADR or an explicit, version-controlled rationale in the component’s documentation.

4. **Non-default languages explicitly not chosen**

   * Rust is not the default language for platform services.
   * Node.js and Python are not the default languages for production on-box platform services.

## Rationale

### Why Go fits OurBox OS

1. **Multi-architecture appliance shipping**

   * OurBox OS runs on diverse Linux hardware targets. Go supports producing small, self-contained binaries per target architecture, simplifying build, release, and on-box debugging.

2. **k3s/Kubernetes ecosystem alignment**

   * OurBox OS is k3s-based (SRS-0203) and treats the deployment baseline as the integration contract (ADR-0008), with a trajectory toward OCI-packaged platform contracts (ADR-0009). Go has mature, widely-used libraries and patterns for Kubernetes clients, controllers, and operational tooling, reducing integration friction and long-term maintenance risk.

3. **Service-oriented concurrency and networking**

   * OurBox OS platform components are primarily networked services and controllers. Go provides a pragmatic concurrency model and strong standard library support for the kinds of workloads we expect (routing-adjacent services, identity/membership enforcement helpers, background work queues, and operator tooling).

4. **Operational simplicity**

   * Standardizing on one primary language reduces operational blast radius:

     * fewer runtimes to ship and patch,
     * fewer dependency ecosystems to secure,
     * fewer build pipelines to maintain,
     * easier contributor onboarding and review.

### Why Rust is not the default

Rust provides strong memory safety properties and excellent performance characteristics, but making it the default for OurBox OS platform services would impose costs that do not currently pay rent for the platform’s primary workload mix:

* **Higher implementation friction for service-heavy systems** (especially around async patterns and ecosystem choices).
* **Reduced iteration velocity** while core platform seams are stabilizing (tenant routing, membership enforcement, storage contracts, and platform baseline governance).
* **Ecosystem gravity** for Kubernetes/k3s integration and controller patterns is stronger in Go, reducing long-term integration and maintenance risk.

Rust remains an acceptable exception for tightly scoped components where it materially reduces risk.

### Why Node.js is not the default

Node.js is valuable for browser-adjacent development and some web workloads, but as a default for on-box platform services it increases appliance complexity:

* **Runtime dependency**: services require a managed Node runtime on-box and consistent runtime version alignment with shipped code.
* **Dependency surface**: typical Node services bring large transitive dependency graphs, increasing patch cadence and supply-chain review burden.
* **Resource headroom**: Node services often require higher baseline memory headroom than single-binary services for comparable roles.

Node remains appropriate where it is inherently required (browser code) or for narrowly scoped developer tooling where it is already the natural fit.

### Why Python is not the default

Python is valuable for scripting and developer workflows, but as a default for production on-box services it carries tradeoffs that work against appliance goals:

* **Interpreter + packaging complexity**: shipping reproducible, pinned, multi-arch Python environments increases build and release complexity.
* **Performance and concurrency tradeoffs**: many long-running, concurrent service workloads require careful design in Python to meet efficiency goals.
* **Operational drift risk**: environment and dependency resolution issues are a common failure mode in appliance-like deployments.

Python remains appropriate for scripting, diagnostics, or constrained tooling where its ergonomics outweigh its packaging costs.

## Consequences

### Positive

* **Consistency:** a single primary language reduces fragmentation across OurBox OS platform code.
* **Simpler multi-architecture releases:** clearer build and test pipelines for `linux/amd64` and `linux/arm64` targets.
* **k3s-native tooling leverage:** easier integration with Kubernetes conventions and libraries used by the broader ecosystem.
* **Operational legibility:** small, inspectable binaries and fewer runtime dependencies simplify on-box diagnosis and recovery.

### Negative

* **GC tradeoffs:** Go’s garbage collection can introduce memory overhead and latency variance relative to manual/ownership-based approaches.
* **Less compile-time enforcement than Rust:** some classes of correctness and concurrency invariants require disciplined design and testing rather than type-system enforcement.
* **Temptation to “just write everything in Go”:** some components may be better served by other languages when a tight scope and strong justification exist.

### Mitigation

* **Profile and budget:** define resource budgets for key services and measure memory/CPU in CI and on representative hardware targets.
* **Test-first platform seams:** rely on the deployment baseline + conformance tests posture (ADR-0008) to continuously validate integration behavior and invariants.
* **Allow justified exceptions:** use Rust (or other languages) selectively for well-bounded components when it materially reduces risk, and document those exceptions explicitly.
* **Keep browser code separate:** continue to treat shipped apps (PWAs) as web artifacts per ADR-0001, not as evidence for or against Go as the platform language.

## Implementation Notes

* Provide a Go-first service template for new platform components (logging conventions, config handling, health endpoints, and test harness patterns).
* Pin toolchain versions in version-controlled build environments to support reproducible multi-arch builds consistent with the platform contract governance posture (ADR-0008, ADR-0009).
* Establish CI checks (formatting, linting, unit tests, and multi-arch build verification) for Go-based platform components.
* Document the exception process for non-Go production components.

## References

* `docs/00-Glossary/Terms-and-Definitions.md`
* `docs/architecture/AD-0001-ourbox-os-architecture-description.md`
* SyRS-0001: OurBox OS System Requirements Specification
* SRS-0201: Gateway Software Requirements Specification
* SRS-0202: CouchDB Service Software Requirements Specification
* SRS-0203: k3s Platform Contract Software Requirements Specification
* SRS-0204: Local Tenant Replica Software Requirements Specification
* SRS-0205: Tenant Blob Store Software Requirements Specification
* SRS-0206: Identity and Tenant Membership Software Requirements Specification
* ADR-0001: Purpose-build Offline-First PWAs for All Shipped OurBox Apps
* ADR-0007: Run CouchDB as a k3s Workload (Not a Host Service)
* ADR-0008: Deployment Baseline as the Platform Integration Contract
* ADR-0009: Package the OurBox OS Platform Contract as an OCI Artifact
