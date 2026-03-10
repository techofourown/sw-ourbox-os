# New Hardware Target Checklist

## Access modes
- [ ] Local-only mode support documented.
- [ ] Local-only mode host grammar documented (`<tenant_id>.local`).
- [ ] Local-only mode HTTP-only posture documented.
- [ ] Local landing host documented if present (`ourbox.local`).
- [ ] Public custom-domain mode support documented.
- [ ] Public custom-domain host grammar documented (`<tenant_id>.<box-host>`).
- [ ] Public DNS/external routing prerequisites documented.
- [ ] Target-specific limitations documented.

## Commonality vs divergence
Access-mode realization is a named seam above the hardware boundary and SHALL be documented as commonality/divergence.

## Required docs to create or update
Include target access-mode docs when target behavior differs or needs explanation.
