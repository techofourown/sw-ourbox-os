# Terms and Definitions

## Purpose
This document defines canonical terms and acronyms used across OurBox OS requirements, architecture, design, and verification artifacts.

This glossary is the vocabulary authority for host-routing terms, access modes, and requirement language.

## OurBox OS product and architecture terms (normative)

### full host
The entire host portion of a URL before any port and before the path.

### box-host
In public custom-domain mode, the public custom-domain base host suffix after the tenant label.

Pattern: `<tenant_id>.<box-host>`

### tenant host
The full host used to address a tenant.

Supported patterns:
- local-only mode: `<tenant_id>.local`
- public custom-domain mode: `<tenant_id>.<box-host>`

### local landing host
A reserved non-tenant local host used for setup/admin entry flows.

Recommended pattern: `ourbox.local`

### Local-only mode
HTTP-only tenant-host mode for joined-LAN access.

Patterns:
- `http://<tenant_id>.local/<app_slug>`
- `http://<tenant_id>.local/db`
- optional `http://ourbox.local/`

Implications:
- no TLS transport authentication,
- no TLS transport confidentiality/integrity,
- browser insecure-transport UI may appear,
- secure-context browser features are not automatically available.

### Public custom-domain mode
HTTPS/TLS mode for public custom-domain tenant-host access.

Patterns:
- `https://<tenant_id>.<box-host>/<app_slug>`
- `https://<tenant_id>.<box-host>/db`

### tenant_id
Stable identifier for a tenant.

Constraints:
- SHALL be lowercase.
- SHALL be safe for use in DNS labels.
- SHALL be safe for use as the leftmost DNS label of a tenant host.
- SHALL be safe for use in CouchDB database names.

### Tenant origin
A tenant-scoped browser origin.

Supported patterns by mode:
- local-only mode: `http://<tenant_id>.local/...`
- public custom-domain mode: `https://<tenant_id>.<box-host>/...`

Across both modes:
- the full host carries tenant context,
- `tenant_id` is derived from the leftmost DNS label of the full host,
- the path identifies app context.

`http://bob.local` and `https://bob.example.com` are different origins and therefore do not share IndexedDB, Cache Storage, service workers, or local tenant replicas.

### Gateway
Tenant-facing HTTP service surface that routes by full host and path.

- local-only mode: serves HTTP tenant hosts and optional local landing host.
- public custom-domain mode: terminates TLS and serves HTTPS tenant hosts.
- exposes same-origin replication at `/db` in both modes.

### Progressive Web App (PWA)
Shipped apps are PWA-capable. Full installable-PWA posture (secure context, service-worker-backed reopen-offline) is tied to public custom-domain mode. Local-only mode is HTTP-only and does not guarantee equivalent behavior.
