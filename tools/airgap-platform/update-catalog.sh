#!/usr/bin/env bash
set -euo pipefail

log() { echo "[$(date -Is)] $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PUBLISH_RECORD="${1:-}"
CHANNEL="${2:-}"
TIMESTAMP="${3:-${TIMESTAMP:-}}"
IMMUTABLE_TAG_OVERRIDE="${4:-${IMMUTABLE_TAG_OVERRIDE:-}}"
VERSION_OVERRIDE="${5:-${VERSION_OVERRIDE:-}}"
CATALOG_ARTIFACT_TYPE="application/vnd.techofourown.ourbox.airgap-platform.catalog.v1"

[[ -n "${PUBLISH_RECORD}" ]] || die "usage: update-catalog.sh <publish-record.json> <channel> [timestamp] [immutable-tag-override] [version-override]"
[[ -f "${PUBLISH_RECORD}" ]] || die "publish record not found: ${PUBLISH_RECORD}"
[[ -n "${CHANNEL}" ]] || die "channel is required"
case "${CHANNEL}" in
  stable|beta|nightly|exp-labs) : ;;
  *) die "channel must be one of: stable beta nightly exp-labs" ;;
esac

command -v python3 >/dev/null 2>&1 || die "python3 is required"
command -v oras >/dev/null 2>&1 || die "oras is required"

read -r ARTIFACT_REPO ARCH DEFAULT_TIMESTAMP < <(
  python3 - "${PUBLISH_RECORD}" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as fh:
    data = json.load(fh)

if data.get("artifact_family") != "airgap-platform":
    raise SystemExit("publish record must be for artifact_family=airgap-platform")

artifact_repo = data.get("artifact_repo", "")
arch = data.get("artifact_metadata", {}).get("AIRGAP_PLATFORM_ARCH", "")
created = data.get("created", "")
print(artifact_repo, arch, created)
PY
)

[[ -n "${ARTIFACT_REPO}" ]] || die "artifact_repo missing from publish record"
case "${ARCH}" in
  arm64|amd64) : ;;
  *) die "unsupported or missing AIRGAP_PLATFORM_ARCH in publish record: ${ARCH}" ;;
esac

if [[ -z "${TIMESTAMP}" ]]; then
  TIMESTAMP="${DEFAULT_TIMESTAMP}"
fi
[[ -n "${TIMESTAMP}" ]] || die "timestamp is required"

CATALOG_TAG="catalog-${ARCH}"

args=(
  update-catalog
  --catalog-family airgap-platform
  --artifact-record "${PUBLISH_RECORD}"
  --artifact-repo "${ARTIFACT_REPO}"
  --catalog-tag "${CATALOG_TAG}"
  --catalog-artifact-type "${CATALOG_ARTIFACT_TYPE}"
  --channel-tag "${CHANNEL}"
  --channel-mode short
  --timestamp "${TIMESTAMP}"
)

if [[ -n "${IMMUTABLE_TAG_OVERRIDE}" ]]; then
  args+=(--immutable-tag-override "${IMMUTABLE_TAG_OVERRIDE}")
fi

if [[ -n "${VERSION_OVERRIDE}" ]]; then
  args+=(--version-override "${VERSION_OVERRIDE}")
fi

log "Updating ${ARTIFACT_REPO}:${CATALOG_TAG} for channel=${CHANNEL} arch=${ARCH}"
python3 "${ROOT}/tools/release-control/release_control.py" "${args[@]}"
