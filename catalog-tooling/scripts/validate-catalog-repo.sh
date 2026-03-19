#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS="${ROOT}/scripts"

log() { echo "[$(date -Is)] $*"; }

log "Validating script syntax"
bash -n \
  "${SCRIPTS}/render-catalog-bundle.sh" \
  "${SCRIPTS}/check-catalog-bundle-smoke.sh" \
  "${SCRIPTS}/check-image-refs-exist.sh" \
  "${SCRIPTS}/check-publish-workflow.sh" \
  "${SCRIPTS}/publish-catalog-bundle.sh" \
  "${SCRIPTS}/validate-catalog-repo.sh"

log "Validating catalog-row helper syntax"
python3 -m py_compile "${SCRIPTS}/render-catalog-rows.py"

log "Validating publish workflow invariants"
bash "${SCRIPTS}/check-publish-workflow.sh"

log "Validating and rendering catalog bundle (smoke test)"
bash "${SCRIPTS}/check-catalog-bundle-smoke.sh"

log "Validating referenced images exist"
bash "${SCRIPTS}/check-image-refs-exist.sh"

log "All validations passed"
