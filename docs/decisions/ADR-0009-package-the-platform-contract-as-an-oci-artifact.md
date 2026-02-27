# ADR-0009: Package the OurBox OS Platform Contract as an OCI Artifact

- **Date:** 2026-02-26
- **Related:**
  - Org ADR: `org-techofourown/docs/decisions/ADR-0007-adopt-oci-artifacts-for-app-distribution.md`
  - Org RFC: `org-techofourown/docs/rfcs/RFC-0001-oci-artifacts-trust-and-attestations.md`
  - OurBox OS ADR-0008: Deployment Baseline as the Platform Integration Contract

---

## Context

OurBox OS is explicitly trying to decouple:

- **app iteration** (fast; frequent; cross-target), from
- **hardware flashing / OS images** (slow; target-specific; safety-sensitive).

We also want a single "lane" for everyone (TOOO, users, hackers) where:
- the *distribution shape is the same*,
- and the only difference is **who you choose to trust** (TOOO signer vs yourself vs a friend vs "some random mod").

At the org level, we adopted OCI artifacts + digests as the canonical distribution substrate for apps and platform components.
This repository needs a minimal, OurBox-specific allocation of that posture for the **Platform Contract**.

---

## Decision

### We will package the OurBox OS Platform Contract as an OCI artifact, and it MUST be identifiable and consumable by digest.

Concretely:

1) **Platform Contract Artifact**
- The "Platform Contract" (the versioned deployment baseline / k3s platform contract) SHALL have a canonical OCI artifact representation.
- Consumers SHALL be able to reference it as:
  - `registry/namespace/name@sha256:<digest>`

2) **Digest is the identity**
- Tags MAY exist for humans (`vMAJOR.MINOR.PATCH`, `dev`, `edge`), but the **digest is the ground truth**.
- Any consumer that cares about repeatability SHOULD pin by digest.

3) **Naming**
- OCI repository naming SHOULD align with org naming:
  - Recommended: `ghcr.io/techofourown/sw-ourbox-os/platform-contract`

4) **Minimum metadata**
The platform contract OCI artifact SHOULD carry OCI labels/annotations sufficient to make provenance legible:
- `org.opencontainers.image.source`
- `org.opencontainers.image.revision`
- `org.opencontainers.image.version`
- `org.opencontainers.image.created`

It SHOULD also include an OurBox-specific "kind" annotation, e.g.:
- `techofourown.artifact.kind=platform-contract`

5) **No hardening requirements in this ADR**
This ADR does NOT mandate, today:
- signatures
- SBOM referrers
- provenance attestations

Those are part of the org-level phased plan and will be adopted when they start paying rent.

---

## Rationale

- **One lane, explicit trust:** OCI + digest gives everyone the same distribution mechanics; trust is layered later.
- **Decoupling:** image repos can become consumers of a platform contract artifact instead of embedding bespoke manifests forever.
- **Auditability:** even before signatures, digest identity makes "what's installed" unambiguous.
- **Forkability:** users can build their own contract artifact and deploy it using the exact same mechanism.

---

## Consequences

### Positive
- Establishes a clean producer/consumer boundary between `sw-ourbox-os` (contract) and `img-*` (hardware-specific flashing).
- Makes "build from source and run your own version" a first-class path (same lane).
- Prepares for later trust hardening without redesigning distribution.

### Negative / Trade-offs
- Requires some discipline around capturing/publishing digests in future automation.
- Introduces new terminology ("platform contract artifact") that must be documented clearly.

### Mitigation
- Provide an integration doc describing the artifact model and how image repos consume it.
- Keep this ADR minimal; defer heavy requirements to the org RFC and a repo RFC.

---

## References
- Org ADR-0007 (OCI substrate)
- Org RFC-0001 (phased trust/attestations)
- OurBox OS ADR-0008 (deployment baseline is the integration contract)
