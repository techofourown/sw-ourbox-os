# Artifact Publish Record Contract

- Status: Stable
- Audience: maintainers of `sw-ourbox-os`, downstream automation authors, release engineers, and consumers who need machine-readable publication metadata

## Purpose

This document defines the canonical machine-readable publication record for upstream artifacts published by this repository.

This contract exists because shell-oriented outputs such as:

- `.meta.env`
- `.ref`
- `.push.log`

are useful, but they are not a strong machine-readable integration surface by themselves.

From this point forward, each upstream artifact publish path must emit a JSON publish record matching:

- `schemas/artifact-publish-record.schema.json`

The JSON publish record is the canonical machine-readable publication surface.

The older shell/human-oriented outputs remain in place for compatibility.

---

## 1. Scope

This contract applies to the upstream artifact families published from `sw-ourbox-os`:

- platform-contract
- ourbox-substrate
- install-defaults
- catalog-tooling

It does not replace downstream `candidate-provenance` records owned by `tools/release-control/`. Those are a separate downstream module contract.

---

## 2. Required record files

Each artifact family MUST emit the following record file in `dist/`.

| Artifact family | Required JSON publish record |
|---|---|
| platform-contract | `dist/platform-contract.publish-record.json` |
| install-defaults | `dist/install-defaults.publish-record.json` |
| ourbox-substrate | `dist/ourbox-substrate.<arch>.publish-record.json` |
| catalog-tooling | `dist/catalog-tooling.publish-record.json` |

For ourbox-substrate, `<arch>` is required and is currently one of:

- `arm64`
- `amd64`

---

## 3. Compatibility outputs that remain in place

The following existing outputs remain valid and must not be removed during this contract adoption:

### Platform contract
- `dist/platform-contract.meta.env`
- `dist/platform-contract.ref`
- `dist/platform-contract.push.log`

### Install-defaults
- `dist/install-defaults.meta.env`
- `dist/install-defaults.ref`
- `dist/install-defaults.push.log`

### OurBox Substrate
- `dist/ourbox-substrate.meta.env`
- `dist/ourbox-substrate.<arch>.ref`
- `dist/ourbox-substrate.<arch>.push.log`

### Catalog-tooling
- `dist/catalog-tooling.meta.env`
- `dist/catalog-tooling.ref`
- `dist/catalog-tooling.push.log`

These outputs remain useful for shell consumption and human inspection.

The publish record JSON becomes the canonical machine-readable publication surface.

---

## 4. Record schema

All publish records MUST conform to:

- `schemas/artifact-publish-record.schema.json`

The schema defines the common envelope. Artifact-family-specific required metadata keys are defined here.

### 4.1 Required common fields

Every publish record MUST contain the following top-level fields:

- `schema`
- `artifact_family`
- `artifact_type`
- `artifact_repo`
- `artifact_ref`
- `artifact_pinned_ref`
- `artifact_digest`
- `source_repo`
- `source_commit`
- `source_version`
- `created`
- `artifact_metadata`
- `input_metadata`
- `dist_files`

### 4.2 Field meanings

#### `schema`
Integer schema version for this publish record contract.

Current value:
- `1`

#### `artifact_family`
The artifact family published by this repo.

Allowed values:
- `platform-contract`
- `ourbox-substrate`
- `install-defaults`
- `catalog-tooling`

#### `artifact_type`
The OCI artifact type used in the publish step.

Examples:
- `application/vnd.techofourown.ourbox.platform-contract.v1.tar+gzip`
- `application/vnd.techofourown.ourbox.substrate.v1.tar+gzip`
- `application/vnd.techofourown.ourbox.install-defaults.v1.tar+gzip`
- `application/vnd.techofourown.ourbox.catalog-tooling.v1.tar+gzip`

#### `artifact_repo`
The OCI repository path without tag or digest.

Examples:
- `ghcr.io/techofourown/sw-ourbox-os/platform-contract`
- `ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate`
- `ghcr.io/techofourown/sw-ourbox-os/install-defaults`
- `ghcr.io/techofourown/sw-ourbox-os/catalog-tooling`

