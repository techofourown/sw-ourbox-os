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

## Artifact distribution and trust

OurBox OS uses OCI artifacts + digests as the distribution substrate for the platform contract and
related components.

- Decision: [ADR-0009](docs/decisions/ADR-0009-package-the-platform-contract-as-an-oci-artifact.md)
- Plan: [RFC-0001](docs/rfcs/RFC-0001-ourbox-os-artifact-contract-and-phased-oci-adoption.md)
- Integration reference: [Artifact distribution and integration contract](docs/architecture/artifact-distribution-and-integration.md)

The model is one lane, explicit trust: everyone uses the same artifact mechanics; trust is layered
through signer/policy choices over time.
