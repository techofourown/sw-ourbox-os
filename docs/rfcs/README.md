# RFCs (Requests for Comment)

This folder contains **RFCs**: structured memos used to explore and propose changes to OurBox OS
*before* we commit to a decision.

RFCs are how we think in public, reduce ambiguity, and build shared understanding across product,
design, and engineering.

## What belongs here

RFCs in `sw-ourbox-os` are specifically for **OurBox OS product and platform** topics, including:

- Canonical bundled app suite (Email, Notes, Contacts, Photos, Messaging, Settings, etc.)
- App model: what an "app" is, how apps are discovered/installed/removed
- Launcher UX model and navigation rules
- Identity/auth/session model
- Shared data foundations (e.g., contacts as a shared resource)
- Permissions and isolation model between apps/services
- Resource/lifecycle policies (always-on vs on-demand apps)
- Backups/export/migration user experience (product-level)
- Remote access posture (product-level), security and trust model (product-level)

## What does NOT belong here

Put these topics in their owning repos instead:

- Hardware design decisions -> `hw-*` repos (e.g., `hw-ourbox-mini`)
- Bootable image build decisions -> `img-*` repos (e.g., `img-ourbox-mini-rpi`)
- Organization governance/policy -> `org-*` repos
- Marketing site content -> `web-*` repos

If the memo is fundamentally about "what the product should do," it belongs here.  
If it is fundamentally about "how a specific device/image is constructed," it belongs elsewhere.

## RFC lifecycle (how we use these documents)

1. **Draft**
   - Start with the template: `docs/rfcs/0000-template.md`
   - Open a PR early; use the PR as the discussion thread.

2. **Discussion**
   - Iterate based on review comments, experiments, and constraints we uncover.

3. **Accepted / Rejected / Withdrawn**
   - If an RFC concludes with a firm choice we intend to follow, we promote that choice into an ADR
     under `docs/decisions/`.
   - RFCs can be accepted as "directionally approved" even if implementation details remain open.

**Rule:** RFCs propose; **ADRs decide**.

## File naming and numbering

RFC filenames must follow:

`RFC-XXXX-short-descriptive-slug.md`

Examples:
- `RFC-0001-canonical-app-suite.md`
- `RFC-0002-app-catalog-and-distribution.md`
- `RFC-0003-email-app.md`

Notes:
- `XXXX` is zero-padded.
- Use a short, hyphenated slug.
- One RFC = one topic. If it gets too big, split it.

## Writing guidelines (what "good" looks like)

- Write in plain language first, technical detail second.
- Start with the problem and constraints before proposing solutions.
- Include trade-offs and what we are giving up.
- Call out open questions explicitly.
- Link to related RFCs and any ADRs that result from this work.
- Avoid "we decided…" language in RFCs. That belongs in an ADR.

## Cross-linking

- If an RFC leads to an ADR, add a link to the ADR in the RFC's **References** section.
- ADRs should link back to their originating RFC(s).

## Template

Use: `docs/rfcs/0000-template.md`
