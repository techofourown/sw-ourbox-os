# ADR-0013: Centralize the Installer SSH Contract Above the Hardware Seam

## Date
2026-03-09

## Context

OurBox now has multiple installer implementations that expose, or may expose, installer-time SSH
for diagnostics and support.

- Matchbox currently bakes installer SSH policy into the image during pi-gen build.
- Woodbox applies installer SSH policy at live-installer boot and layers richer local behavior on
  top, including generated-password handling, status surfaces, and monitor output.
- Future targets may or may not expose installer SSH at all.

ADR-0011 already says that installer mechanics, lifecycle, and target-specific behavior stay local
to the `img-*` repositories. ADR-0012 established the first explicit "shared-above-the-seam,
local-below-the-seam" installer abstraction by centralizing installer selection policy and shipping
a small vendorable resolver in `sw-ourbox-os`.

Installer SSH has reached the same point:

- Matchbox and Woodbox duplicate policy vocabulary, input normalization, auth-path reasoning,
  account setup, and `sshd_config.d` rendering.
- Those shared rules determine whether installer SSH is safe, truthful, and supportable.
- But the target-local mechanics still differ materially:
  - build-time versus boot-time application,
  - password generation and disclosure UX,
  - status/password files,
  - monitor/UI behavior,
  - host-key lifecycle,
  - service restart and readiness checks.

We need one shared contract for installer SSH posture above the hardware seam without collapsing the
target-specific runtime mechanics into one installer implementation.

## Decision

We will centralize the **installer SSH contract** in `sw-ourbox-os` and provide a small vendorable
shell helper there.

Concretely:

1. `sw-ourbox-os` owns the normative installer SSH contract.
   - The contract defines shared policy vocabulary, safe auth-path validation rules, and common
     `sshd_config.d` rendering semantics.
   - The canonical reference document is
     `docs/reference/installer-ssh-contract.md`.

2. `sw-ourbox-os` ships a small shell helper for the shared installer SSH contract.
   - The helper lives at `tools/installer-ssh-helper.sh`.
   - It is intentionally limited to shared policy normalization, validation, account/auth-material
     application, and deterministic `sshd_config.d` fragment rendering.

3. `img-*` repositories keep target-local lifecycle and UX.
   - Local responsibilities include:
     - when installer SSH policy is applied,
     - password generation and disclosure UX,
     - status/password file schemas,
     - host-key lifecycle,
     - `sshd -t`,
     - service restart/start behavior,
     - readiness waits,
     - monitor/UI behavior,
     - and any installer-flow-specific prompts or support ergonomics.

4. No runtime-fetched installer SSH control plane is introduced.
   - We are not introducing a new OCI artifact for installer SSH policy.
   - We are not extending `install-defaults` to carry installer SSH behavior or auth material.
   - Installer SSH policy remains repo-contained and vendored, like the installer-selection
     reference resolver, not runtime-fetched.

5. Generated installer passwords are a target-local mechanism, not part of the shared helper.
   - The shared contract may allow a local target to generate a password when the requested posture
     permits it.
   - The actual generation, disclosure, redaction, and lifecycle of that password remain local.

## Rationale

1. It centralizes the policy that determines whether installer SSH is actually safe and usable.
2. It copies the same successful abstraction pattern already used for installer selection.
3. It stops drift without forcing Matchbox and Woodbox into one runtime model.
4. It keeps security-sensitive auth material and SSH posture out of the remote `install-defaults`
   control plane.
5. It preserves room for targets that do not expose installer SSH at all.

## Consequences

### Positive
- One normative place to define installer SSH posture vocabulary and validation rules.
- One upstream helper to test and reason about.
- Cleaner boundary between shared policy and target-local lifecycle/UX.
- Easier downstream vendoring and drift checks using an existing repo pattern.
- Safer official media rules, because repos can no longer silently rely on loose local defaults.

### Negative
- Downstream repos still need to vendor or otherwise carry the helper into installer media.
- The docs surface grows: installer SSH becomes a sibling contract to installer selection.
- Cross-repo coordination is required for the first migration.

### Mitigation
- Keep the helper small and policy-focused.
- Keep generated-password handling, monitors, and service lifecycle local.
- Explicitly keep `install-defaults` out of scope for installer SSH.
- Add lightweight upstream shell tests and downstream drift checks.

## References
- ADR-0011: Separate Hardware Enablement from the Platform Contract
- ADR-0012: Centralize the Installer Selection Contract Above the Hardware Seam
- `docs/reference/target-integration-contract.md`
- `docs/reference/installer-selection-contract.md`
- `docs/reference/installer-ssh-contract.md`