#### `artifact_ref`
The tagged ref published during this invocation.

Examples:
- `ghcr.io/techofourown/sw-ourbox-os/platform-contract:edge`
- `ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate:main-93e087a67142-arm64`
- `ghcr.io/techofourown/sw-ourbox-os/install-defaults:edge`

#### `artifact_pinned_ref`
The digest-pinned ref corresponding to the published artifact.

Example:
- `ghcr.io/techofourown/sw-ourbox-os/platform-contract@sha256:...`

#### `artifact_digest`
The artifact digest, including the `sha256:` prefix.

#### `source_repo`
The source repository URL.

Expected current value:
- `https://github.com/techofourown/sw-ourbox-os`

#### `source_commit`
The full source commit SHA used for the publish.

#### `source_version`
The source version label used by the publish.

Examples:
- `dev`
- `v0.10.1`

#### `created`
The publish/build timestamp in UTC ISO 8601 format.

#### `artifact_metadata`
String map carrying artifact-family metadata already known to the artifact family.

This should preserve the same meaningful fields that are already emitted in existing `.meta.env` outputs.

#### `input_metadata`
String map carrying important build-input metadata that is useful to downstream automation or later audit.

This is where artifact-family-specific build inputs should be surfaced.

#### `dist_files`
String map listing the important local output paths produced by the publish flow for this artifact.

These paths are relative repository paths such as:
- `dist/platform-contract.tar.gz`
- `dist/platform-contract.meta.env`
- `dist/platform-contract.push.log`
- `dist/platform-contract.ref`

---

## 5. Artifact-family-specific metadata requirements

The schema defines the common envelope. These sections define what each family MUST place into `artifact_metadata` and `input_metadata`.

### 5.1 Platform-contract

#### Required `artifact_metadata` keys
- `OURBOX_PLATFORM_CONTRACT_SOURCE`
- `OURBOX_PLATFORM_CONTRACT_REVISION`
- `OURBOX_PLATFORM_CONTRACT_VERSION`
- `OURBOX_PLATFORM_CONTRACT_CREATED`

#### Required `input_metadata` keys
- `PROFILE_DEFAULT`
  - current expected value: `demo-apps`

This record should describe the artifact that was actually published, not every possible render profile in the source tree.

#### Required `dist_files` keys
- `payload`
- `meta_env`
- `push_log`
- `pinned_ref`

### 5.2 Install-defaults

#### Required `artifact_metadata` keys
- `OURBOX_INSTALL_DEFAULTS_SOURCE`
- `OURBOX_INSTALL_DEFAULTS_REVISION`
- `OURBOX_INSTALL_DEFAULTS_VERSION`
- `OURBOX_INSTALL_DEFAULTS_CREATED`

#### Required `input_metadata` keys
- `PROFILE_COUNT`
- `PROFILE_IDS`

`PROFILE_IDS` is a stable human-readable list of bundled installer profile IDs.

#### Required `dist_files` keys
- `payload`
- `meta_env`
- `push_log`
- `pinned_ref`

### 5.3 OurBox Substrate

#### Required `artifact_metadata` keys
- `OURBOX_SUBSTRATE_SOURCE`
- `OURBOX_SUBSTRATE_REVISION`
- `OURBOX_SUBSTRATE_VERSION`
- `OURBOX_SUBSTRATE_CREATED`
- `OURBOX_SUBSTRATE_ARCH`

#### Required `input_metadata` keys
- `K3S_VERSION`
- `OURBOX_PLATFORM_PROFILE`
- `OURBOX_PLATFORM_IMAGES_LOCK_SHA256`
- `OURBOX_PLATFORM_CONTRACT_DIGEST`

For official publication, `OURBOX_PLATFORM_CONTRACT_DIGEST` is mandatory because
the substrate bundle is contract-bound to the exact published platform-contract
artifact identity.

If the build can truthfully surface additional contract-input metadata, it
should include it here.

