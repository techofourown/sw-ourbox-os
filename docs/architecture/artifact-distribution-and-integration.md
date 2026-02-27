# OurBox OS Artifact Distribution and Integration Contract

**Status:** Draft (informative, but intended to become the canonical integration reference)  
**Audience:** `sw-ourbox-os` maintainers, `img-*` maintainers, contributors, downstream builders  

---

## Purpose

This document defines:

- what artifacts `sw-ourbox-os` produces (and will produce),
- how those artifacts are identified (digests),
- how hardware image repos (`img-ourbox-*`) consume them,
- and how we preserve "one lane, explicit trust" without introducing a separate developer mode.

---

## The principle: one lane, explicit trust

Everyone uses the same mechanics:

- build → publish → get digest → deploy/flash by digest

The only difference is what the user chooses to trust:

- "I trust Tech of Our Own" (signature identity matches TOOO policy), or
- "I trust this exact digest," or
- "I trust my own key / my friend's key."

There is no special "developer lane." There is only explicit trust.

---

## Artifact taxonomy (OurBox OS)

### 1) Platform Contract (primary output of `sw-ourbox-os`)
**Kind:** `platform-contract`  
**Meaning:** the versioned deployment baseline for the on-device platform (k3s workloads, gateway routing, storage defaults, etc.).  
**Canonical distribution:** OCI artifact identified by digest.

Recommended OCI repo:
- `ghcr.io/techofourown/sw-ourbox-os/platform-contract`

### 2) App Images (produced by app repos, referenced by the platform contract)
**Kind:** container images  
**Canonical distribution:** OCI image identified by digest.

The platform contract SHOULD reference app images by digest in manifests.

### 3) Release Manifest (future)
**Kind:** `release-manifest`  
**Meaning:** a signed "bill of materials" listing the exact digests that define an official release/profile.

---

## Consumer contract: what `img-*` repos must do

Hardware image repos are responsible for:
- base OS image assembly
- bootstrap and first-boot behavior
- installer flows (if present)
- embedding or fetching the platform contract

They SHOULD NOT be the long-term source of truth for platform manifests.

### Required (documented now; implemented later)

1) **Consumer must be able to pin the platform contract by digest**
- The image build must have a way to consume a platform contract reference like:
  - `.../platform-contract@sha256:...`

2) **Image must record "what platform contract it shipped"**
The installed system SHOULD record:
- `OURBOX_PLATFORM_CONTRACT_SOURCE`
- `OURBOX_PLATFORM_CONTRACT_REVISION`
- `OURBOX_PLATFORM_CONTRACT_VERSION`
- `OURBOX_PLATFORM_CONTRACT_DIGEST` (when available)

(Exact storage location is an implementation detail, but `/etc/ourbox/release` is the recommended home.)

3) **Airgap is a packaging concern, not an identity concern**
- Airgap bundles may embed the contract and image tars.
- Identity remains digest-based.
- In an airgapped environment, the device should still be able to answer: "what digests are these bits?"

### Consumer pinning (operational)
- Consumers SHOULD pin `ghcr.io/techofourown/sw-ourbox-os/platform-contract@sha256:<digest>`.
- The platform-contract workflow writes the digest to `dist/platform-contract.ref` (uploaded as a workflow artifact for each publish).
- DIY users can also pull `:edge` and read the digest from the ORAS output or GHCR UI before pinning.

---

## Build-from-source remains first-class

OCI does not make building from source harder; it makes distributing and identifying the output less ambiguous.

### Example "builder loop" (conceptual)

1) You modify the platform contract or an app.
2) You build and publish to *your* registry or local OCI store.
3) You get a digest.
4) You point your device / manifests / image build at that digest.

This is the same lane TOOO uses.

---

## Trust boundary (future layering)

We will layer trust on top of digest identity:

- digest answers **what bits**
- signature answers **who is claiming responsibility**
- trust policy answers **do I accept that signer/digest on this device**

Official TOOO releases will eventually be signed and verifiable offline, per the org RFC.

---

## References

- ADR-0009: Platform contract as OCI artifact (this repo)
- Org ADR-0007: OCI artifacts as distribution substrate
- Org RFC-0001: Trust/attestations phased plan
- OurBox OS ADR-0008: Deployment baseline is the integration contract
