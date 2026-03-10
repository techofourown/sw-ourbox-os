# Demo Apps Profile

This directory contains the checked-in inputs for the `demo-apps` platform
contract profile.

## Files

- `profile.env`
  - profile-level render inputs used by the platform-contract renderer
- `images.lock.json`
  - the pinned application image set for this profile

## Where this profile is used

This profile currently drives both published upstream artifact families:

- `platform-contract`
  - the renderer uses this profile to produce the default rendered contract
- `airgap-platform`
  - the airgap build re-renders the contract with this profile, then pulls and
    saves every image pinned in `images.lock.json`

That makes this directory an important shared seam. Changes here can affect:

- rendered manifests
- verification outputs
- the app image set bundled into downstream airgap media

## Who consumes the output

Downstream image repos do not consume this directory directly. They consume the
published artifacts that were built from it:

- `platform-contract`
- `airgap-platform`

## Updating this profile

Use this directory when you need to change:

- the rendered demo-apps platform behavior
- the pinned application images that should travel in the airgap bundle

After changes here, expect the publish lanes for platform-contract and
airgap-platform to be relevant.

See also:

- [platform-contract/README.md](../../README.md)
- [tools/airgap-platform/README.md](../../../tools/airgap-platform/README.md)
