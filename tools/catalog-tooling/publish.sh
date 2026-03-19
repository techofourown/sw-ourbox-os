#!/usr/bin/env bash
set -euo pipefail

log() { echo "[$(date -Is)] $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIST_DIR="${ROOT}/dist"
ARTIFACT_TYPE="application/vnd.techofourown.ourbox.catalog-tooling.v1.tar+gzip"
REF_BASE="ghcr.io/techofourown/sw-ourbox-os/catalog-tooling"

TAG="${TAG:-${1:-edge}}"
[[ -n "${TAG}" ]] || die "TAG is required"

command -v oras >/dev/null 2>&1 || die "oras is required (https://oras.land/)"
command -v node >/dev/null 2>&1 || die "node is required for schema validation of publish records"

log "Building catalog-tooling bundle"
"${ROOT}/tools/catalog-tooling/build.sh"
# shellcheck disable=SC1091
source "${DIST_DIR}/catalog-tooling.meta.env"

REF="${REF_BASE}:${TAG}"
PUSH_LOG="${DIST_DIR}/catalog-tooling.push.log"

pushd "${ROOT}" >/dev/null
set +e
OUT="$(oras push "${REF}" \
  --artifact-type "${ARTIFACT_TYPE}" \
  dist/catalog-tooling.tar.gz:application/gzip \
  --annotation "org.opencontainers.image.source=${OURBOX_CATALOG_TOOLING_SOURCE}" \
  --annotation "org.opencontainers.image.revision=${OURBOX_CATALOG_TOOLING_REVISION}" \
  --annotation "org.opencontainers.image.version=${OURBOX_CATALOG_TOOLING_VERSION}" \
  --annotation "org.opencontainers.image.created=${OURBOX_CATALOG_TOOLING_CREATED}" \
  --annotation "techofourown.artifact.kind=catalog-tooling" \
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
REF_FILE="${DIST_DIR}/catalog-tooling.ref"
printf '%s\n' "${PINNED}" | tee "${REF_FILE}"

python3 "${ROOT}/tools/publish-records/write-publish-record.py" \
  --artifact-family catalog-tooling \
  --artifact-type "${ARTIFACT_TYPE}" \
  --artifact-repo "${REF_BASE}" \
  --artifact-ref "${REF}" \
  --artifact-pinned-ref "${PINNED}" \
  --artifact-digest "${DIGEST}" \
  --source-repo "${OURBOX_CATALOG_TOOLING_SOURCE}" \
  --source-commit "${OURBOX_CATALOG_TOOLING_REVISION}" \
  --source-version "${OURBOX_CATALOG_TOOLING_VERSION}" \
  --created "${OURBOX_CATALOG_TOOLING_CREATED}" \
  --artifact-metadata-env "${DIST_DIR}/catalog-tooling.meta.env" \
  --input SCRIPT_COUNT="${SCRIPT_COUNT}" \
  --input SCRIPT_NAMES="${SCRIPT_NAMES}" \
  --dist-file payload=dist/catalog-tooling.tar.gz \
  --dist-file meta_env=dist/catalog-tooling.meta.env \
  --dist-file push_log=dist/catalog-tooling.push.log \
  --dist-file pinned_ref=dist/catalog-tooling.ref \
  --output "${DIST_DIR}/catalog-tooling.publish-record.json"

node "${ROOT}/tools/policy/validate-schemas.cjs" --publish-record dist/catalog-tooling.publish-record.json

log "Pinned ref: ${PINNED}"
