# Target Integration Contract

## 1. Purpose
Defines seams every hardware target must satisfy above the hardware boundary.

## 2. Scope
Includes platform contract consumption, persistence, bootstrap, observability, and access-mode realization.

## 5. Required common seams

### 5.1 Platform contract consumption
Target consumes approved platform contract artifacts.

### 5.2 Access-mode realization
Target SHALL document and realize:
- local-only mode support and host grammar (`http://<tenant_id>.local/...`),
- whether local landing host `ourbox.local` is exposed,
- local-only mode HTTP-only posture,
- public custom-domain mode support and host grammar (`https://<tenant_id>.<box-host>/...`),
- public-mode operator prerequisites (DNS, routing, TLS),
- any unsupported combinations or limitations.

### 5.3 Routing posture
Target SHALL support mode-appropriate gateway routing for `/<app_slug>`, `/db`, and `/api/...`.

## 8. Conformance questions
- How does the target realize local-only mode?
- How does the target realize public custom-domain mode?
- Are there target-specific limitations in either mode?
