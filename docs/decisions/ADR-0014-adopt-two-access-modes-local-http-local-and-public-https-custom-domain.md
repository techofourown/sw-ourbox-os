# ADR-0014: Adopt Two Access Modes: Local HTTP `.local` and Public HTTPS Custom-Domain

## Date
2026-03-10

## Context

OurBox OS currently centers the tenant boundary on the browser origin and derives tenant context from the hostname.

The existing public-pattern shape is:

- `https://<tenant_id>.<box-host>/<app_slug>`

This posture appears in ADR-0001, ADR-0003, AD-0001, SyRS-0001, and the Gateway requirements.

For clarity, in URI/web terms:

- the **host** is the full host portion of the URL before any port and before the path,
- in a host such as `bob.box.example.com`, the full host is `bob.box.example.com`,
- `tenant_id` is the **leftmost DNS label** of that full host (`bob`),
- and `box-host` is the **base host suffix after the tenant label** (`box.example.com`).

Examples:
- full host: `bob.bobsdomain.com`
  - `tenant_id = bob`
  - `box-host = bobsdomain.com`
- full host: `alice.box.example.com`
  - `tenant_id = alice`
  - `box-host = box.example.com`

This existing public pattern is the correct long-term shape for full tenant-origin behavior:

- the **full host** carries tenant context,
- the gateway derives `tenant_id` from the leftmost DNS label of that full host,
- the path identifies the app experience,
- all shipped apps under the same tenant origin share one local tenant replica,
- and HTTPS + service-worker-backed installable PWA behavior are part of the current shipped-app posture.

However, the product also needs a **zero-preparation day-one LAN experience**:

- the user plugs the box into power and Ethernet,
- the box joins a functioning local network,
- the user does **not** register a domain,
- the user does **not** configure router DNS,
- the user does **not** configure port forwarding,
- the user does **not** install a local CA,
- and the user can still reach tenant-scoped app surfaces by name from client devices on that local network.

At the same time, OurBox also needs a **higher-friction public mode** for users who later choose to expose the box on the public internet using their own registered domain and external routing.

We therefore need to distinguish two access modes:

1. a **local-only joined-LAN mode** optimized for zero-preparation local use, and
2. a **public custom-domain mode** optimized for canonical HTTPS tenant origins and full PWA posture.

This ADR records that product-level separation.

This ADR is about **how the box is addressed** in those two modes and about the transport posture attached to each mode.

This ADR does **not** decide the full browser/PWA/offline behavior differences between the modes. Those consequences are documented separately in RFC-0002.

## Decision

We will support **two first-class access modes** for tenant app access:

1. **Local-only mode**
2. **Public custom-domain mode**

### 1) Unifying routing model across both modes

Across both access modes, the product model remains:

- the **full host** carries tenant context,
- the gateway derives `tenant_id` from the full host,
- and the **path** identifies the app experience.

Put plainly:

- full host carries tenant context
- leftmost DNS label identifies `tenant_id`
- path identifies app

This remains the conceptual rule even though the exact hostname grammar differs by mode.

### 2) Local-only mode

Local-only mode is the zero-preparation joined-LAN mode.

#### Local tenant host pattern
Tenant app surfaces in local-only mode use:

- `http://<tenant_id>.local/<app_slug>`

Examples:
- `http://default.local/simplenote`
- `http://bob.local/richnote`
- `http://alice.local/tasks`

In local-only mode:

- the full host is exactly `<tenant_id>.local`
- the leftmost DNS label is the tenant label
- there is no separate user-configured public `box-host` suffix in the local tenant-host pattern

Examples:
- full host: `bob.local`
  - `tenant_id = bob`
- full host: `alice.local`
  - `tenant_id = alice`

#### Local landing/setup host
The product MAY expose a reserved local landing/setup host for non-tenant entry flows.

Recommended pattern:
- `http://ourbox.local/`

This reserved local host is not a tenant host.

