#!/usr/bin/env bash
set -euo pipefail

log() { echo "[$(date -Is)] $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIST_DIR="${ROOT}/dist"
ARTIFACT_TYPE="application/vnd.techofourown.ourbox.substrate.v1.tar+gzip"
REF_BASE="ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate"

ARCH="${ARCH:-${1:-}}"
TAG="${TAG:-${2:-edge}}"

[[ -n "${ARCH}" ]] || die "ARCH is required (arm64|amd64)"
case "${ARCH}" in
  arm64|amd64) : ;;
  *) die "Unsupported ARCH: ${ARCH} (expected arm64 or amd64)" ;;
esac

command -v oras >/dev/null 2>&1 || die "oras is required (https://oras.land/)"
command -v node >/dev/null 2>&1 || die "node is required for schema validation of publish records"
[[ -z "${OURBOX_APPLICATION_CATALOG_REF:-}" ]] \
  || die "ourbox-substrate publish no longer accepts OURBOX_APPLICATION_CATALOG_REF"
[[ -z "${OURBOX_ALLOW_FIXTURE_APPLICATION_CATALOG:-}" ]] \
  || die "ourbox-substrate publish no longer uses OURBOX_ALLOW_FIXTURE_APPLICATION_CATALOG"

log "Building bundle for ${ARCH}"
ARCH="${ARCH}" "${ROOT}/tools/ourbox-substrate/build.sh"
# shellcheck disable=SC1090
source "${DIST_DIR}/ourbox-substrate.meta.env"

REF="${REF_BASE}:${TAG}-${ARCH}"
PUSH_LOG="${DIST_DIR}/ourbox-substrate.${ARCH}.push.log"

pushd "${ROOT}" >/dev/null
set +e
OUT="$(oras push "${REF}" \
  --artifact-type "${ARTIFACT_TYPE}" \
  dist/ourbox-substrate.tar.gz:application/gzip \
  --annotation "org.opencontainers.image.source=${OURBOX_SUBSTRATE_SOURCE}" \
  --annotation "org.opencontainers.image.revision=${OURBOX_SUBSTRATE_REVISION}" \
  --annotation "org.opencontainers.image.version=${OURBOX_SUBSTRATE_VERSION}" \
  --annotation "org.opencontainers.image.created=${OURBOX_SUBSTRATE_CREATED}" \
  --annotation "techofourown.artifact.kind=ourbox-substrate" \
  --annotation "techofourown.substrate.arch=${ARCH}" \
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
REF_FILE="${DIST_DIR}/ourbox-substrate.${ARCH}.ref"
printf '%s\n' "${PINNED}" | tee "${REF_FILE}"

K3S_VERSION="$(awk -F= '/^K3S_VERSION=/{print $2}' "${ROOT}/tools/ourbox-substrate/versions.env")"
OURBOX_PLATFORM_PROFILE="$(tar -xOzf "${DIST_DIR}/ourbox-substrate.tar.gz" manifest.env | awk -F= '/^OURBOX_PLATFORM_PROFILE=/{print $2}')"
OURBOX_PLATFORM_IMAGES_LOCK_SHA256="$(tar -xOzf "${DIST_DIR}/ourbox-substrate.tar.gz" manifest.env | awk -F= '/^OURBOX_PLATFORM_IMAGES_LOCK_SHA256=/{print $2}')"

python3 "${ROOT}/tools/publish-records/write-publish-record.py" \
  --artifact-family ourbox-substrate \
  --artifact-type "${ARTIFACT_TYPE}" \
  --artifact-repo "${REF_BASE}" \
  --artifact-ref "${REF}" \
  --artifact-pinned-ref "${PINNED}" \
  --artifact-digest "${DIGEST}" \
  --source-repo "${OURBOX_SUBSTRATE_SOURCE}" \
  --source-commit "${OURBOX_SUBSTRATE_REVISION}" \
  --source-version "${OURBOX_SUBSTRATE_VERSION}" \
  --created "${OURBOX_SUBSTRATE_CREATED}" \
  --artifact-metadata-env "${DIST_DIR}/ourbox-substrate.meta.env" \
  --input K3S_VERSION="${K3S_VERSION}" \
  --input OURBOX_PLATFORM_PROFILE="${OURBOX_PLATFORM_PROFILE}" \
  --input OURBOX_PLATFORM_IMAGES_LOCK_SHA256="${OURBOX_PLATFORM_IMAGES_LOCK_SHA256}" \
  --dist-file payload=dist/ourbox-substrate.tar.gz \
  --dist-file meta_env=dist/ourbox-substrate.meta.env \
  --dist-file push_log="dist/ourbox-substrate.${ARCH}.push.log" \
  --dist-file pinned_ref="dist/ourbox-substrate.${ARCH}.ref" \
  --output "${DIST_DIR}/ourbox-substrate.${ARCH}.publish-record.json"

node "${ROOT}/tools/policy/validate-schemas.cjs" --publish-record "dist/ourbox-substrate.${ARCH}.publish-record.json"

log "Pinned ref: ${PINNED}"
