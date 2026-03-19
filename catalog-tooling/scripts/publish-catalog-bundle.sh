#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() { echo "[$(date -Is)] $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "required command not found: $1" >&2
    exit 1
  }
}

need_cmd oras
need_cmd python3
need_cmd sha256sum
need_cmd tar

: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
: "${GITHUB_SHA:?GITHUB_SHA is required}"
: "${GITHUB_RUN_ID:?GITHUB_RUN_ID is required}"
: "${GITHUB_RUN_ATTEMPT:?GITHUB_RUN_ATTEMPT is required}"
: "${OURBOX_PLATFORM_CONTRACT_DIGEST:?OURBOX_PLATFORM_CONTRACT_DIGEST is required}"

RUNNER_TEMP="${RUNNER_TEMP:-${TMPDIR:-/tmp}}"

REF="ghcr.io/${GITHUB_REPOSITORY}:latest"
CATALOG_REF="ghcr.io/${GITHUB_REPOSITORY}:catalog-amd64"
CATALOG_ARTIFACT_TYPE="application/vnd.techofourown.ourbox.application-catalog.catalog.v1"
IMMUTABLE_TAG="sha-${GITHUB_SHA}-run-${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT}"
IMMUTABLE_REF="ghcr.io/${GITHUB_REPOSITORY}:${IMMUTABLE_TAG}"
VERSION_TAG="main-${GITHUB_SHA::12}"
CREATED="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

log "Rendering catalog bundle"
bash "${ROOT}/scripts/render-catalog-bundle.sh"

log "Publishing bundle as ${IMMUTABLE_REF}"
oras push \
  --artifact-type application/vnd.techofourown.ourbox.application-catalog.v1.tar+gzip \
  "${IMMUTABLE_REF}" \
  dist/application-catalog-bundle.tar.gz:application/vnd.techofourown.ourbox.application-catalog.v1.tar+gzip

DIGEST="$(oras resolve "${IMMUTABLE_REF}")"

EXISTING_CATALOG=""
rm -rf dist/catalog-existing
if oras pull "${CATALOG_REF}" -o dist/catalog-existing >"${RUNNER_TEMP}/catalog-pull.out" 2>"${RUNNER_TEMP}/catalog-pull.err"; then
  EXISTING_CATALOG="$(find dist/catalog-existing -maxdepth 4 -type f -name 'catalog.tsv' | head -n 1 || true)"
elif grep -Eiq 'MANIFEST_UNKNOWN|NAME_UNKNOWN|not found|404' "${RUNNER_TEMP}/catalog-pull.err"; then
  echo "No existing catalog index found at ${CATALOG_REF}; creating a new catalog.tsv"
else
  echo "Failed to pull existing catalog index ${CATALOG_REF}" >&2
  cat "${RUNNER_TEMP}/catalog-pull.err" >&2
  exit 1
fi

python3 "${ROOT}/scripts/render-catalog-rows.py" \
  --catalog-json catalog/catalog.json \
  --profile-env catalog/profile.env \
  --images-lock dist/images.lock.json \
  --existing-catalog "${EXISTING_CATALOG}" \
  --out-catalog dist/catalog.tsv \
  --channel stable \
  --tag "${IMMUTABLE_TAG}" \
  --created "${CREATED}" \
  --version "${VERSION_TAG}" \
  --revision "${GITHUB_SHA}" \
  --arch amd64 \
  --artifact-digest "${DIGEST}" \
  --pinned-ref "ghcr.io/${GITHUB_REPOSITORY}@${DIGEST}"

log "Publishing catalog index to ${CATALOG_REF}"
oras push \
  --artifact-type "${CATALOG_ARTIFACT_TYPE}" \
  "${CATALOG_REF}" \
  dist/catalog.tsv:text/tab-separated-values

oras tag "${IMMUTABLE_REF}" latest >/dev/null
oras tag "${IMMUTABLE_REF}" stable >/dev/null
oras tag "${IMMUTABLE_REF}" "${VERSION_TAG}" >/dev/null

LATEST_DIGEST="$(oras resolve "${REF}")"
[[ "${LATEST_DIGEST}" == "${DIGEST}" ]] || {
  echo "latest tag did not resolve to the published immutable digest" >&2
  echo "expected: ${DIGEST}" >&2
  echo "actual:   ${LATEST_DIGEST}" >&2
  exit 1
}

log "Writing publish record"
DIGEST="${DIGEST}" \
IMMUTABLE_REF="${IMMUTABLE_REF}" \
python3 - <<'PY'
import json
import os
from pathlib import Path

catalog = json.loads(Path("catalog/catalog.json").read_text(encoding="utf-8"))
record = {
    "schema": 1,
    "kind": "ourbox-application-catalog-bundle-publish-record",
    "catalog_id": catalog["catalog_id"],
    "catalog_name": catalog["catalog_name"],
    "mutable_ref": f"ghcr.io/{os.environ['GITHUB_REPOSITORY']}:latest",
    "immutable_ref": os.environ["IMMUTABLE_REF"],
    "artifact_ref": f"ghcr.io/{os.environ['GITHUB_REPOSITORY']}@{os.environ['DIGEST']}",
    "artifact_digest": os.environ["DIGEST"],
    "tooling_requested_ref": os.environ.get("OURBOX_CATALOG_TOOLING_REQUESTED_REF", ""),
    "tooling_resolved_digest": os.environ.get("OURBOX_CATALOG_TOOLING_RESOLVED_DIGEST", ""),
    "github_sha": os.environ["GITHUB_SHA"],
    "github_run_id": os.environ["GITHUB_RUN_ID"],
    "github_run_attempt": os.environ["GITHUB_RUN_ATTEMPT"],
}
Path("dist/catalog-bundle.publish-record.json").write_text(
    json.dumps(record, indent=2) + "\n",
    encoding="utf-8",
)
PY

log "Published ${IMMUTABLE_REF} (digest: ${DIGEST})"
