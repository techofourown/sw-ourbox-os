OurBox OS Official Image Production and Consumption

Status: Draft (informative; intended to become the canonical public model for official and custom image flows)
Audience: sw-ourbox-os maintainers, img-* maintainers, contributors, downstream builders, and operators
Public-scope note: This document describes the public build/release model, interfaces, and guarantees. It intentionally omits internal infrastructure identifiers, credentials, topology, and operational security details.

Related docs

docs/architecture/artifact-distribution-and-integration.md

docs/decisions/ADR-0008-deployment-baseline-as-the-platform-integration-contract.md

docs/decisions/ADR-0009-package-the-platform-contract-as-an-oci-artifact.md

org-techofourown/docs/decisions/ADR-0007-adopt-oci-artifacts-for-app-distribution.md

org-techofourown/docs/rfcs/RFC-0001-oci-artifacts-trust-and-attestations.md

org-techofourown/docs/decisions/ADR-0008-adopt-organization-controlled-build-infrastructure-for-heavy-artifacts.md

org-techofourown/docs/policies/OFFICIAL_ARTIFACT_BUILD_AND_PROVENANCE_POLICY.md

1. Purpose

This document explains the public system model for how OurBox OS images and related install artifacts
exist, are published, are selected by installers, and are consumed by devices.

It answers the question:

What is the public model for how official images exist, how installers find them, and how custom builders use the same lane?

This document is intentionally about artifact roles, interfaces, and trust surfaces. It is not a
private operations memo, and it does not define the exact flashing procedure for each hardware
target.

2. Scope and non-goals
In scope

This document covers:

the roles of sw-ourbox-os, img-* repos, OS payload repos, catalogs, and install-defaults

the distinction between:

official OS payloads

official installer media

install-defaults bundles

catalogs

custom or forked payloads

how default artifact selection works at a public-model level

how official and custom builders use the same distribution shape

how digest identity works today

how future signatures and attestations fit later without changing the basic lane

what installed systems should record locally about what they installed

Out of scope

This document does not specify:

the exact flashing workflow for each hardware target

whether a target is installed from SD, USB mass storage, network boot, recovery mode, direct host
flashing, or another transport

internal builder topology, runner layout, secret management, or private mirrors/caches

target-specific install UX

per-target compatibility matrices and bring-up instructions

Those target-specific procedures belong in the relevant img-* repositories because different device
classes may legitimately require different install mechanics.

3. Design principles
3.1 One lane, explicit trust

OurBox should not have one hidden “official magic lane” and another “developer lane.”

The intended model is:

build or obtain an artifact

identify it by digest, checksum, or other stable reference

install or consume it through documented interfaces

decide whether to trust it based on explicit provenance and identity

Official TOOO artifacts and third-party compatible artifacts should differ by publisher identity and
provenance, not by secret build steps.

3.2 Separate platform definition from hardware-specific packaging

sw-ourbox-os is the upstream platform-definition and integration-contract repository.

Hardware-specific img-* repositories are the consumers that turn that platform definition into:

target-specific OS payloads

target-specific installer media

target-specific install procedures

This separation allows the platform contract to evolve without forcing one monolithic image pipeline
for every hardware class.

3.3 Public-source buildability remains first-class

The source and build entrypoints for OS payloads and installer media should remain public and
repo-owned so that a third party can build compatible artifacts on their own workstation, server,
cloud account, or self-hosted runner.

3.4 Hardware targets may vary; the artifact model should not

A Raspberry Pi-class device, an x86 appliance, and a direct-flashed embedded target may not share the
same installation transport. That is expected.

What should stay stable is the public model for:

how artifacts are named

how they are published

how installers discover them

how they are identified

how installed systems record what they consumed

4. Roles in the system
4.1 sw-ourbox-os

sw-ourbox-os is the upstream producer of the platform contract and the install-defaults
control plane.

It is responsible for:

defining the deployment baseline and platform integration contract

packaging the platform contract as an OCI artifact

publishing install-defaults bundles that tell installers where to look by default

documenting the public artifact model and consumer expectations

sw-ourbox-os does not directly define every hardware-specific flashing path.

4.2 img-* repositories

Each img-* repository is a hardware-specific integration and image-build repository.

An img-* repo is responsible for one or more of:

consuming the current or chosen OurBox OS platform contract

adding target-specific integration, boot, kernel, firmware, or installer behavior

building target-specific OS payloads

building installer media or flashing assets

publishing official target-specific artifacts

documenting target-specific install paths and compatibility notes

Examples include repos like:

img-ourbox-matchbox

