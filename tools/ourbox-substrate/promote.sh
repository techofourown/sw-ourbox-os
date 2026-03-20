#!/usr/bin/env bash
set -euo pipefail

log() { echo "[$(date -Is)] $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

need_cmd() { command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIST_DIR="${ROOT}/dist"
REF_BASE="ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate"

ARCH="${ARCH:-${1:-}}"
RELEASE_TAG="${RELEASE_TAG:-${2:-}}"
SOURCE_PINNED_REF="${PROMOTE_SOURCE_PINNED_REF:-}"
SOURCE_REF="${PROMOTE_SOURCE_REF:-${SOURCE_PINNED_REF}}"

[[ -n "${ARCH}" ]] || die "ARCH is required (arm64|amd64)"
[[ -n "${RELEASE_TAG}" ]] || die "RELEASE_TAG is required"
[[ -n "${SOURCE_PINNED_REF}" ]] || die "PROMOTE_SOURCE_PINNED_REF is required"

case "${ARCH}" in
  arm64|amd64) : ;;
  *) die "Unsupported ARCH: ${ARCH} (expected arm64 or amd64)" ;;
esac

need_cmd oras

SOURCE_REPO="${SOURCE_PINNED_REF%@*}"
IMMUTABLE_DIGEST="${SOURCE_PINNED_REF##*@}"
[[ "${SOURCE_REPO}" == "${REF_BASE}" ]] \
  || die "PROMOTE_SOURCE_PINNED_REF repo mismatch: expected ${REF_BASE}, got ${SOURCE_REPO}"
[[ "${IMMUTABLE_DIGEST}" =~ ^sha256:[0-9a-f]{64}$ ]] \
  || die "PROMOTE_SOURCE_PINNED_REF must contain a digest-pinned ref"

TARGET_TAG="${RELEASE_TAG}-${ARCH}"
TARGET_REF="${REF_BASE}:${TARGET_TAG}"
PINNED_REF="${REF_BASE}@${IMMUTABLE_DIGEST}"

mkdir -p "${DIST_DIR}"

existing_target_digest="$(oras resolve "${TARGET_REF}" 2>/dev/null || true)"
if [[ -n "${existing_target_digest}" && "${existing_target_digest}" != "${IMMUTABLE_DIGEST}" ]]; then
  die "Target immutable tag ${TARGET_REF} already points to ${existing_target_digest}, not ${IMMUTABLE_DIGEST}"
fi

log "Promoting ${PINNED_REF} -> ${TARGET_REF}"
oras tag "${PINNED_REF}" "${TARGET_TAG}" >/dev/null

printf '%s\n' "${SOURCE_REF}" > "${DIST_DIR}/ourbox-substrate.${ARCH}.promote.source.ref"
printf '%s\n' "${PINNED_REF}" > "${DIST_DIR}/ourbox-substrate.${ARCH}.promote.digest.ref"
printf '%s\n' "${TARGET_REF}" > "${DIST_DIR}/ourbox-substrate.${ARCH}.promote.target.ref"

log "Promoted ${PINNED_REF} -> ${TARGET_REF}"
