#!/usr/bin/env bash
set -euo pipefail

log() { echo "[$(date -Is)] $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

need_cmd() { command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"; }

need_cmd oras
need_cmd tar
need_cmd python3

ARTIFACT_REF="${1:?Usage: self-test.sh <artifact-ref>}"

TEST_DIR="$(mktemp -d)"
trap 'rm -rf "${TEST_DIR}"' EXIT

log "Pulling artifact: ${ARTIFACT_REF}"
oras pull "${ARTIFACT_REF}" -o "${TEST_DIR}"

TARBALL="$(find "${TEST_DIR}" -maxdepth 2 -type f -name 'catalog-tooling.tar.gz' | head -n1 || true)"
[[ -f "${TARBALL}" ]] || die "Pull did not produce catalog-tooling.tar.gz"

EXTRACT_DIR="${TEST_DIR}/extracted"
mkdir -p "${EXTRACT_DIR}"
tar -xzf "${TARBALL}" -C "${EXTRACT_DIR}"

TOOLING_DIR="${EXTRACT_DIR}/catalog-tooling"
[[ -d "${TOOLING_DIR}" ]] || die "Tarball missing catalog-tooling/ directory"
[[ -f "${TOOLING_DIR}/manifest.env" ]] || die "Missing manifest.env"
[[ -d "${TOOLING_DIR}/scripts" ]] || die "Missing scripts/ directory"

log "Validating manifest.env"
REQUIRED_KEYS=(
  OURBOX_CATALOG_TOOLING_SCHEMA
  OURBOX_CATALOG_TOOLING_KIND
  OURBOX_CATALOG_TOOLING_SOURCE
  OURBOX_CATALOG_TOOLING_REVISION
  OURBOX_CATALOG_TOOLING_VERSION
  OURBOX_CATALOG_TOOLING_CREATED
  OURBOX_CATALOG_TOOLING_INTERFACE_VERSION
)
for key in "${REQUIRED_KEYS[@]}"; do
  grep -q "^${key}=" "${TOOLING_DIR}/manifest.env" \
    || die "manifest.env missing required key: ${key}"
done

INTERFACE_VERSION="$(awk -F= '/^OURBOX_CATALOG_TOOLING_INTERFACE_VERSION=/{print $2; exit}' "${TOOLING_DIR}/manifest.env")"
[[ "${INTERFACE_VERSION}" =~ ^[1-9][0-9]*$ ]] \
  || die "OURBOX_CATALOG_TOOLING_INTERFACE_VERSION must be a positive integer, got: ${INTERFACE_VERSION}"

log "Validating expected scripts"
EXPECTED_SCRIPTS=(
  render-catalog-bundle.sh
  render-catalog-rows.py
  publish-catalog-bundle.sh
  validate-catalog-repo.sh
  check-catalog-bundle-smoke.sh
  check-publish-workflow.sh
  check-image-refs-exist.sh
)
for script in "${EXPECTED_SCRIPTS[@]}"; do
  [[ -f "${TOOLING_DIR}/scripts/${script}" ]] \
    || die "Missing expected script: ${script}"
  [[ -x "${TOOLING_DIR}/scripts/${script}" ]] \
    || die "Script is not executable: ${script}"
done

log "Syntax-checking bash scripts"
for script in "${TOOLING_DIR}/scripts/"*.sh; do
  bash -n "${script}" || die "Syntax error in: $(basename "${script}")"
done

log "Syntax-checking Python scripts"
for script in "${TOOLING_DIR}/scripts/"*.py; do
  python3 -m py_compile "${script}" || die "Syntax error in: $(basename "${script}")"
done

log "Self-test passed for ${ARTIFACT_REF}"