img-ourbox-tinderbox

img-ourbox-woodbox

This document treats them generically because the common public artifact model should hold across all
of them.

4.3 OS payload repos

An OS payload repo is the public distribution location for installable OS payload artifacts.

In practice, this is commonly an OCI repository namespace or equivalent public distribution surface
used by installers and tooling.

The OS payload repo is where official and custom publishers expose:

immutable payload references

optional moving channel tags

catalog metadata for discovery

4.4 Catalogs

A catalog is a machine-readable index associated with a payload repo.

A catalog is not the payload itself. It is the discovery and metadata surface that lets an installer
or operator answer questions such as:

what is the current stable payload for this profile?

what immutable reference does this moving tag resolve to?

what source revision, version, target, SKU, or platform-contract digest was associated with it?

4.5 Install-defaults bundles

An install-defaults bundle is the upstream control-plane artifact that tells an installer profile
where it should look by default.

It is intentionally small. It does not contain the whole OS payload.

Its job is to answer questions like:

which payload repo is the default for this installer profile?

which catalog tag should be consulted?

is there a pinned default artifact reference?

what are the current stable, beta, nightly, or experimental channel tags?

4.6 Installer media or flashing tools

Installer media is the thing that initiates installation on hardware.

That might be:

a bootable installer image

a USB stick image

a host-driven flashing tool

a recovery-mode flashing workflow

a pre-staged offline install bundle

Installer media is distinct from the installed OS payload.

4.7 Installed device

The installed device is the final consumer.

Its responsibilities are to:

consume the selected payload

install it correctly for the target

record enough local metadata to answer:

what am I running?

where did it come from?

what exact artifact identity was installed?

what platform contract did it correspond to?

5. Artifact taxonomy and distinctions
5.1 Platform Contract artifact

The Platform Contract is the primary upstream output of sw-ourbox-os.

It represents the versioned deployment baseline for the on-device platform:

k3s workloads

gateway defaults

storage and platform integration expectations

platform-level configuration baseline

Its canonical distribution shape is an OCI artifact identifiable by digest.

It is not itself the thing most end users flash directly.

5.2 Install-defaults bundle

The install-defaults bundle is an upstream-maintained control-plane bundle that maps an installer
profile to default payload locations and selection rules.

Typical fields include:

INSTALLER_ID

OS_REPO

OS_CATALOG_TAG

OS_DEFAULT_REF

CHANNEL_STABLE_TAG

CHANNEL_BETA_TAG

CHANNEL_NIGHTLY_TAG

CHANNEL_EXP_LABS_TAG

This bundle is small and separately publishable so the recommended default artifact can change without
requiring every installer image to be rebuilt for every recommendation change.

5.3 OS payload

The OS payload is the target-specific installable operating system artifact produced by an
img-* repo.

Examples include:

a compressed disk image

a target-specific install archive

a flashing payload bundle

another hardware-appropriate machine install artifact

The OS payload is what actually becomes the installed system.

5.4 Catalog

The catalog is the discovery and metadata index for a payload repo.

A catalog may include data such as:

channel name

immutable artifact tag or reference

creation timestamp

version

variant

target

model or SKU applicability

source git revision

platform contract digest

image checksum

artifact digest

pinned immutable reference

A catalog is not the thing installed; it is the thing used to resolve human-friendly moving channels
to stable artifact identities.

5.5 Installer media

The installer media is the artifact that starts the installation process.

It may:

fetch an OS payload at install time

carry a preselected payload

carry a pre-staged offline bundle

consume overrides supplied by an operator

Installer media is therefore distinct from the OS payload in both role and lifecycle.

5.6 Official OS payload vs official installer media

These are related but not identical:

Official OS payload means the actual installable system artifact published by TOOO through an
official release channel.

Official installer media means the TOOO-published artifact used to initiate installation.

In some cases they may be built together. In other cases they may evolve on different cadences.

5.7 Custom or forked payloads

A custom or forked payload is built from public source by someone other than TOOO or
published outside a TOOO official release channel.

A custom payload may still:

follow the same artifact shape

use the same installer mechanisms

maintain its own catalog

provide its own install-defaults profile or explicit overrides

A custom payload is compatible when it follows the same public contract, but it is not official
unless TOOO publishes it as such.

6. Official production model

The intended public production model is:

Step 1: sw-ourbox-os publishes the platform contract

sw-ourbox-os produces the versioned platform contract artifact and makes it available by digest.

This gives downstream image repos a stable upstream integration contract.

Step 2: sw-ourbox-os publishes install-defaults