#### Local-only mode is HTTP-only
Local-only mode SHALL use **HTTP only**.

Local-only mode SHALL NOT require or promise HTTPS/TLS for `.local` tenant hosts.

Examples:
- `http://bob.local/notes`
- `http://alice.local/tasks`

Examples that are **not** part of the local-only mode contract:
- `https://bob.local/notes`
- `https://alice.local/tasks`

#### Local-only mode characteristics
Local-only mode is intended to require:

- a functioning local network,
- no public DNS registration,
- no port forwarding,
- no router/DHCP/DNS preparation,
- no local CA installation,
- and no vendor-assigned box identifier in the hostname.

#### Local-only mode transport/security implication
Because local-only mode is HTTP-only:

- it does **not** provide TLS transport authentication,
- it does **not** provide TLS transport confidentiality,
- it does **not** provide TLS transport integrity,
- and browsers may present insecure-transport UI indicators for local-only pages.

This is an accepted tradeoff of the zero-preparation local-only mode.

### 3) Public custom-domain mode

Public custom-domain mode is the user-configured internet-facing mode.

Tenant app surfaces in public custom-domain mode use:

- `https://<tenant_id>.<box-host>/<app_slug>`

Examples:
- `https://bob.bobsdomain.com/richnote`
- `https://alice.bobsdomain.com/tasks`
- `https://default.box.example.com/simplenote`

For clarity, in public custom-domain mode:

- the **full host** is `<tenant_id>.<box-host>`
- `tenant_id` is the leftmost DNS label of that full host
- `box-host` is the base host suffix after the tenant label

Examples:
- full host: `bob.bobsdomain.com`
  - `tenant_id = bob`
  - `box-host = bobsdomain.com`
- full host: `alice.box.example.com`
  - `tenant_id = alice`
  - `box-host = box.example.com`

Where:

- `box-host` is a user-controlled public DNS base host under a registered domain,
- the exact public DNS layout is operator-chosen,
- and the user is responsible for the external routing needed to reach the OurBox gateway.

Public custom-domain mode does **not** require a vendor-assigned box identifier in the hostname.

#### Public custom-domain mode is HTTPS mode
Public custom-domain mode is the HTTPS/TLS mode.

This mode is the mode intended to carry:

- TLS transport authentication,
- TLS transport confidentiality/integrity,
- trusted browser secure-context behavior,
- and the full installable-PWA posture targeted by existing shipped-app documents.

### 4) Local and public modes are both product-valid

Public custom-domain mode does not invalidate local-only mode.

An OurBox MAY continue to support local-only access and public custom-domain access at the same time, subject to operator choice and implementation details.

This ADR does not require that enabling public mode disable local mode.

### 5) Local-only mode is intentionally a one-box-per-local-link simplification

The v0 local-only mode intentionally optimizes for the common “first box on a home LAN” case.

The product does **not** attempt to solve the multiple-OurBox-per-link naming problem in local-only mode.

Local-only mode therefore accepts the tradeoff that:

- multiple OurBox devices on the same local link are not a supported zero-preparation scenario in v0,
- and local hostname collisions with other devices are a practical risk that must be handled operationally and in UX, not by adding a vendor box identifier to the local hostname grammar.

### 6) This ADR does not decide full offline/PWA equivalence between the modes

This ADR decides the supported access-mode patterns, host grammar, and basic transport posture.

It does **not** decide that local-only mode and public custom-domain mode have identical browser behavior.

In particular, this ADR does not claim that:

- `http://<tenant_id>.local/...` and
- `https://<tenant_id>.<box-host>/...`

have identical:

- TLS behavior,
- browser security UI,
- secure-context behavior,
- service-worker support,
- installability,
- or reopen-offline behavior.

Those differences are explicitly analyzed in RFC-0002 and are reflected across architecture, glossary, and requirements artifacts.

## Rationale

### 1) Day-one usability matters
The product needs a genuinely low-friction “take it home, plug it in, and use it” path.

