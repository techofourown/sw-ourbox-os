#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIST_DIR="${ROOT}/dist"

TAG="${1:-edge}"
REF="ghcr.io/techofourown/sw-ourbox-os/platform-contract:${TAG}"
ARTIFACT_TYPE="application/vnd.techofourown.ourbox.platform-contract.v1.tar+gzip"

command -v oras >/dev/null 2>&1 || {
  echo "oras is required (https://oras.land/). Install it on your build host/CI." >&2
  exit 1
}

"${ROOT}/tools/platform-contract/build.sh"
# shellcheck disable=SC1090
source "${DIST_DIR}/platform-contract.meta.env"

OUT="$({
  oras push "${REF}" \
    --artifact-type "${ARTIFACT_TYPE}" \
    "${DIST_DIR}/platform-contract.tar.gz:application/gzip" \
    --annotation "org.opencontainers.image.source=${OURBOX_PLATFORM_CONTRACT_SOURCE}" \
    --annotation "org.opencontainers.image.revision=${OURBOX_PLATFORM_CONTRACT_REVISION}" \
    --annotation "org.opencontainers.image.version=${OURBOX_PLATFORM_CONTRACT_VERSION}" \
    --annotation "org.opencontainers.image.created=${OURBOX_PLATFORM_CONTRACT_CREATED}" \
    --annotation "techofourown.artifact.kind=platform-contract"
} 2>&1)"

printf '%s\n' "${OUT}"

DIGEST="$(printf '%s\n' "${OUT}" | awk '/Digest:/ {print $2}' | tail -n1)"
if [[ -z "${DIGEST}" ]]; then
  echo "Failed to capture digest from oras output" >&2
  exit 1
fi

PINNED="ghcr.io/techofourown/sw-ourbox-os/platform-contract@${DIGEST}"
printf '%s\n' "${PINNED}" | tee "${DIST_DIR}/platform-contract.ref"

echo ""
echo "Pinned ref:"
echo "  ${PINNED}"