#### Required `dist_files` keys
- `payload`
- `meta_env`
- `push_log`
- `pinned_ref`

### 5.4 Catalog-tooling

#### Required `artifact_metadata` keys
- `OURBOX_CATALOG_TOOLING_SOURCE`
- `OURBOX_CATALOG_TOOLING_REVISION`
- `OURBOX_CATALOG_TOOLING_VERSION`
- `OURBOX_CATALOG_TOOLING_CREATED`
- `OURBOX_CATALOG_TOOLING_INTERFACE_VERSION`

#### Required `input_metadata` keys
- `SCRIPT_COUNT`
- `SCRIPT_NAMES`

`SCRIPT_NAMES` is a stable human-readable list of bundled script filenames.

#### Required `dist_files` keys
- `payload`
- `meta_env`
- `push_log`
- `pinned_ref`

---

## 6. Required behavior in publish scripts

Each publish script SHALL do all of the following.

1. Build the artifact as it already does.
2. Capture the pushed digest as it already does.
3. Preserve existing `.meta.env`, `.ref`, and `.push.log` outputs.
4. Emit the publish record JSON into the required `dist/` path.
5. Ensure the emitted record conforms to the shared schema.

### 6.1 Centralized record writer
Do not hand-write JSON separately in each publish script if that can be avoided.

A shared helper under `tools/publish-records/` SHALL own JSON record emission so the contract is consistent across artifact families.

---

## 7. Example records

These examples are illustrative. The real records must be produced from actual build data.

## 7.1 Platform-contract example

```json
{
  "schema": 1,
  "artifact_family": "platform-contract",
  "artifact_type": "application/vnd.techofourown.ourbox.platform-contract.v1.tar+gzip",
  "artifact_repo": "ghcr.io/techofourown/sw-ourbox-os/platform-contract",
  "artifact_ref": "ghcr.io/techofourown/sw-ourbox-os/platform-contract:edge",
  "artifact_pinned_ref": "ghcr.io/techofourown/sw-ourbox-os/platform-contract@sha256:134129e3edaf366728f30c6f86f431c02ec9200793f77f18495cd4d341d90157",
  "artifact_digest": "sha256:134129e3edaf366728f30c6f86f431c02ec9200793f77f18495cd4d341d90157",
  "source_repo": "https://github.com/techofourown/sw-ourbox-os",
  "source_commit": "93e087a671428ee9e87688d039a8715abea735a7",
  "source_version": "v0.10.1",
  "created": "2026-03-08T14:00:05Z",
  "artifact_metadata": {
    "OURBOX_PLATFORM_CONTRACT_SOURCE": "https://github.com/techofourown/sw-ourbox-os",
    "OURBOX_PLATFORM_CONTRACT_REVISION": "93e087a671428ee9e87688d039a8715abea735a7",
    "OURBOX_PLATFORM_CONTRACT_VERSION": "v0.10.1",
    "OURBOX_PLATFORM_CONTRACT_CREATED": "2026-03-08T14:00:05Z"
  },
  "input_metadata": {
    "PROFILE_DEFAULT": "demo-apps"
  },
  "dist_files": {
    "payload": "dist/platform-contract.tar.gz",
    "meta_env": "dist/platform-contract.meta.env",
    "push_log": "dist/platform-contract.push.log",
    "pinned_ref": "dist/platform-contract.ref"
  }
}
```

## 7.2 Install-defaults example

