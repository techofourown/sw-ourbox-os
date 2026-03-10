# RFC-0002: Behavioral Differences Between Local HTTP `.local` Mode and Public HTTPS Custom-Domain Mode

**Created:** 2026-03-10  
**Updated:** 2026-03-10

---

## What

This RFC documents the behavioral differences between the two supported OurBox access modes introduced by ADR-0014:

1. **Local-only mode**
   - `http://<tenant_id>.local/<app_slug>`
   - optional local landing/setup host such as `http://ourbox.local/`

2. **Public custom-domain mode**
   - `https://<tenant_id>.<box-host>/<app_slug>`

This RFC exists because those two modes are **not browser-equivalent**, even though they preserve the same conceptual routing model:

- the full host carries tenant context,
- the gateway derives `tenant_id` from the full host,
- and the path identifies app.

This RFC also makes an important terminology point explicit:

- in a URL such as `https://bob.box.example.com/notes`, the **full host** is `bob.box.example.com`,
- `tenant_id` is the leftmost DNS label of that full host (`bob`),
- and `box-host` is the base host suffix after the tenant label (`box.example.com`).

So in public custom-domain mode:

- the full host is `<tenant_id>.<box-host>`

not:

- “the host is `<box-host>` and the subdomain is something separate from the host.”

The tenant label is part of the full host.

In particular, this RFC focuses on the difference between:

- **local data continuity** via PouchDB/IndexedDB and same-origin app routing, and
- **full service-worker-backed PWA/offline behavior**.

This RFC is the behavioral reference for distinguishing the two permanent access modes in product, architecture, and requirements language.

---

## Why

OurBox supports two first-class tenant access modes with shared routing semantics but different browser/runtime behavior:

- local-only mode (`http://<tenant_id>.local/...`) for zero-preparation LAN access,
- public custom-domain mode (`https://<tenant_id>.<box-host>/...`) for HTTPS secure-context access.

This RFC documents the practical behavior split so product, UI, requirements, and verification stay explicit about:

- HTTP-only transport implications in local-only mode,
- HTTPS/TLS and secure-context posture in public custom-domain mode,
- shared tenant-host/path routing invariants,
- and mode-scoped offline/PWA expectations.

## How

## 1. Terms used in this RFC

To avoid ambiguity, this RFC uses the following terms.

### 1.1 Full host
The entire host portion of the URL before any port and before the path.

Examples:
- full host: `bob.local`
- full host: `bob.box.example.com`

### 1.2 `box-host`
In public custom-domain mode, `box-host` means the base host suffix after the tenant label.

Examples:
- full host: `bob.bobsdomain.com`
  - `tenant_id = bob`
  - `box-host = bobsdomain.com`
- full host: `alice.box.example.com`
  - `tenant_id = alice`
  - `box-host = box.example.com`

In local-only mode, the tenant host pattern is simply `<tenant_id>.local`; there is no separate public `box-host` suffix in that local tenant-host grammar.

### 1.3 Tenant host
The full host used to address a tenant.

Patterns:
- local-only mode: `<tenant_id>.local`
- public custom-domain mode: `<tenant_id>.<box-host>`

### 1.4 LAN-reachable
The client can resolve the host and reach the OurBox over the local network.

Examples:
- the home router still works,
- the device is still on the same Wi‑Fi/LAN,
- `bob.local` still resolves and the box is reachable.

### 1.5 Box-unreachable
The client cannot reach the OurBox at all.

Examples:
- the box is powered off,
- the client has left the LAN,
- or the host no longer resolves/reaches the box.

### 1.6 Continue-running offline
The app is already open in a tab/window and can continue using already-loaded assets plus local browser storage even after the box becomes unreachable.

### 1.7 Reopen offline
The user closes the tab/browser/app, or reloads the page, and later reopens the URL while the box is unreachable.

This requires the browser to be able to serve the app shell and associated assets without reaching the box.