sw-ourbox-os also publishes the install-defaults bundle that maps installer profiles to default
payload repos, catalog tags, and optional pinned references.

This acts as the upstream control plane for “where should this installer look by default?”

Step 3: an img-* repo consumes the platform contract

A hardware-specific img-* repo consumes the chosen platform contract and combines it with
hardware-specific integration, boot/runtime behavior, and install mechanics.

Step 4: the img-* repo builds OS payloads and, where applicable, installer media

The image repo produces:

one or more installable OS payload artifacts

optional installer media or flashing assets

release metadata suitable for publication and catalog indexing

Step 5: official artifacts are published through TOOO-controlled release channels

The image repo’s release path publishes:

immutable payload references

optional moving channel tags such as stable/beta/nightly

catalog updates mapping those channels to immutable references

official installer media where applicable

Per org policy, official heavy-artifact release capability should remain possible on
organization-controlled build infrastructure, even if third-party hosted CI is also used.

Step 6: installers and devices consume the published artifacts

Installer media or host-driven flashing tools use the install-defaults and catalog surfaces to select
and acquire the right payload, then install it and record what was installed.

7. Consumption model
7.1 Official default path

The standard public path looks like this:

the operator starts a target-specific installer or flasher

the installer identifies its profile (for example via INSTALLER_ID)

the installer resolves its defaults

the installer chooses either:

an explicit default pinned ref, or

a moving channel resolved through a catalog

the installer acquires the payload

the installer performs the target-specific installation

the installed system records the relevant artifact identities locally

This is the normal “use official artifacts” path.

7.2 Explicit pinned-ref path

An operator may provide an exact payload reference or digest-pinned artifact identity.

In that case, the installer can skip moving-channel discovery and install the exact requested payload.

This is the preferred repeatable path when the operator wants a known exact build.

7.3 Custom or forked path

A custom publisher or advanced operator may:

publish a payload to a non-TOOO repo

provide a custom catalog

provide a custom install-defaults bundle

or override the defaults directly on the installer media or command path

The same installer mechanisms should still work.

This is important: custom builders should not need a separate special installer protocol.

8. Default selection and control-plane model
8.1 Why install-defaults exists

Install-defaults exists so that “where should the installer look?” is a small upstream control-plane
question, not something welded forever into every installer image.

That gives TOOO a way to change recommended official refs or channels without requiring the installer
mechanics themselves to change every time.

8.2 Installer profiles

The intended unit of selection is the installer profile, commonly keyed by an INSTALLER_ID.

A profile can answer:

which repo is the default source of OS payloads?

which catalog tag should be consulted?

is there a pinned preferred default ref?

which moving channel tags are available?

8.3 Current intended precedence

At a public-model level, the intended precedence is:

explicit operator override

boot media override

config override

command-line override

other target-appropriate forced selection mechanism

resolved install-defaults profile

remote install-defaults if available

otherwise baked local fallback

pinned default ref, if provided

if OS_DEFAULT_REF is set, it is the direct default

channel resolution through catalog

if no pinned default ref exists, use the selected channel tag and resolve it through the catalog
to an immutable reference

local fallback must remain sufficient

failure to refresh remote defaults should not make the installer unable to function if it has a
valid local fallback

This is the intended public model even if specific targets may realize parts of it incrementally.

8.4 Why catalogs exist

Moving tags such as stable or beta are convenient for humans, but they move.

Catalogs exist to make the resolution legible:

human-friendly selector in

immutable reference out

with metadata explaining what that selector currently means

9. Official and custom publication surfaces
9.1 Official publication

An artifact is official when TOOO publishes it through a TOOO-controlled release channel and it
meets the org-level provenance policy.

Examples of official publication surfaces may include:

TOOO OCI repos

TOOO GitHub releases

TOOO download endpoints

other TOOO-controlled release channels

9.2 Custom publication

A third-party builder may use the same public source and build entrypoints to publish:

their own OS payload repo

their own catalog

their own installer media

their own defaults bundle

or simply their own exact pinned artifact ref

This is an intended part of the model, not a loophole.

9.3 Support boundary

Same lane does not mean same support promise.

A useful public distinction is:

official artifact = TOOO-published and TOOO-identified

compatible artifact = built against the same public contract but published by someone else

That distinction keeps the system open without blurring who is claiming responsibility.

10. Artifact identity, integrity, and future hardening
10.1 Today: digest and checksum are the ground truth

Today’s model is intentionally minimal and honest:

the canonical identity of OCI-shaped artifacts is the digest

the canonical identity of file-shaped artifacts should include a stable checksum

