# SRS-0203: k3s Platform Contract Software Requirements Specification

**Version:** 0.1 (Draft)
**Last Updated:** 2026-01-31
**Status:** Draft

This specification defines the software requirements for the **k3s platform contract** shipped on an OurBox instance (workload topology, persistent data placement, operational defaults, governance, and verification posture). It is a minimal scaffold; detailed requirements live in section records and the authoritative Glossary.

## Normative Language

Normative keywords (SHALL, SHALL NOT, SHOULD, SHOULD NOT, MAY) are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Product and architecture terms used in this SRS (including **Kubernetes namespace**, **Gateway**, **tenant**, **tenant origin**, and **tenant DB**) are defined in the OurBox OS Glossary.

- Vocabulary authority: `docs/architecture/Glossary.md` (normative for terminology)
- Normative keywords (SHALL/SHOULD/MAY): `docs/00-Glossary/Terms-and-Definitions.md`

## Introduction

This SRS defines requirements for the **k3s platform contract** used to deploy and operate OurBox OS workloads on an OurBox instance.

Scope includes:
- k3s as the Kubernetes distribution used on-box for OurBox OS workloads
- Kubernetes namespace posture (operational grouping; not tenant boundaries)
- **data placement** requirements for system-of-record data when deployed in k3s (persistent storage expectations)
- **defaults** required for out-of-box operation (e.g., default persistent volume provisioning, namespace conventions)
- **governance** posture for the deployment configuration baseline (how the deployed platform is defined and controlled)
- **verification** posture for confirming the running cluster satisfies the contract

Out of scope:
- gateway routing semantics and app/path policy (see `[[spec:SRS-0201]]`)
- on-box CouchDB data modeling posture (see `[[spec:SRS-0202]]`)
- tenant blob store semantics and CAS rules (see `[[spec:SRS-0205]]`)
- app-specific behavior and UI flows (see app SRSs)

## Referenced Documents

- `docs/00-Glossary/Terms-and-Definitions.md`
- `docs/architecture/Glossary.md`
- [[spec:SyRS-0001]]
- [[arch_doc:AD-0001]]
- [[adr:ADR-0003]]
- [[adr:ADR-0007]]
- [[spec:SRS-0201]]
- [[spec:SRS-0202]]
- [[spec:SRS-0205]]

## Requirements

Allocated system requirements from `[[spec:SyRS-0001]]` are included here for traceability; k3s-platform-specific requirements follow.

### K8S-001: Kubernetes namespaces SHALL NOT encode tenant boundaries

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** Tenant is a data boundary, not an operational namespace.

Kubernetes namespaces SHALL be used for operational grouping and SHALL NOT be treated as the primary
tenant isolation boundary.

### K8S-002: Gateway ingress SHALL support wildcard tenant hosts

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** Tenant origins rely on hostname routing.

Ingress configuration SHALL support wildcard host routing for `*.<box-host>` to enable tenant
subdomains.

### K8S-003: Shipped app workloads SHOULD use dedicated namespaces

**Status:** Draft  
**Testable:** false  
**Area:** k8s  
**Rationale:** Separates app operations while keeping tenant boundaries intact.

Shipped app workload bundles SHOULD run in their own Kubernetes namespaces to simplify operations
and isolation from platform services.

### K8S-004: OurBox OS SHALL use k3s as the Kubernetes distribution

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** AD-0001 establishes OurBox as a k3s-based appliance deployment posture.

OurBox OS SHALL deploy and operate its Kubernetes workloads using k3s on each OurBox instance.

**Trace:** [[arch_doc:AD-0001]]

### K8S-005: CouchDB SHALL run as a k3s workload

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** ADR-0007 establishes that CouchDB runs as a k3s workload for consistent appliance operations.

The CouchDB service SHALL be deployed and managed as a Kubernetes workload in the on-box k3s cluster and SHALL NOT be operated as an unmanaged host-level daemon.

**Trace:** [[adr:ADR-0007]]

### K8S-006: CouchDB data SHALL be stored on persistent volumes

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** CouchDB is the system-of-record; when deployed in k3s its data must survive pod restarts and rescheduling.

The CouchDB workload SHALL store CouchDB data files on persistent storage provided via Kubernetes PersistentVolumeClaim(s).

CouchDB SHALL NOT store system-of-record data only on ephemeral container filesystem storage.

**Trace:** [[adr:ADR-0007]]

### K8S-007: k3s platform SHALL provide default persistent volume provisioning for system-of-record workloads

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** Operational simplicity: the appliance should provide durable storage without requiring manual PV provisioning.

The k3s platform deployment SHALL provide a default mechanism to provision persistent volumes suitable for system-of-record workloads (e.g., CouchDB) without requiring the operator to pre-create volumes.

**Trace:** [[arch_doc:AD-0001]] §2.1

### K8S-008: Platform workloads SHOULD use dedicated system namespaces

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** AD-0001 recommends a small set of namespaces for platform workloads and app workloads for operational legibility.

Shared multi-tenant platform workloads (e.g., gateway, CouchDB, platform services) SHOULD run in a small set of dedicated Kubernetes namespaces (e.g., `ourbox-system`, `ourbox-platform`).

Shipped app workload bundles SHOULD run in app-specific Kubernetes namespaces (e.g., `app-simplenote`, `app-richnote`).

**Trace:** [[arch_doc:AD-0001]] §5.4.1

### K8S-009: k3s platform deployment SHALL be governed by a versioned configuration baseline

**Status:** Draft  
**Testable:** true  
**Area:** k8s  
**Rationale:** A versioned baseline enables reproducible deployments and controlled changes consistent with requirements governance.

The Kubernetes resources that define the OurBox OS platform deployment (namespaces, workloads, ingress, and storage objects) SHALL be defined declaratively in version-controlled artifacts.

Changes to the deployment baseline SHALL follow controlled change procedures.

**Trace:** `docs/00-Glossary/Terms-and-Definitions.md` (Baseline, Change control)

## External Interfaces

The k3s platform is treated as internal infrastructure on the OurBox instance.

External interfaces include:
- Kubernetes deployment artifacts (manifests/charts) used to define the platform baseline
- operational inspection surfaces (e.g., `kubectl`-visible resources, logs, events)

Precise operational procedures and any operator-facing commands will be specified via future ICDs or operational docs.

## Verification

Verification methods are defined in `docs/00-Glossary/Terms-and-Definitions.md`.

Initial verification posture:
- **Inspection:** confirm namespace posture (no tenant namespaces) and wildcard host ingress posture.
- **Inspection:** confirm CouchDB is deployed as a k3s workload and uses persistent storage (PVC/PV).
- **Test:** restart/reschedule the CouchDB pod and confirm tenant DB data remains intact.
- **Inspection:** confirm the deployment baseline is traceable to versioned artifacts (release manifests/config snapshots).