### 1.8 Full PWA posture
For this RFC, “full PWA posture” means the behavior OurBox has been targeting in ADR-0001 / AD-0001:

- secure-context web app behavior,
- service-worker-backed app-shell caching,
- installability,
- and reopen-offline capability after first successful load.

### 1.9 Local-only mode is HTTP-only
For this RFC, local-only mode means:

- plain HTTP,
- `.local` hostnames,
- no default TLS,
- and no claim that local-only tenant hosts are browser-trusted secure contexts.

---

## 2. Common architectural behavior across both modes

The two modes are not identical, but they do share important invariants.

### 2.1 The full host carries tenant context; the path identifies app
Both modes preserve the same product model:

- the full host carries tenant context,
- the gateway derives `tenant_id` from the full host,
- and the path identifies app.

More precisely:

- in local-only mode, the full host is `<tenant_id>.local`
- in public custom-domain mode, the full host is `<tenant_id>.<box-host>`

Examples:
- local-only mode: `http://bob.local/notes`
  - full host: `bob.local`
  - `tenant_id = bob`
- public mode: `https://bob.box.example.com/notes`
  - full host: `bob.box.example.com`
  - `tenant_id = bob`
  - `box-host = box.example.com`

### 2.2 Tenant isolation still follows browser origin rules
In both modes, different tenant hosts are different origins.

Examples:
- `http://bob.local`
- `http://alice.local`

are distinct origins.

Likewise:
- `https://bob.example.com`
- `https://alice.example.com`

are distinct origins.

This means tenant-scoped browser storage isolation still fundamentally works in both modes.

### 2.3 Apps under the same tenant host still share one origin
Within a given mode, app paths under the same tenant host remain the same origin.

Examples:
- `http://bob.local/notes`
- `http://bob.local/contacts`

share the same origin.

Likewise:
- `https://bob.example.com/notes`
- `https://bob.example.com/contacts`

share the same origin.

So the single local tenant replica model still makes sense in both modes.

### 2.4 Same-origin replication endpoint model still works in both modes
In both modes, the gateway can preserve the same conceptual replication surface:

- `/db` on the tenant origin

Examples:
- `http://bob.local/db`
- `https://bob.example.com/db`

As long as the box is reachable in that mode, PouchDB can still replicate with the tenant DB through the same-origin gateway surface.

---

## 3. The transport/TLS difference is fundamental

Before discussing offline behavior, this RFC makes the transport difference explicit.

## 3.1 Local-only mode is HTTP-only
In local-only mode:

- URLs are `http://...`
- there is no default TLS certificate for tenant hosts
- the browser connection is not TLS-authenticated
- the browser connection is not TLS-encrypted
- the browser connection does not get TLS integrity protection

This means local-only mode should be understood as a **local convenience mode**, not as transport-equivalent to public HTTPS mode.

## 3.2 Browser UI will reflect that local-only mode is HTTP
Because local-only mode is plain HTTP, browsers may present insecure-transport UI indications.

Exact wording varies by browser and platform, but product and docs should expect things like:

- “not secure” / insecure indicators,
- less reassuring lock/security UI,
- and browser/platform behaviors that distinguish HTTP from HTTPS.

OurBox should not document local-only mode in a way that implies browser trust signals equivalent to HTTPS.

## 3.3 Secure-context-dependent browser features are not automatically part of local-only mode
Because local-only mode is HTTP-only, OurBox should not assume that browser features requiring secure contexts are available in that mode.

This is especially relevant to:

- service-worker-backed app-shell caching,
- installability,
- and other browser capabilities typically associated with HTTPS PWAs.

## 3.4 Some auth/session designs may need mode-specific handling
Any auth/session design that assumes HTTPS transport may need local-mode-specific treatment.

Examples of implications that may need explicit design work:

- HTTPS-only cookie attributes,
- transport assumptions in browser session handling,
- UI language about sign-in trust,
- and warnings or guidance around local network trust.

This RFC flags that implication but does not design the auth/session solution.