Requiring domain registration, DNS configuration, or port forwarding before a user can access the box would unnecessarily delay first value.

### 2) The full host should continue to carry tenant context
ADR-0003 and AD-0001 correctly place the tenant boundary in the hostname because browser origins isolate storage and service workers by `(scheme, host, port)`.

The precise technical rule is:

- the full host carries tenant context,
- the gateway derives `tenant_id` from the leftmost DNS label of that full host,
- and the path identifies app context.

That model remains correct in both modes.

### 3) Local-only mode should optimize for the local network we actually get
A box that joins an arbitrary home LAN as a client cannot assume:

- wildcard local DNS,
- router cooperation,
- operator DNS skill,
- trusted local TLS,
- or local certificate installation.

A `.local`-based, HTTP-only local host grammar is the practical zero-preparation path.

### 4) Local-only mode must be honest about HTTP
If the product promises “just plug it in and go” with no router prep, no domain, and no certificate setup, then local-only mode must accept HTTP.

Pretending this mode is also an HTTPS/TLS mode would either add hidden operator friction or create an untruthful transport/security story.

### 5) Public mode should preserve the canonical HTTPS tenant-origin posture
Once a user chooses the higher-friction public path, the product should return to the canonical public pattern:

- full host: `<tenant_id>.<box-host>`
- full URL: `https://<tenant_id>.<box-host>/<app_slug>`

That remains the cleanest model for public tenant origins, gateway routing, and full PWA posture.

### 6) We do not want a vendor box identifier in the hostname
We are intentionally not standardizing on a vendor-assigned or factory-assigned box identifier in user-visible hostnames for either local-only mode or public custom-domain mode.

That simplicity is more important than solving the rare multi-box-per-link home-LAN case in v0 local mode.

## Consequences

### Positive
- Users get a true zero-preparation local access mode.
- The product preserves a stable conceptual routing model:
  - the full host carries tenant context
  - the leftmost DNS label identifies `tenant_id`
  - the path identifies app
- Public custom-domain mode remains clean and legible.
- The product avoids coupling day-one usability to domain purchase and router configuration.
- We avoid introducing a vendor-controlled box identifier into user-visible hostname patterns.

### Negative
- The product now has two hostname grammars rather than one.
- Local-only mode and public custom-domain mode are not browser-equivalent in every respect.
- Local-only mode is HTTP-only and therefore does not provide TLS transport security.
- Local-only mode may trigger browser insecure-transport UI indicators.
- Local-only mode accepts local hostname collision risk.
- Multiple OurBoxes on the same local link are not a supported zero-preparation local-only scenario in v0.
- Repository architecture and requirements artifacts use this mode-aware model as the documentation norm.

### Mitigation
- Document the behavioral differences explicitly (RFC-0002).
- Keep the conceptual rule stable across both modes:
  - the full host carries tenant context
  - the leftmost DNS label identifies `tenant_id`
  - the path identifies app
- Reserve a product local landing host (recommended: `ourbox.local`) for setup/admin entry flows.
- Keep AD-0001, ADRs, glossary, and requirements artifacts aligned to this mode-aware model.
- Make local-name collisions a visible operational/UX concern rather than hiding them behind a vendor box identifier.
- Be explicit in docs and UI that local-only mode is HTTP-only and not the same transport/security posture as public HTTPS mode.

## References
- ADR-0001: Purpose-build Offline‑First PWAs for All Shipped OurBox Apps
- ADR-0003: Standardize on Tenant as the OurBox OS Data Boundary Term
- AD-0001: OurBox OS Architecture Description
- SyRS-0001: OurBox OS System Requirements Specification
- SRS-0201: Gateway Software Requirements Specification
- docs/00-Glossary/Terms-and-Definitions.md
- RFC-0002: Behavioral Differences Between Local HTTP `.local` Mode and Public HTTPS Custom-Domain Mode
