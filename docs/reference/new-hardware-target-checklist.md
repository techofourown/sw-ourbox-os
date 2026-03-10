# New Hardware Target Checklist

## Access modes
- [ ] Local-only mode support documented
- [ ] Local-only mode host grammar documented (`<tenant_id>.local`)
- [ ] Local-only mode HTTP-only posture documented
- [ ] Local landing host documented if present (`ourbox.local`)
- [ ] Public custom-domain mode support documented
- [ ] Public custom-domain host grammar documented (`<tenant_id>.<box-host>`)
- [ ] Public DNS/external routing prerequisites documented
- [ ] Any target-specific limitations documented

## Commonality vs divergence
Access-mode realization is a named seam above the hardware boundary and must not be treated as ad hoc target behavior.

## Required docs to create or update
Include target access-mode documentation whenever target behavior differs, is limited, or requires explicit operator prerequisites.
