# Candidate: Tinode

**Status:** Exploring  
**License:** Open source (see upstream)  
**Source:** URL  
**Created:** YYYY-MM-DD  
**Updated:** YYYY-MM-DD

---

## Project summary

Messaging platform with web client; positioned as an open-source WhatsApp/Telegram-style stack.

## Why it is interesting for OurBox

- Purpose-built messaging (DMs, groups)
- Ships a web client
- Supports attachments via upload adapters

## Fit vs criteria

- Web-first UX: Yes
- Self-hosting simplicity: Moderate (DB required)
- File attachments (incl. audio files): Yes
- Voice notes as recordings: Unclear; WebRTC for calls with extra config

## Integration shape (high-level)

- Wrap as first-class OurBox app

## Licensing notes

- Verify exact license and compatibility

## Risks

- Requires DB (MySQL/Postgres/Mongo)
- Calling requires TURN/STUN configuration

## Decision status

- Exploring