## 3.5 Public custom-domain mode is the TLS/secure-context mode
In public custom-domain mode:

- URLs are `https://...`
- the connection is intended to be browser-trusted HTTPS
- secure-context browser behavior is the expected posture
- and this remains the mode where the existing full-PWA story fits naturally.

---

## 4. The key difference: data continuity is not the same thing as full PWA/offline behavior

This RFC draws a hard line between two ideas that are easy to conflate:

1. **local data continuity**
   - IndexedDB/PouchDB still exists in the browser,
   - and the currently loaded app may keep reading/writing it

2. **full reopen-offline behavior**
   - the browser can load or reload the app shell without the box,
   - typically through service-worker-backed cached assets on a secure origin

Public custom-domain mode is intended to provide both.

Local-only mode is intended to provide the first, but should not be documented as if it guarantees the second.

That difference is the entire reason this RFC exists.

---

## 5. Local-only mode behavior

## 5.1 Local-only mode strengths

Local-only mode is strong at:

- zero-preparation LAN access,
- same-origin tenant routing,
- shared local tenant replica per tenant origin,
- same-origin replication while the box is reachable,
- low-friction first use.

As long as the box remains LAN-reachable, local-only mode can behave like a normal local web app.

### Example
If the user is on the home LAN and visits:

- `http://bob.local/notes`

then the app can:

- load from the box,
- talk to `/db` on the same origin,
- use PouchDB/IndexedDB locally,
- and continue syncing opportunistically while the box remains reachable.

## 5.2 Local-only mode weaker area: transport/security posture is lower than HTTPS mode
Local-only mode uses:

- HTTP, not HTTPS,
- `.local` local-only names,
- and no user-installed local CA by default.

So local-only mode should not be documented as if it provides the same transport or browser-trust posture as public HTTPS mode.

At minimum, docs and UI should not imply that local-only mode provides:

- trusted server identity equivalent to a validated HTTPS origin,
- encrypted transport equivalent to HTTPS,
- or browser security cues equivalent to HTTPS.

## 5.3 Local-only mode weaker area: reopen-offline should not be promised
Because local-only mode is HTTP-only, OurBox should **not** treat local-only mode as equivalent to the current ADR-0001 full PWA posture.

### Working assumption for this RFC
OurBox should assume that arbitrary `http://<tenant_id>.local` origins are **not** a reliable basis for promising:

- service-worker-backed installability,
- cached app-shell reloads after disconnect,
- or reopen-offline behavior equivalent to public HTTPS origins.

This assumption is the design basis for the RFC and must be verified against the browser matrix before ratification.

## 5.4 What local-only mode can still do after disconnect
If the page is already open and the app shell is already loaded, local-only mode may still support useful behavior after the box becomes unreachable:

- the page can continue running,
- the app can keep using already-open local state,
- and user edits can still be written to the local tenant replica.

That is **continue-running offline**.

This is useful and should be preserved.

## 5.5 What local-only mode should not claim
Local-only mode should not claim the same guarantee for **reopen offline**.

Examples that should **not** be documented as guaranteed in local-only mode:

- “Close the tab, turn off the box, come back later, and `http://bob.local/notes` will still load from cache.”
- “Install the app from `http://bob.local` and treat it as a full installable PWA.”
- “Reloading a local HTTP `.local` tenant origin while disconnected is part of the guaranteed shipped-app posture.”
- “Local-only mode provides the same browser security/trust experience as HTTPS mode.”

Those may work in some environments or browsers. They should not be the product promise.

---

## 6. Public custom-domain mode behavior

## 6.1 Public mode remains the canonical full-PWA mode
Public custom-domain mode keeps the existing intended posture:

- HTTPS tenant origins,
- TLS transport protection,
- browser secure-context behavior,
- service-worker-backed app shell caching,
- installable PWAs,
- and reopen-offline behavior after first successful load.

Examples:
- `https://bob.bobsdomain.com/notes`
- `https://alice.box.example.com/tasks`

