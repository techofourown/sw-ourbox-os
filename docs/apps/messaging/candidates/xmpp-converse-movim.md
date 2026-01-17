# Candidate: XMPP server + Converse.js / Movim

**Status:** Exploring  
**License:** Open standard + OSS components (see upstream)  
**Source:** URL  
**Created:** YYYY-MM-DD  
**Updated:** YYYY-MM-DD

---

## Project summary

Standards-based messaging via an XMPP server with a hosted web client (Converse.js or Movim).

## Why it is interesting for OurBox

- Open standard with long-term interoperability
- Web client provides browser-first UX without native apps
- Optional compatibility with existing XMPP clients

## Fit vs criteria

- Web-first UX: Yes
- Self-hosting simplicity: Moderate (server + web client)
- File attachments: Supported via XMPP extensions/components
- Voice notes as recordings: Varies by client

## Integration shape (high-level)

- Host XMPP server and provide a managed web client

## Licensing notes

- Verify component licenses and server selection

## Risks

- More moving parts than a single bundled stack
- File sharing requires correct XMPP extensions

## Decision status

- Exploring
