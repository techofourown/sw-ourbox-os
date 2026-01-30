File: /techofourown/sw-ourbox-os/docs/decisions/ADR-0007-run-couchdb-as-a-k3s-workload.md

# ADR-0007: Run CouchDB as a k3s Workload (Not a Host Service)

## Status
Accepted

## Date
2026-01-30

## Deciders
Founder (initial); future Board + Members (ratification/amendment per `docs/policies/founding/CONSTITUTION.md`)

## Context

OurBox OS is an offline-first, browser-first appliance whose shipped apps use PouchDB in the browser
and replicate with CouchDB on the box (ADR-0001, ADR-0002). Tenant context is derived from hostname
and enforced by the gateway (ADR-0003, AD-0001). Each tenant has exactly one tenant DB and tenant DBs
are partitioned (ADR-0002, ADR-0004, SyRS-0001 DATA-001/DATA-002).

CouchDB is a core platform dependency: it is the system-of-record and the replication target for
shipped apps. Therefore, its operational posture must be:
- secure-by-default (avoid accidental exposure of raw CouchDB surfaces),
- reproducible and pinned (appliance discipline; no “it depends on distro packages” drift),
- aligned with the platform deployment model (k3s-based services, gateway-mediated tenant routing),
- legible and supportable (one control plane for “platform services on the box”).

A design choice remains: run CouchDB as a host-installed, systemd-managed service, or run CouchDB as
a k3s-managed workload (container).

This ADR records the decision for OurBox OS.

## Decision

CouchDB SHALL run as a **k3s-managed workload** on the OurBox instance.

Specifically:

1) **Deployment model**
   - CouchDB SHALL be deployed as a Kubernetes workload managed by k3s.
   - Default form SHOULD be a **StatefulSet** (single replica on a single-node box), with a persistent
     volume for the CouchDB data directory.
   - OurBox OS SHALL NOT rely on a separately-managed host CouchDB daemon (systemd/package install)
     for normal operation.

2) **Network exposure**
   - CouchDB SHALL be treated as internal infrastructure.
   - CouchDB SHALL be exposed inside the cluster as **ClusterIP-only** (or equivalent internal-only service).
   - CouchDB SHALL NOT be directly exposed to LAN/WAN tenants as a raw node endpoint.
     Tenant and client access is mediated by the gateway (AD-0001 §4.5–4.7; SyRS-0001 GW-001..GW-003).

3) **Tenant access posture**
   - Clients replicate same-origin via the gateway surface (`/db` on the tenant origin) as defined in
     AD-0001 (e.g., `https://<tenant_id>.<box-host>/db`).
   - Clients SHALL NOT be required to know CouchDB ports, pod IPs, or internal database topology.

This ADR decides **where CouchDB runs** (k3s workload vs host service) and the associated default
exposure posture. It does not redefine tenant DB naming or document modeling, which are already
governed by ADR-0002/ADR-0004 and SyRS-0001.

## Rationale

1) **One operational control plane for platform services**
   OurBox OS is explicitly k3s-based for platform deployment. Running CouchDB as a k3s workload keeps
   platform services within one lifecycle manager (k3s), rather than splitting operations between
   systemd services and Kubernetes workloads.

2) **Secure-by-default network boundaries**
   A k3s workload with a ClusterIP service is internal-only by default. This aligns with the OurBox
   posture that CouchDB is infrastructure behind the gateway, reducing the risk of accidentally
   exposing raw CouchDB surfaces on the network.

3) **Clean integration with gateway-mediated tenancy**
   OurBox derives tenant context from hostname and enforces membership at the gateway (ADR-0003, AD-0001).
   Deploying CouchDB in-cluster makes the gateway→CouchDB dependency straightforward and predictable,
   without host-network binding and firewall complexity.

4) **Reproducibility and appliance discipline**
   A containerized CouchDB enables consistent version pinning and repeatable deployments across
   hardware targets. It avoids coupling CouchDB correctness to host OS package ecosystems and
   dependency resolution at install time.

5) **Alignment with OurBox’s definition of “system working”**
   OurBox OS platform services depend on k3s. If k3s is not running, the OurBox instance is not in a
   functional state for tenants. Therefore, treating CouchDB as a k3s workload aligns availability
   boundaries with the platform’s actual operational boundary.

## Consequences

### Positive
- **Security by default:** CouchDB stays internal; the gateway remains the only tenant-facing surface.
- **Operational legibility:** platform services share the same lifecycle, health reporting, and deployment model.
- **Reproducible shipping:** pinned container images and manifests reduce drift and “works on my distro” surprises.
- **Straightforward gateway integration:** in-cluster service routing is simpler and less error-prone than host-level routing.
- **Supports OurBox tenancy posture:** aligns with tenant-derived-from-hostname and gateway-mediated access (ADR-0003, AD-0001).

### Negative
- **CouchDB availability is coupled to k3s availability:** CouchDB will not run independently of k3s.
- **Stateful workload correctness must be treated as first-class:** storage placement, permissions, upgrades,
  and operational hygiene must be handled deliberately.

### Mitigation
- **Treat k3s health as a first-order platform requirement:** OurBox OS already depends on k3s for platform
  function; operational tooling SHOULD diagnose and repair k3s as the primary recovery path.
- **Make state explicit and deterministic:** CouchDB data MUST be persisted on stable storage (persistent volume)
  rather than ephemeral container storage. (Exact storage root/path and PV strategy may be specified in a
  separate ADR or deployment spec.)
- **Keep CouchDB internal:** enforce ClusterIP-only service posture and avoid NodePort/hostPort patterns by default.
- **Operational hygiene:** define and automate compaction/maintenance, and monitor revision growth and storage use
  (AD-0001 §8.1).
- **Document break-glass procedures:** provide clear operator guidance for inspecting/backing up the persistent
  data on disk when the system is unhealthy, consistent with Operator Truth.

## References
- ADR-0001: Purpose-build Offline‑First PWAs for All Shipped OurBox Apps
- ADR-0002: Adopt CouchDB + PouchDB and Standardize OurBox Data Modeling (Tenant DBs + Partitions)
- ADR-0003: Standardize on Tenant as the OurBox OS Data Boundary Term
- ADR-0004: OurBox Document IDs
- ADR-0005: Store blobs in a content-addressed blob store keyed by a canonical multihash key (no chunking)
- ADR-0006: Deterministic sharded path layout for blob payloads
- `docs/architecture/AD-0001-ourbox-os-architecture-description.md`
- SyRS-0001: OurBox OS System Requirements Specification (notably DATA-001..DATA-006; GW-001..GW-003; K8S-001..K8S-003)