For clarity:
- full host: `bob.bobsdomain.com`
  - `tenant_id = bob`
  - `box-host = bobsdomain.com`
- full host: `alice.box.example.com`
  - `tenant_id = alice`
  - `box-host = box.example.com`

This is where the current ADR-0001 / AD-0001 shipped-app posture continues to fit naturally.

## 6.2 Public mode should carry the stronger offline promise
In public custom-domain mode, OurBox can continue to target the stronger statement:

- after first successful load,
- the app can be reopened from browser cache,
- even when the box is unreachable,
- subject to normal browser storage-eviction constraints.

That is the mode where “offline-first PWA” should continue to mean what the current docs already imply.

---

## 7. Transition between local-only and public mode is an origin change

This is a crucial product consequence.

These are different origins:

- `http://bob.local`
- `https://bob.bobsdomain.com`

So moving from one to the other is **not** “the same browser app just with a prettier URL.”

It is an origin change.

That means:

- different IndexedDB storage bucket,
- different Cache Storage bucket,
- different service worker registration,
- different local browser persistence surface,
- and different transport/browser-trust posture.

## 7.1 Product consequence
The transition from local-only mode to public custom-domain mode should be treated as:

- a new origin bootstrap,
- followed by a sync/bootstrap from the tenant DB,
- not as transparent continuity of the same browser-local cache.

## 7.2 User consequence
The user may see the same tenant and the same data after sync, but the browser is not reusing the same origin-local state.

This needs to be explained honestly in product and engineering language.

---

## 8. Behavior summary matrix

| Dimension | Local-only mode | Public custom-domain mode |
|---|---|---|
| Full URL pattern | `http://<tenant_id>.local/<app_slug>` | `https://<tenant_id>.<box-host>/<app_slug>` |
| Full host pattern | `<tenant_id>.local` | `<tenant_id>.<box-host>` |
| Example full host | `bob.local` | `bob.box.example.com` |
| `tenant_id` derivation | leftmost DNS label of full host | leftmost DNS label of full host |
| `box-host` meaning | not used as a separate public suffix in the local tenant-host pattern | base host suffix after tenant label |
| Typical scope | local LAN only | LAN and/or internet |
| User prerequisites | functioning local network only | registered domain + public DNS + external routing |
| Vendor box identifier required | no | no |
| Full host carries tenant context | yes | yes |
| Path identifies app | yes | yes |
| Same-origin `/db` replication while box reachable | yes | yes |
| Shared local tenant replica per tenant origin | yes | yes |
| TLS transport authentication/confidentiality/integrity | no | yes/intended |
| Browser secure-context posture | not guaranteed | intended/required |
| Browser insecure-transport UI risk | yes | no, assuming valid HTTPS |
| Continue-running offline after box disconnect (already loaded tab) | plausible/expected | expected |
| Reopen offline after box disconnect | not guaranteed | intended/required |
| Full installable PWA posture | not guaranteed | intended/required |
| Browser storage continuity when switching modes | no; new origin | no; new origin relative to local mode |

---

## 9. Product-language implications

This RFC recommends a more precise product language split.

### 9.1 For local-only mode, say:
- local mode
- local-only mode
- joined-LAN mode
- zero-preparation LAN mode
- HTTP local mode

### 9.2 For public custom-domain mode, say:
- public mode
- custom-domain mode
- HTTPS mode
- full PWA mode

### 9.3 Avoid saying:
- “Both modes are the same except one is internal and one is external.”
- “Local `.local` mode provides the same offline guarantee as the HTTPS mode.”
- “Local-only mode provides the same transport security as public mode.”
- “Any shipped app is always installable as a PWA in either mode.”

The distinction matters.

---

## 10. Candidate implementation posture

This RFC does not define final requirements, but it recommends the following direction.

### 10.1 Local-only mode should optimize for:
- low-friction first use,
- same-origin tenant routing,
- local data continuity,
- opportunistic sync while box reachable,
- honest downgrade of PWA/offline claims,
- honest explanation that the mode is HTTP-only,
- and honest explanation that browser UI may mark the connection as insecure/plain HTTP.

