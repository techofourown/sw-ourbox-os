#!/usr/bin/env bash
set -euo pipefail

log() { echo "[$(date -Is)] $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

need_cmd() { command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIST_DIR="${ROOT}/dist"
REF_BASE="ghcr.io/techofourown/sw-ourbox-os/platform-contract"

RELEASE_TAG="${RELEASE_TAG:-${1:-}}"
SOURCE_PINNED_REF="${PROMOTE_SOURCE_PINNED_REF:-}"
SOURCE_REF="${PROMOTE_SOURCE_REF:-${SOURCE_PINNED_REF}}"

[[ -n "${RELEASE_TAG}" ]] || die "RELEASE_TAG is required"
[[ -n "${SOURCE_PINNED_REF}" ]] || die "PROMOTE_SOURCE_PINNED_REF is required"

need_cmd oras

SOURCE_REPO="${SOURCE_PINNED_REF%@*}"
IMMUTABLE_DIGEST="${SOURCE_PINNED_REF##*@}"
[[ "${SOURCE_REPO}" == "${REF_BASE}" ]] \
  || die "PROMOTE_SOURCE_PINNED_REF repo mismatch: expected ${REF_BASE}, got ${SOURCE_REPO}"
[[ "${IMMUTABLE_DIGEST}" =~ ^sha256:[0-9a-f]{64}$ ]] \
  || die "PROMOTE_SOURCE_PINNED_REF must contain a digest-pinned ref"

TARGET_REF="${REF_BASE}:${RELEASE_TAG}"
PINNED_REF="${REF_BASE}@${IMMUTABLE_DIGEST}"

mkdir -p "${DIST_DIR}"

existing_target_digest="$(oras resolve "${TARGET_REF}" 2>/dev/null || true)"
if [[ -n "${existing_target_digest}" && "${existing_target_digest}" != "${IMMUTABLE_DIGEST}" ]]; then
  log "Tag ${TARGET_REF} already promoted to ${existing_target_digest}; skipping"
  printf '%s\n' "${SOURCE_REF}" > "${DIST_DIR}/platform-contract.promote.source.ref"
  printf '%s\n' "${PINNED_REF}" > "${DIST_DIR}/platform-contract.promote.digest.ref"
  printf '%s\n' "${TARGET_REF}" > "${DIST_DIR}/platform-contract.promote.target.ref"
  exit 0
fi

log "Promoting ${PINNED_REF} -> ${TARGET_REF}"
oras tag "${PINNED_REF}" "${RELEASE_TAG}" >/dev/null

printf '%s\n' "${SOURCE_REF}" > "${DIST_DIR}/platform-contract.promote.source.ref"
printf '%s\n' "${PINNED_REF}" > "${DIST_DIR}/platform-contract.promote.digest.ref"
printf '%s\n' "${TARGET_REF}" > "${DIST_DIR}/platform-contract.promote.target.ref"

log "Promoted ${PINNED_REF} -> ${TARGET_REF}"
