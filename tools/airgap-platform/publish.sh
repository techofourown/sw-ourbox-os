#!/usr/bin/env bash
set -euo pipefail

log() { echo "[$(date -Is)] $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIST_DIR="${ROOT}/dist"
ARTIFACT_TYPE="application/vnd.techofourown.ourbox.airgap-platform.v1.tar+gzip"
REF_BASE="ghcr.io/techofourown/sw-ourbox-os/airgap-platform"

ARCH="${ARCH:-${1:-}}"
TAG="${TAG:-${2:-edge}}"

[[ -n "${ARCH}" ]] || die "ARCH is required (arm64|amd64)"
case "${ARCH}" in
  arm64|amd64) : ;;
  *) die "Unsupported ARCH: ${ARCH} (expected arm64 or amd64)" ;;
esac

command -v oras >/dev/null 2>&1 || die "oras is required (https://oras.land/)"

log "Building bundle for ${ARCH}"
ARCH="${ARCH}" "${ROOT}/tools/airgap-platform/build.sh"
# shellcheck disable=SC1090
source "${DIST_DIR}/airgap-platform.meta.env"

REF="${REF_BASE}:${TAG}-${ARCH}"
PUSH_LOG="${DIST_DIR}/airgap-platform.${ARCH}.push.log"

pushd "${ROOT}" >/dev/null
set +e
OUT="$(oras push "${REF}" \
  --artifact-type "${ARTIFACT_TYPE}" \
  dist/airgap-platform.tar.gz:application/gzip \
  --annotation "org.opencontainers.image.source=${OURBOX_AIRGAP_PLATFORM_SOURCE}" \
  --annotation "org.opencontainers.image.revision=${OURBOX_AIRGAP_PLATFORM_REVISION}" \
  --annotation "org.opencontainers.image.version=${OURBOX_AIRGAP_PLATFORM_VERSION}" \
  --annotation "org.opencontainers.image.created=${OURBOX_AIRGAP_PLATFORM_CREATED}" \
  --annotation "techofourown.artifact.kind=airgap-platform" \
  --annotation "techofourown.airgap.arch=${ARCH}" \
  2>&1)"
STATUS=$?
set -e
popd >/dev/null

printf '%s
' "${OUT}" | tee "${PUSH_LOG}"

if [[ "${STATUS}" -ne 0 ]]; then
  die "oras push failed (exit ${STATUS}); see ${PUSH_LOG}"
fi

DIGEST="$(printf '%s\n' "${OUT}" | grep -Eo 'sha256:[0-9a-f]{64}' | tail -n1)"
[[ -n "${DIGEST}" ]] || die "Failed to capture digest from oras output"

PINNED="${REF_BASE}@${DIGEST}"
REF_FILE="${DIST_DIR}/airgap-platform.${ARCH}.ref"
printf '%s
' "${PINNED}" | tee "${REF_FILE}"

log "Pinned ref: ${PINNED}"