### 10.2 Public custom-domain mode should optimize for:
- full HTTPS tenant-origin posture,
- TLS-backed browser trust cues,
- installable PWA behavior,
- service-worker-backed asset caching,
- reopen-offline behavior after first successful load,
- continuity with existing ADR-0001 language.

### 10.3 UI/UX should not pretend the modes are equivalent
The product should not present “Install app” or “available offline” messaging in local-only mode unless the browser matrix later proves that promise is supportable and the product chooses to make it.

The product should also avoid implying that HTTP local mode provides HTTPS-like security cues.

---

## Trade-offs

### Pros
- Preserves the zero-preparation LAN story users want.
- Preserves the canonical HTTPS tenant-origin story for public use.
- Keeps the host/path routing model coherent across both modes.
- Forces honesty about what “offline-first” means in each mode.
- Forces honesty about the transport/security downgrade in local HTTP mode.
- Avoids pushing requirements drift into AD-0001 and app specs.

### Cons
- Introduces two operationally different modes.
- User-facing hostname grammar differs between local-only and public mode.
- Transitioning from local-only to public mode is an origin change, not seamless browser-local continuity.
- Local-only mode lacks TLS and may trigger insecure browser UI.
- Some local behavior must be documented as “best effort” or “not guaranteed,” which is less elegant than a single-mode story.
- Some auth/session assumptions built around HTTPS may need explicit local-mode handling.

---

## Open Questions

1. **Browser matrix**
   - What is the actual behavior across current Safari, Chrome, Firefox, and Android/iOS browser variants for:
     - `http://<tenant>.local`
     - service worker availability
     - install prompts
     - homescreen behavior
     - reload/reopen semantics
     - browser insecure-transport UI treatment

2. **Local-mode UX**
   - Should local-only mode hide install affordances entirely?
   - Should it show a banner such as:
     - “For full offline/installable behavior, connect a public domain”?
   - Should it show explicit messaging such as:
     - “Local mode uses plain HTTP on your local network”?

3. **Reserved local hosts**
   - Should `ourbox.local` be the only reserved local non-tenant host?
   - Are other reserved local names needed (`admin`, `api`, `db`)?

4. **Concurrent support**
   - When public mode is enabled, should local-only mode remain enabled by default?
   - Or should that be operator-configurable?

5. **Local-mode auth/session posture**
   - What session strategy is appropriate for HTTP local mode?
   - Which HTTPS-oriented assumptions (for example around `Secure` cookies) need local-mode-specific handling?

6. **Future enhancement path**
   - If a later design introduces local HTTPS under a user-controlled public domain (for example via split-horizon DNS or another deliberate operator setup), does that become a third mode or an upgrade path for local-only mode?

7. **Spec language**
   - How should ADR-0001 and AD-0001 phrase “offline-first PWA” once local-only mode exists?
   - Do we split requirements into:
     - local-mode requirements, and
     - public-mode requirements?

---

## Next Steps

1. Complete browser matrix validation for local-only mode behavior and UI indicators.
2. Finalize local-mode auth/session posture decisions.
3. Refine and allocate any remaining mode-specific requirements where verification scope is still open.

---

## References

- ADR-0001: Purpose-build Offline‑First PWAs for All Shipped OurBox Apps
- ADR-0003: Standardize on Tenant as the OurBox OS Data Boundary Term
- ADR-0014: Adopt Two Access Modes: Local HTTP `.local` and Public HTTPS Custom-Domain
- AD-0001: OurBox OS Architecture Description
- SyRS-0001: OurBox OS System Requirements Specification
- SRS-0201: Gateway Software Requirements Specification
- docs/00-Glossary/Terms-and-Definitions.md

Informative external technical basis to validate during RFC review:
- URI syntax / host terminology
- Secure Contexts
- Service Workers
- IndexedDB origin model
- mDNS / `.local` behavior
