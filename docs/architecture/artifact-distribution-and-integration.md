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

- build -> publish -> get digest -> deploy/flash by digest

The only difference is what the user chooses to trust:

- "I trust Tech of Our Own" (signature identity matches TOOO policy), or
- "I trust this exact digest," or
- "I trust my own key / my friend's key."

There is no special "developer lane." There is only explicit trust.

---

## The rule: intent in source control, identity at build time

Source-controlled official surfaces carry **intent**:
approved snapshot name, repository, channel, profile, or policy label.

Builds resolve **identity**: exact digest, exact commit SHA, exact version tag — at
the moment the build runs.

**No human should ever manually update a digest, version number, or commit SHA in
source control.** If a human is typing a hash or version number into a checked-in
file, the automation is incomplete.

This applies uniformly to:

- OCI artifact references (platform contract, substrate, install-defaults)
- vendored tool revisions (installer SSH helper, release-control module, any shared
  script vendored from an upstream repo)
- any other generated lockfile or pinned-identity record

A checked-in digest or hardcoded commit SHA is a symptom that the release automation
has a gap. The right fix is to close the gap, not to normalize the manual step.

The automation rule is:
1. upstream publishes (via its own release process)
2. downstream source control records the approved intent (snapshot name, channel, or
   equivalent policy label) — this is what humans commit
3. build workflow resolves exact identity from that intent at build start
4. resolved identity is recorded in generated provenance outputs, not in source control

---

## Boundary: platform contract above the hardware seam

`sw-ourbox-os` standardizes the platform above the hardware seam. `img-*` repositories own the
target-specific substrate below it.

That means:

- `sw-ourbox-os` is responsible for the platform contract, artifact model, and common consumer
  expectations,
- `img-*` repos are responsible for base OS image assembly, hardware enablement, bootstrap,
  installer flows, and target-specific packaging,
- image repos may legitimately differ in base distro, vendor BSP, kernel, boot chain, driver
  stack, flashing workflow, or partitioning strategy.

What must stay stable is the contract above that boundary. See also:
- `docs/decisions/ADR-0011-separate-hardware-enablement-from-the-platform-contract.md`
- `docs/reference/target-integration-contract.md`

---

## Artifact taxonomy (OurBox OS)

### 1) Platform Contract (primary output of `sw-ourbox-os`)
**Kind:** `platform-contract`  
**Meaning:** the versioned deployment baseline for the on-device platform (k3s workloads, gateway routing, access-mode defaults, storage defaults, etc.).  
**Canonical distribution:** OCI artifact identified by digest.

Recommended OCI repo:
- `ghcr.io/techofourown/sw-ourbox-os/platform-contract`

### 2) App Images (produced by app repos, referenced by the platform contract)
**Kind:** container images  
**Canonical distribution:** OCI image identified by digest.

The platform contract SHOULD reference app images by digest in manifests.

### 3) Install Defaults (installer remote config)
**Kind:** `install-defaults`  
**Meaning:** upstream-maintained installer selection defaults per hardware installer ID (recommended default ref, channel tags, catalog tag, repo override).  
**Canonical distribution:** OCI artifact identified by digest, consumed by host-side compose tools
or legacy direct-selection installers.

Recommended OCI repo:
- `ghcr.io/techofourown/sw-ourbox-os/install-defaults`

### 4) Release Manifest (future)
**Kind:** `release-manifest`  
**Meaning:** a signed "bill of materials" listing the exact digests that define an official release/profile.

---

## Consumer contract: what `img-*` repos must do

Hardware image repos are responsible for:
- base OS image assembly,
- hardware enablement,
- bootstrap and first-boot behavior,
- installer flows (if present),
- embedding or fetching the platform contract.

They SHOULD NOT be the long-term source of truth for platform manifests.

They SHOULD document how they satisfy the target integration contract:
- platform contract consumption,
- installed-system provenance,
- persistent data contract,
- bootstrap behavior,
- status and observability surfaces,
- substrate bundle behavior where relevant.

### Required (documented now; implemented later)

1) **Consumers must be able to pin upstream OCI artifacts by digest**
- The image build should have a way to consume immutable refs such as:
  - `.../platform-contract@sha256:...`
  - `.../ourbox-substrate@sha256:...`

2) **Images must record what upstream artifacts actually shipped**
The installed system SHOULD record the upstream artifact identities that matter
to operators, such as:
- `OURBOX_OS_ARTIFACT_REF`
- `OURBOX_OS_ARTIFACT_DIGEST`
- `OURBOX_SUBSTRATE_REF`
- `OURBOX_SUBSTRATE_DIGEST`
- `OURBOX_INSTALL_SELECTION_SOURCE`

Recommended location:
- `/etc/ourbox/release`

3) **Substrate is a packaging concern, not a second identity scheme**
- Substrate bundles may embed k3s bytes and platform image tar payloads.
- Identity remains digest-based.
- In an offline environment, the device should still be able to answer: "what exact pinned artifacts am I running?"

4) **Installer defaults are upstream selection data, not target-runtime state**
- Host-side compose tools may pull `install-defaults` by OCI ref while selecting artifacts.
- Legacy direct-selection installers may also consume `install-defaults`, but that is not the
  preferred direction for migrated targets.
- Targets that have moved to host-composed local mission media should not depend on
  target-runtime `install-defaults` fetches.
- The shared precedence, catalog rules, digest rules, and provenance vocabulary for this decision
  surface are defined by the installer-selection contract in
  `docs/reference/installer-selection-contract.md`.

5) **Consumer must expose an operator-readable installed-system identity**
At minimum, an operator should be able to determine:
- which target build is installed,
- which upstream OS and substrate artifacts it corresponds to,
- and where target-specific logs or bootstrap status can be inspected.

6) **Persistent-data behavior must be documented**
- The image repo must document the stable persistent data contract it exposes to the platform.
- The preferred canonical data root is `/data`, but justified target-specific divergence is allowed.

### Consumer pinning (operational)
- Consumers SHOULD pin any upstream OCI artifact they consume by digest.
- The publish workflows write pinned refs such as `dist/platform-contract.ref` and `dist/ourbox-substrate.<arch>.ref`.
- DIY users can also pull moving tags such as `:edge`, resolve them, and then pin the resulting digest for repeatable builds.

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

## Recommended repo-local doc pattern

Each `img-*` repo SHOULD eventually carry a small, repeatable doc pattern:

- a repo-local ADR that says the repo consumes the platform contract from `sw-ourbox-os`,
- a repo-local platform-contract provenance/update reference,
- a repo-local contracts doc describing the target's realization of the target integration contract.

This keeps the central model stable while making target-specific behavior legible where it belongs.

---

## References

- ADR-0009: Platform contract as OCI artifact (this repo)
- ADR-0011: Separate Hardware Enablement from the Platform Contract
- `docs/reference/target-integration-contract.md`
- Org ADR-0007: OCI artifacts as distribution substrate
- Org RFC-0001: Trust/attestations phased plan
- OurBox OS ADR-0008: Deployment baseline is the integration contract


## Reference contracts

- [Downstream consumer surfaces](../reference/downstream-consumer-surfaces.md)
- [Artifact publish record contract](../reference/artifact-publish-record-contract.md)
