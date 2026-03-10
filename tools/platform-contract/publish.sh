#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIST_DIR="${ROOT}/dist"

TAG="${1:-edge}"
REF="ghcr.io/techofourown/sw-ourbox-os/platform-contract:${TAG}"
ARTIFACT_REPO="ghcr.io/techofourown/sw-ourbox-os/platform-contract"
ARTIFACT_TYPE="application/vnd.techofourown.ourbox.platform-contract.v1.tar+gzip"
BLOB_REL="dist/platform-contract.tar.gz"
PUSH_LOG="${DIST_DIR}/platform-contract.push.log"

command -v oras >/dev/null 2>&1 || {
  echo "oras is required (https://oras.land/). Install it on your build host/CI." >&2
  exit 1
}

command -v node >/dev/null 2>&1 || {
  echo "node is required for schema validation of publish records." >&2
  exit 1
}

"${ROOT}/tools/platform-contract/build.sh"
# shellcheck disable=SC1090
source "${DIST_DIR}/platform-contract.meta.env"

pushd "${ROOT}" >/dev/null
set +e
OUT="$(oras push "${REF}" \
  --artifact-type "${ARTIFACT_TYPE}" \
  "${BLOB_REL}:application/gzip" \
  --annotation "org.opencontainers.image.source=${OURBOX_PLATFORM_CONTRACT_SOURCE}" \
  --annotation "org.opencontainers.image.revision=${OURBOX_PLATFORM_CONTRACT_REVISION}" \
  --annotation "org.opencontainers.image.version=${OURBOX_PLATFORM_CONTRACT_VERSION}" \
  --annotation "org.opencontainers.image.created=${OURBOX_PLATFORM_CONTRACT_CREATED}" \
  --annotation "techofourown.artifact.kind=platform-contract" \
  2>&1)"
STATUS=$?
set -e
popd >/dev/null

printf '%s\n' "${OUT}" | tee "${PUSH_LOG}"

if [[ "${STATUS}" -ne 0 ]]; then
  echo "" >&2
  echo "ERROR: oras push failed (exit ${STATUS})" >&2
  echo "See: ${PUSH_LOG}" >&2
  exit "${STATUS}"
fi

DIGEST="$(printf '%s\n' "${OUT}" | grep -Eo 'sha256:[0-9a-f]{64}' | tail -n1)"
if [[ -z "${DIGEST}" ]]; then
  echo "Failed to capture digest from oras output" >&2
  exit 1
fi

PINNED="${ARTIFACT_REPO}@${DIGEST}"
printf '%s\n' "${PINNED}" | tee "${DIST_DIR}/platform-contract.ref"

python3 "${ROOT}/tools/publish-records/write-publish-record.py" \
  --artifact-family platform-contract \
  --artifact-type "${ARTIFACT_TYPE}" \
  --artifact-repo "${ARTIFACT_REPO}" \
  --artifact-ref "${REF}" \
  --artifact-pinned-ref "${PINNED}" \
  --artifact-digest "${DIGEST}" \
  --source-repo "${OURBOX_PLATFORM_CONTRACT_SOURCE}" \
  --source-commit "${OURBOX_PLATFORM_CONTRACT_REVISION}" \
  --source-version "${OURBOX_PLATFORM_CONTRACT_VERSION}" \
  --created "${OURBOX_PLATFORM_CONTRACT_CREATED}" \
  --artifact-metadata-env "${DIST_DIR}/platform-contract.meta.env" \
  --input PROFILE_DEFAULT=demo-apps \
  --dist-file payload=dist/platform-contract.tar.gz \
  --dist-file meta_env=dist/platform-contract.meta.env \
  --dist-file push_log=dist/platform-contract.push.log \
  --dist-file pinned_ref=dist/platform-contract.ref \
  --output "${DIST_DIR}/platform-contract.publish-record.json"

node "${ROOT}/tools/policy/validate-schemas.cjs" --publish-record dist/platform-contract.publish-record.json

echo ""
echo "Pinned ref:"
echo "  ${PINNED}"
