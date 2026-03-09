# Installer SSH Contract

- Status: Draft
- Audience: `sw-ourbox-os` maintainers, `img-*` maintainers, downstream builders
- Related:
  - `../decisions/ADR-0013-centralize-installer-ssh-contract-above-the-hardware-seam.md`
  - `../decisions/ADR-0011-separate-hardware-enablement-from-the-platform-contract.md`
  - `../decisions/ADR-0012-centralize-installer-selection-contract-above-the-hardware-seam.md`
  - `../reference/target-integration-contract.md`
  - `../reference/installer-selection-contract.md`

## 1. Purpose

This document defines the shared policy for installer diagnostics access over SSH before
target-specific installer lifecycle and UX take over.

It exists because:

- installer SSH posture must be safe and truthful,
- the requested auth mode must not silently degrade into "SSH maybe exists but has no usable login
  path",
- compatible installers should use the same policy vocabulary even when their runtime mechanics
  differ.

This is the installer SSH contract above the hardware seam for:

- shared installer SSH input vocabulary,
- input normalization,
- posture validation,
- auth-path rules,
- deterministic `sshd_config.d` rendering semantics.

## 2. Shared Inputs

The shared installer SSH contract is defined in terms of the following inputs:

- `OURBOX_INSTALLER_SSH_MODE`
- `OURBOX_INSTALLER_SSH_USER`
- `OURBOX_INSTALLER_SSH_PASSWORD_HASH`
- `OURBOX_INSTALLER_SSH_AUTHORIZED_KEYS`
- `OURBOX_INSTALLER_SSH_ALLOW_ROOT`
- `OURBOX_INSTALLER_SSH_GENERATE_PASSWORD_IF_EMPTY`

Targets may have additional local inputs for target-specific lifecycle or UX behavior, but those are
outside this shared contract.

## 3. Mode Semantics

Shared mode meanings are:

- `off`
  - no usable installer SSH login path
- `key`
  - installer user exists and key auth is the only intended auth path
- `password`
  - installer user exists and password auth is the only intended auth path
- `both`
  - installer user exists and either or both auth paths may be usable once the target has
    materialized them safely

## 4. Validation Rules

### 4.1 Requested posture validation

Requested posture validation happens when a target is deciding whether the requested installer SSH
configuration is allowed in principle.

Rules:

- `key` requires non-empty `OURBOX_INSTALLER_SSH_AUTHORIZED_KEYS`
- `password` requires non-empty `OURBOX_INSTALLER_SSH_PASSWORD_HASH`, unless
  `OURBOX_INSTALLER_SSH_GENERATE_PASSWORD_IF_EMPTY=1` and the local target will materialize the
  password before enabling SSH
- `both` requires at least one usable auth path, or the same generation exception
- helper logic must never silently accept "no usable auth path"
- `OURBOX_INSTALLER_SSH_ALLOW_ROOT` is support-only and must be explicit

### 4.2 Materialized auth validation

Materialized auth validation happens at the point where a target is about to apply auth material and
make installer SSH real.

Rules:

- `off` is always valid because no login path should exist
- `key` requires non-empty `OURBOX_INSTALLER_SSH_AUTHORIZED_KEYS`
- `password` requires non-empty `OURBOX_INSTALLER_SSH_PASSWORD_HASH`
- `both` requires at least one materialized auth path:
  - non-empty `OURBOX_INSTALLER_SSH_PASSWORD_HASH`, or
  - non-empty `OURBOX_INSTALLER_SSH_AUTHORIZED_KEYS`

The generation flag is not sufficient at this stage by itself. A local target must have already
materialized a real password hash if it chose that path.

### 4.3 Official media rules

- official/public media must never ship a fixed shared default installer password
- official workflows must set installer SSH posture explicitly
- no official lane may rely on implicit variant defaults
- `OURBOX_INSTALLER_SSH_ALLOW_ROOT=1` is never an official/public default

## 5. Shared `sshd_config.d` Rendering Semantics

The shared helper writes a deterministic `sshd_config.d` fragment that implements the common policy.

Required semantics:

- `PermitRootLogin no` by default
- `PasswordAuthentication yes` only for password-capable modes
- `PubkeyAuthentication yes`
- `KbdInteractiveAuthentication no`
- `X11Forwarding no`
- `AllowTcpForwarding no`
- `AllowUsers` must include the installer user whenever installer SSH is enabled
- `AllowUsers` may include `root` only when `OURBOX_INSTALLER_SSH_ALLOW_ROOT=1`
- `off` must render a fragment with no usable installer SSH login path

## 6. Upstream Reference Implementation

The upstream shell helper lives at:

- `tools/installer-ssh-helper.sh`

Targets may vendor or otherwise carry that file into installer media, but the normative behavior is
defined here and owned by `sw-ourbox-os`.

## 7. Explicit Non-goals

This contract does **not** standardize:

- password generation
- password disclosure UX
- monitor output
- status file schema
- service restarts
- host-key lifecycle
- build-time versus boot-time application timing
- installer-specific prompts or support UI

Those remain target-specific below the hardware seam.

## 8. Security Rule

Generated passwords are allowed only as a **local target mechanism**.

If a target generates an installer password:

- it must not be written to general logs,
- it must not appear in shared status files,
- it must not be emitted through HTTP or UDP monitor output,
- and the local target must own the disclosure and cleanup story explicitly.

## 9. Local Responsibilities That Stay Out Of Scope

Targets remain free to differ in:

- when installer SSH is applied,
- how local password generation works,
- how generated passwords are disclosed,
- how status and monitor surfaces are published,
- how `sshd` is restarted or validated,
- how readiness is probed,
- and how installer-local support or diagnostics UX is presented.

This is deliberate. The contract exists so those local flows still realize comparable installer SSH
policy and auth safety above the hardware seam.