tags and moving channels are convenience selectors, not the ground truth

documentation should prefer digest-pinned or checksum-anchored references when repeatability matters

This matches the broader TOOO posture:

buildable from public source

traceable to source revision and digest

stronger signing/attestation layers planned

10.2 What catalogs contribute

Catalogs do not replace digests. They make moving selectors legible by telling the consumer:

what immutable thing a selector points to

what version and source revision it represents

what platform contract it was associated with

what checksum or digest the final payload has

10.3 Future: signatures, SBOMs, provenance, compatibility metadata

The org-level RFC already describes the intended future layering:

digest identifies what bits

signature identifies who is claiming responsibility

trust policy decides whether to accept that signer or exact digest

SBOM and provenance referrers add auditability

compatibility metadata helps fail closed on incompatible hardware payloads

The important point is that these future layers do not require a different basic lane.
They layer on top of the same artifact model.

10.4 Honesty rule

Until signing and attestations are actually implemented for a given artifact path, docs should avoid
overstating the current posture.

Good present-tense language is:

buildable from public source

traceable to source revision and digest

signing and attestation planned

11. What installed systems should record locally

An installed OurBox system should be able to answer:

what exact OS payload was installed?

what platform contract did it correspond to?

where did the payload come from?

what default-selection path produced this result?

was the artifact selected by channel or by exact pinned ref?

in the future, what verification result did we get?

11.1 Recommended recording location

The recommended home for this metadata is a stable local record such as:

/etc/ourbox/release

or another well-documented equivalent

11.2 Platform contract fields

Per existing sw-ourbox-os artifact-distribution guidance, the installed system should surface at
least:

OURBOX_PLATFORM_CONTRACT_SOURCE

OURBOX_PLATFORM_CONTRACT_REVISION

OURBOX_PLATFORM_CONTRACT_VERSION

OURBOX_PLATFORM_CONTRACT_DIGEST

11.3 Recommended OS payload fields

In addition, image-installed systems should surface a payload-level record such as:

OURBOX_INSTALLER_ID

OURBOX_OS_ARTIFACT_SOURCE or OURBOX_OS_REPO

OURBOX_OS_ARTIFACT_REF

OURBOX_OS_ARTIFACT_DIGEST

OURBOX_OS_IMAGE_SHA256 (for file-shaped payloads)

OURBOX_RELEASE_CHANNEL (when selected via moving channel)

OURBOX_INSTALL_DEFAULTS_SOURCE or OURBOX_INSTALL_DEFAULTS_REF (when a remote defaults bundle
influenced selection)

OURBOX_BUILD_TS or equivalent published timestamp when available

11.4 Future trust fields

Once signing and attestation are adopted, the installed system should also be able to surface:

signer identity

verification result

trust policy decision or acceptance basis

11.5 Why this matters

This record is what lets the device answer:

What am I running?
Where did it come from?
What exact bits or references define it?

That is a core part of TOOO’s inspectability posture.

12. How custom builders use the same mechanisms

A third-party builder should be able to stay inside the same public model by doing some or all of the
following:

build from the public img-* repo entrypoints

consume either:

the TOOO platform contract, or

a forked/custom platform contract

publish the resulting OS payload to their own repo

maintain their own catalog metadata

optionally publish their own installer media

point the installer to that repo using:

explicit artifact overrides

custom defaults bundles

or another documented override path

This means the model supports all of the following without changing lanes:

TOOO official releases

advanced user self-builds

community-maintained builds

long-term forks

future alternate operators

That is the point.

13. Boundary between this document and img-* repo documentation

This document defines the common public system model.

Each img-* repository should still document its own target-specific details, including:

exact flashing procedure

supported install transports

compatibility matrices

target-specific prerequisites

official artifact locations for that target

custom override instructions for that target

what “installer media” means for that hardware family

For example, a directly flashed embedded target may have a very different host-side flow than a
bootable USB installer, but both should still fit the artifact model described here.

14. Summary

The public OurBox image model is:

sw-ourbox-os defines the upstream platform contract and install-defaults control plane

img-* repos turn that upstream contract into target-specific OS payloads and installer media

payload repos publish immutable artifacts, moving channels, and catalogs

install-defaults tells a given installer profile where to look by default

installers resolve defaults, choose or resolve a payload, install it, and record what they did

TOOO official artifacts and third-party compatible artifacts use the same lane

today, digest and checksum are the ground truth

later, signatures and attestations will layer on top without changing the basic distribution shape

This keeps the system:

public

forkable

buildable by others

intelligible to operators

and not dependent on a hidden internal story to make sense
