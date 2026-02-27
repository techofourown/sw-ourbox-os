# RFC-0001: OurBox OS Artifact Contract and Phased OCI Adoption

**Created:** 2026-02-26  
**Updated:** 2026-02-26  

---

## What

This RFC proposes how `sw-ourbox-os` will:

- define a concrete **artifact contract** between OurBox OS (platform contract) and hardware image repos (`img-*`)
- package and distribute the **platform contract** as an OCI artifact
- evolve toward a stronger trust model (signatures, SBOM, provenance) without blocking app iteration today

This RFC allocates the org-level posture to OurBox OS concerns.

---

## Why

We need three things simultaneously:

1) **Fast app iteration** across multiple targets without reflashing OS images.
2) **A clean boundary** so `img-*` repos become "hardware flashing + bootstrap" rather than "where the platform contract lives."
3) **One lane, explicit trust**: same mechanics for everyone; tooling clearly surfaces "who signed this" and lets the user choose.

---

## How (phased)

### Phase 0 (Now): Documentation + contract clarity
- Publish the artifact model and consumer expectations (this RFC + integration doc).
- Add ADR-0009 to lock in the distribution shape: OCI + digest identity.
- No build pipeline changes required.

### Phase 1: Digest-pinned platform manifests (even before OCI packaging)
- Ensure the platform baseline can express container images by digest (not just tags).
- Ensure build output / release notes surface digests in a copy-pastable form.
- Image repos can still vendor manifests temporarily, but must record the producing revision and (eventually) the platform contract digest.

### Phase 2: Package the platform contract as an OCI artifact
- Produce an OCI artifact containing the deployment baseline bundle (e.g., tar of manifests, or OCI layout).
- Publish to `ghcr.io/techofourown/sw-ourbox-os/platform-contract`.
- Consumers pull by digest.

### Phase 3: Trust layers (org RFC alignment)
- Add signatures (keyless or key-backed), and tooling that always verifies.
- Add SBOM + provenance referrers for releases.
- Add "trust policy" UX that supports:
  - trust TOOO identities
  - trust yourself (pin digest or add your key)
  - trust a friend / community signer

---

## Artifact contract proposal (OurBox-specific)

### Artifact kinds (proposal)
- **platform-contract**: the deployment baseline for k3s (manifests, defaults, configs)
- **app images**: OCI images produced by app repos
- **release manifest** (future): signed document listing the exact digests that constitute a release/profile

### Required install-time recording (proposal)
Devices SHOULD record in `/etc/ourbox/release` (or similar):
- platform contract source + revision
- platform contract version (tag)
- platform contract digest (when available)
- (later) signer identity and verification result

This enables "what am I running?" and "who do I trust?" to be answerable locally.

---

## Trade-offs

### Pros
- Keeps app iteration unblocked.
- Gives `img-*` repos a stable upstream "contract input."
- Preserves hackability: users can ship their own artifacts in the same lane.

### Cons
- Packaging non-container things as OCI artifacts has some tooling decisions (oras, artifactType, layout format).
- Good trust UX is non-trivial and needs careful design.

---

## Open Questions

1) What is the canonical packaging format for the platform contract artifact?
   - tar of YAML?
   - OCI layout directory?
   - helm chart bundle?
2) What OurBox-specific annotations do we standardize on (kind, product, model compatibility)?
3) How will image repos consume the platform contract during the transition (vendoring vs pull-by-digest)?
4) What is the minimal trust policy format and storage location on device?

---

## Next Steps

- Merge ADR-0009 + integration doc + glossary additions.
- Use these docs as the reference when updating `img-ourbox-*` repos.
- Only then start changing build/boot logic (digest pinning, OCI packaging, etc.).

---

## References
- Org ADR-0007: Adopt OCI artifacts as canonical distribution substrate
- Org RFC-0001: OCI artifacts trust model + attestations (phased)
- OurBox OS ADR-0008: Deployment baseline as platform integration contract
