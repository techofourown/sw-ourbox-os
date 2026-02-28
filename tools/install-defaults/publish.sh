#!/usr/bin/env bash
set -euo pipefail

log() { echo "[$(date -Is)] $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIST_DIR="${ROOT}/dist"
ARTIFACT_TYPE="application/vnd.techofourown.ourbox.install-defaults.v1.tar+gzip"
REF_BASE="ghcr.io/techofourown/sw-ourbox-os/install-defaults"

TAG="${TAG:-${1:-edge}}"
[[ -n "${TAG}" ]] || die "TAG is required"

command -v oras >/dev/null 2>&1 || die "oras is required (https://oras.land/)"

log "Building install-defaults bundle"
"${ROOT}/tools/install-defaults/build.sh"
# shellcheck disable=SC1091
source "${DIST_DIR}/install-defaults.meta.env"

REF="${REF_BASE}:${TAG}"
PUSH_LOG="${DIST_DIR}/install-defaults.push.log"

pushd "${ROOT}" >/dev/null
set +e
OUT="$(oras push "${REF}" \
  --artifact-type "${ARTIFACT_TYPE}" \
  dist/install-defaults.tar.gz:application/gzip \
  --annotation "org.opencontainers.image.source=${OURBOX_INSTALL_DEFAULTS_SOURCE}" \
  --annotation "org.opencontainers.image.revision=${OURBOX_INSTALL_DEFAULTS_REVISION}" \
  --annotation "org.opencontainers.image.version=${OURBOX_INSTALL_DEFAULTS_VERSION}" \
  --annotation "org.opencontainers.image.created=${OURBOX_INSTALL_DEFAULTS_CREATED}" \
  --annotation "techofourown.artifact.kind=install-defaults" \
  2>&1)"
STATUS=$?
set -e
popd >/dev/null

printf '%s\n' "${OUT}" | tee "${PUSH_LOG}"

if [[ "${STATUS}" -ne 0 ]]; then
  die "oras push failed (exit ${STATUS}); see ${PUSH_LOG}"
fi

DIGEST="$(printf '%s\n' "${OUT}" | grep -Eo 'sha256:[0-9a-f]{64}' | tail -n1)"
[[ -n "${DIGEST}" ]] || die "Failed to capture digest from oras output"

PINNED="${REF_BASE}@${DIGEST}"
REF_FILE="${DIST_DIR}/install-defaults.ref"
printf '%s\n' "${PINNED}" | tee "${REF_FILE}"

log "Pinned ref: ${PINNED}"
