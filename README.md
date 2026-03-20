# OurBox OS

OurBox OS is **a local-first application platform** that runs on **user-owned hardware** (or
user-owned cloud VMs) and presents a **mobile-first, phone-like web experience** for launching and
using self-hosted apps.

It is called an "OS" because it behaves like a cohesive operating environment:
- a home screen ("Launcher")
- a set of canonical first-party apps (Email, Notes, Contacts, Photos, Messaging, Settings, etc.)
- an app catalog / installation model
- shared identity, permissions, and data foundations

...but it is **not** an operating system distribution or kernel.


## Repository quick map

- [Downstream consumer surfaces](docs/reference/downstream-consumer-surfaces.md)
- [App authoring guide](docs/reference/app-authoring-guide.md)
- [Apps repository contract](docs/reference/apps-repository-contract.md)
- [Application catalog repository contract](docs/reference/application-catalog-repository-contract.md)
- [Repository layout and authority](docs/reference/repository-layout-and-authority.md)
- [Artifact publish record contract](docs/reference/artifact-publish-record-contract.md)
- [Requirements management guide](docs/01-Requirements/Requirements-Management-Guide.md)

## Artifact distribution and trust

OurBox OS uses OCI artifacts + digests as the distribution substrate for the platform contract and
related components.

- Decision: [ADR-0009](docs/decisions/ADR-0009-package-the-platform-contract-as-an-oci-artifact.md)
- Boundary decision: [ADR-0011](docs/decisions/ADR-0011-separate-hardware-enablement-from-the-platform-contract.md)
- Plan: [RFC-0001](docs/rfcs/RFC-0001-ourbox-os-artifact-contract-and-phased-oci-adoption.md)
- Integration reference: [Artifact distribution and integration contract](docs/architecture/artifact-distribution-and-integration.md)
- Target integration contract: [Reference](docs/reference/target-integration-contract.md)
- New hardware target checklist: [Reference](docs/reference/new-hardware-target-checklist.md)
- Matchbox consumer reference: [`img-ourbox-matchbox` platform contract consumption](https://github.com/techofourown/img-ourbox-matchbox/blob/main/docs/reference/platform-contract.md)
- Woodbox consumer reference: [`img-ourbox-woodbox` platform contract consumption](https://github.com/techofourown/img-ourbox-woodbox/blob/main/docs/reference/platform-contract.md)

The model is one lane, explicit trust: everyone uses the same artifact mechanics; trust is layered
through signer/policy choices over time.

## Platform contract producer workflow

This repository now produces a platform contract bundle from `platform-contract/` as a tarball
that can be published to GHCR as an OCI artifact.

- Build locally from a published catalog bundle:
  `OURBOX_APPLICATION_CATALOG_REF=ghcr.io/catalog-owner/catalog-repo@sha256:... ./tools/platform-contract/build.sh`
- Publish from a published catalog bundle:
  `OURBOX_APPLICATION_CATALOG_REF=ghcr.io/catalog-owner/catalog-repo@sha256:... ./tools/platform-contract/publish.sh [tag]`
- Publish from the in-repo demo-apps fixtures:
  `OURBOX_ALLOW_FIXTURE_APPLICATION_CATALOG=1 ./tools/platform-contract/publish.sh [tag]`
- Pinned digest output: `dist/platform-contract.ref`

Fixture-only local validation remains available via:
`OURBOX_ALLOW_FIXTURE_APPLICATION_CATALOG=1 ./tools/platform-contract/build.sh`

A GitHub Actions workflow publishes:
- `edge` on pushes to `main`
- `v*` tags as versioned contract tags