```json
{
  "schema": 1,
  "artifact_family": "install-defaults",
  "artifact_type": "application/vnd.techofourown.ourbox.install-defaults.v1.tar+gzip",
  "artifact_repo": "ghcr.io/techofourown/sw-ourbox-os/install-defaults",
  "artifact_ref": "ghcr.io/techofourown/sw-ourbox-os/install-defaults:edge",
  "artifact_pinned_ref": "ghcr.io/techofourown/sw-ourbox-os/install-defaults@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  "artifact_digest": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  "source_repo": "https://github.com/techofourown/sw-ourbox-os",
  "source_commit": "93e087a671428ee9e87688d039a8715abea735a7",
  "source_version": "v0.10.1",
  "created": "2026-03-08T14:10:00Z",
  "artifact_metadata": {
    "OURBOX_INSTALL_DEFAULTS_SOURCE": "https://github.com/techofourown/sw-ourbox-os",
    "OURBOX_INSTALL_DEFAULTS_REVISION": "93e087a671428ee9e87688d039a8715abea735a7",
    "OURBOX_INSTALL_DEFAULTS_VERSION": "v0.10.1",
    "OURBOX_INSTALL_DEFAULTS_CREATED": "2026-03-08T14:10:00Z"
  },
  "input_metadata": {
    "PROFILE_COUNT": "3",
    "PROFILE_IDS": "matchbox woodbox tinderbox"
  },
  "dist_files": {
    "payload": "dist/install-defaults.tar.gz",
    "meta_env": "dist/install-defaults.meta.env",
    "push_log": "dist/install-defaults.push.log",
    "pinned_ref": "dist/install-defaults.ref"
  }
}
```

## 7.3 OurBox Substrate example

```json
{
  "schema": 1,
  "artifact_family": "ourbox-substrate",
  "artifact_type": "application/vnd.techofourown.ourbox.substrate.v1.tar+gzip",
  "artifact_repo": "ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate",
  "artifact_ref": "ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate:main-93e087a67142-arm64",
  "artifact_pinned_ref": "ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate@sha256:fc445baf0258f73400e27a20f4f411ad267d8722171dff566c5aeb00f41b918c",
  "artifact_digest": "sha256:fc445baf0258f73400e27a20f4f411ad267d8722171dff566c5aeb00f41b918c",
  "source_repo": "https://github.com/techofourown/sw-ourbox-os",
  "source_commit": "93e087a671428ee9e87688d039a8715abea735a7",
  "source_version": "v0.10.1",
  "created": "2026-03-08T14:20:00Z",
  "artifact_metadata": {
    "OURBOX_SUBSTRATE_SOURCE": "https://github.com/techofourown/sw-ourbox-os",
    "OURBOX_SUBSTRATE_REVISION": "93e087a671428ee9e87688d039a8715abea735a7",
    "OURBOX_SUBSTRATE_VERSION": "v0.10.1",
    "OURBOX_SUBSTRATE_CREATED": "2026-03-08T14:20:00Z",
    "OURBOX_SUBSTRATE_ARCH": "arm64"
  },
  "input_metadata": {
    "K3S_VERSION": "v1.35.0+k3s1",
    "OURBOX_PLATFORM_CONTRACT_DIGEST": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    "OURBOX_PLATFORM_PROFILE": "demo-apps",
    "OURBOX_PLATFORM_IMAGES_LOCK_SHA256": "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
  },
  "dist_files": {
    "payload": "dist/ourbox-substrate.tar.gz",
    "meta_env": "dist/ourbox-substrate.meta.env",
    "push_log": "dist/ourbox-substrate.arm64.push.log",
    "pinned_ref": "dist/ourbox-substrate.arm64.ref"
  }
}
```

---

## 8. Validation requirements

### 8.1 Schema validation

The repository SHALL provide a validation path that checks publish-record JSON documents against:

* `schemas/artifact-publish-record.schema.json`

### 8.2 Content checks

Where practical, tests SHOULD also check:

* `artifact_ref` matches `artifact_repo`,
* `artifact_pinned_ref` matches `artifact_repo`,
* `artifact_pinned_ref` embeds `artifact_digest`,
* required family-specific keys are present.

---

## 9. What downstreams may rely on

Downstream automation may safely rely on the following facts:

1. the JSON publish record exists,
2. its location is stable by artifact family,
3. its shape is defined by the shared schema,
4. its key metadata fields are present consistently across artifact families.

This is the reason the contract exists.

---

## 10. Summary

This repository now publishes three classes of machine-readable publication surfaces:

1. the artifact itself,
2. legacy shell/human sidecars,
3. the canonical publish record JSON.

The JSON record is the stable automation contract.
