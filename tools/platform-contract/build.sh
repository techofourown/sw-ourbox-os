#!/usr/bin/env bash
set -euo pipefail

log() { echo "[$(date -Is)] $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONTRACT_DIR="${ROOT}/platform-contract"
DIST_DIR="${ROOT}/dist"
mkdir -p "${DIST_DIR}"

[[ -d "${CONTRACT_DIR}/profiles" ]] || die "platform-contract/profiles is missing"

REVISION="$(git -C "${ROOT}" rev-parse HEAD)"
CREATED="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

VERSION="dev"
if git -C "${ROOT}" describe --tags --exact-match >/dev/null 2>&1; then
  VERSION="$(git -C "${ROOT}" describe --tags --exact-match)"
fi

BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "${BUILD_DIR}"' EXIT

ALLOW_FIXTURE_APPLICATION_CATALOG="${OURBOX_ALLOW_FIXTURE_APPLICATION_CATALOG:-0}"
APPLICATION_CATALOG_FILE="${CONTRACT_DIR}/profiles/demo-apps/catalog.json"
APPLICATION_IMAGES_LOCK_FILE="${CONTRACT_DIR}/profiles/demo-apps/images.lock.json"
APPLICATION_CATALOG_SOURCE_KIND="fixture-profile"
APPLICATION_CATALOG_MANIFEST_FILE=""

prepare_application_catalog_inputs() {
  local pull_dir=""
  local extract_dir=""
  local bundle_tarball=""
  local manifest_digest=""

  if [[ -z "${OURBOX_APPLICATION_CATALOG_REF:-}" ]]; then
    if [[ "${ALLOW_FIXTURE_APPLICATION_CATALOG}" == "1" ]]; then
      log "Using explicitly requested in-repo demo-apps catalog fixtures for platform-contract build."
      return 0
    fi
    die "OURBOX_APPLICATION_CATALOG_REF is required for platform-contract build. Set OURBOX_ALLOW_FIXTURE_APPLICATION_CATALOG=1 only for explicit local fixture validation."
  fi

  command -v oras >/dev/null 2>&1 || die "oras is required when OURBOX_APPLICATION_CATALOG_REF is set"
  command -v tar >/dev/null 2>&1 || die "tar is required when OURBOX_APPLICATION_CATALOG_REF is set"

  pull_dir="${BUILD_DIR}/application-catalog-pull"
  extract_dir="${BUILD_DIR}/application-catalog"
  rm -rf "${pull_dir}" "${extract_dir}"
  mkdir -p "${pull_dir}" "${extract_dir}"

  log "Pulling application catalog bundle: ${OURBOX_APPLICATION_CATALOG_REF}"
  oras pull "${OURBOX_APPLICATION_CATALOG_REF}" -o "${pull_dir}" >/dev/null
  bundle_tarball="$(find "${pull_dir}" -maxdepth 4 -type f -name 'application-catalog-bundle.tar.gz' | head -n 1 || true)"
  [[ -f "${bundle_tarball}" ]] || die "application catalog pull did not produce application-catalog-bundle.tar.gz"

  tar -xzf "${bundle_tarball}" -C "${extract_dir}"
  [[ -f "${extract_dir}/catalog.json" ]] || die "application catalog bundle missing catalog.json"
  [[ -f "${extract_dir}/images.lock.json" ]] || die "application catalog bundle missing images.lock.json"
  [[ -f "${extract_dir}/manifest.env" ]] || die "application catalog bundle missing manifest.env"

  manifest_digest="$(awk -F= '/^OURBOX_PLATFORM_CONTRACT_DIGEST=/{print $2; exit}' "${extract_dir}/manifest.env")"
  if [[ -n "${manifest_digest}" && ! "${manifest_digest}" =~ ^sha256:[0-9a-f]{64}$ ]]; then
    die "application catalog bundle manifest carries an invalid OURBOX_PLATFORM_CONTRACT_DIGEST"
  fi

  APPLICATION_CATALOG_FILE="${extract_dir}/catalog.json"
  APPLICATION_IMAGES_LOCK_FILE="${extract_dir}/images.lock.json"
  APPLICATION_CATALOG_MANIFEST_FILE="${extract_dir}/manifest.env"
  APPLICATION_CATALOG_SOURCE_KIND="published-catalog-bundle"
  log "Using published application catalog bundle inputs for platform-contract build (bound=${manifest_digest:-unknown})."
}

prepare_application_catalog_inputs

mkdir -p "${BUILD_DIR}/platform-contract"
mkdir -p \
  "${BUILD_DIR}/platform-contract/landing" \
  "${BUILD_DIR}/platform-contract/landing-status" \
  "${BUILD_DIR}/platform-contract/todo-bloom" \
  "${BUILD_DIR}/platform-contract/profiles" \
  "${BUILD_DIR}/platform-contract/tools" \
  "${BUILD_DIR}/platform-contract/rendered/defaults"

cp -a "${CONTRACT_DIR}/landing/." "${BUILD_DIR}/platform-contract/landing/"
cp -a "${CONTRACT_DIR}/landing-status/." "${BUILD_DIR}/platform-contract/landing-status/"
cp -a "${CONTRACT_DIR}/todo-bloom/." "${BUILD_DIR}/platform-contract/todo-bloom/"
cp -a "${CONTRACT_DIR}/profiles/." "${BUILD_DIR}/platform-contract/profiles/"
cp -a "${ROOT}/tools/platform-contract/render-contract.py" "${BUILD_DIR}/platform-contract/tools/"
cp -a "${ROOT}/tools/platform-contract/lint-rendered-contract.py" "${BUILD_DIR}/platform-contract/tools/"
cp -a "${ROOT}/tools/platform-contract/check-target-prereqs.sh" "${BUILD_DIR}/platform-contract/tools/"
cp -a "${ROOT}/tools/platform-contract/contract-identity.sh" "${BUILD_DIR}/platform-contract/tools/"
cp -a "${ROOT}/tools/platform-contract/verify-runtime.sh" "${BUILD_DIR}/platform-contract/tools/"
cp -a "${ROOT}/tools/platform-contract/verify-persistence.sh" "${BUILD_DIR}/platform-contract/tools/"

cat > "${BUILD_DIR}/platform-contract/contract.env" <<METADATA
OURBOX_PLATFORM_CONTRACT_SCHEMA=1
OURBOX_PLATFORM_CONTRACT_KIND=platform-contract
OURBOX_PLATFORM_CONTRACT_SOURCE=https://github.com/techofourown/sw-ourbox-os
OURBOX_PLATFORM_CONTRACT_REVISION=${REVISION}
OURBOX_PLATFORM_CONTRACT_VERSION=${VERSION}
OURBOX_PLATFORM_CONTRACT_CREATED=${CREATED}
METADATA

OURBOX_PLATFORM_CONTRACT_SCHEMA=1 \
OURBOX_PLATFORM_CONTRACT_KIND=platform-contract \
OURBOX_PLATFORM_CONTRACT_SOURCE=https://github.com/techofourown/sw-ourbox-os \
OURBOX_PLATFORM_CONTRACT_REVISION="${REVISION}" \
OURBOX_PLATFORM_CONTRACT_VERSION="${VERSION}" \
OURBOX_PLATFORM_CONTRACT_CREATED="${CREATED}" \
python3 "${ROOT}/tools/platform-contract/render-contract.py" \
  --contract-root "${BUILD_DIR}/platform-contract" \
  --output-dir "${BUILD_DIR}/platform-contract/rendered/defaults/demo-apps" \
  --profile demo-apps \
  --application-catalog "${APPLICATION_CATALOG_FILE}" \
  --images-lock-file "${APPLICATION_IMAGES_LOCK_FILE}" \
  --box-host "ourbox.local" \
  --tls-mode "lan-http" \
  --ingress-class "traefik" \
  --storage-class "local-path"

python3 "${ROOT}/tools/platform-contract/lint-rendered-contract.py" \
  --contract-root "${BUILD_DIR}/platform-contract" \
  --render-dir "${BUILD_DIR}/platform-contract/rendered/defaults/demo-apps"

mkdir -p "${BUILD_DIR}/platform-contract/manifests"
cp -a "${BUILD_DIR}/platform-contract/rendered/defaults/demo-apps/manifests/." "${BUILD_DIR}/platform-contract/manifests/"

tar -C "${BUILD_DIR}" -czf "${DIST_DIR}/platform-contract.tar.gz" platform-contract

cat > "${DIST_DIR}/platform-contract.meta.env" <<METADATA
OURBOX_PLATFORM_CONTRACT_SOURCE=https://github.com/techofourown/sw-ourbox-os
OURBOX_PLATFORM_CONTRACT_REVISION=${REVISION}
OURBOX_PLATFORM_CONTRACT_VERSION=${VERSION}
OURBOX_PLATFORM_CONTRACT_CREATED=${CREATED}
METADATA

echo "Built: ${DIST_DIR}/platform-contract.tar.gz"
