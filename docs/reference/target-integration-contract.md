# Target Integration Contract

## Scope
This contract defines cross-target common seams for platform integration, including gateway behavior, data/replication behavior, and access-mode realization.

## Required common seams

### 5.x Access-mode realization
Targets SHALL document and implement:
- local-only mode host grammar: `<tenant_id>.local`,
- public custom-domain mode host grammar: `<tenant_id>.<box-host>`,
- local-only mode HTTP-only posture,
- public custom-domain mode HTTPS/TLS posture,
- any limitations or unsupported combinations.

Targets SHALL state:
- how local-only tenant hosts are realized,
- whether `ourbox.local` is exposed,
- how public custom-domain mode is enabled,
- operator prerequisites for public mode.

## Conformance questions
- How does the target realize local-only mode?
- How does the target realize public custom-domain mode?
- Are there target-specific limitations in either mode?
