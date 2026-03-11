#!/usr/bin/env bash
set -euo pipefail

log() { echo "[$(date -Is)] $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC_DIR="${ROOT}/install-defaults"
DIST_DIR="${ROOT}/dist"

[[ -d "${SRC_DIR}/defaults" ]] || die "Missing ${SRC_DIR}/defaults"
[[ -f "${SRC_DIR}/schema.env" ]] || die "Missing ${SRC_DIR}/schema.env"

mkdir -p "${DIST_DIR}"

bash "${ROOT}/tools/install-defaults/validate-assignment-only.sh"
set_profile_var() {
  local file="$1" key="$2" value="$3"
  awk -F= -v key="${key}" -v value="${value}" '
    BEGIN { done = 0 }
    $1 == key {
      printf "%s=%s\n", key, value
      done = 1
      next
    }
    { print }
    END {
      if (!done) {
        printf "%s=%s\n", key, value
      }
    }
  ' "${file}" > "${file}.tmp"
  mv "${file}.tmp" "${file}"
}

apply_profile_override() {
  local installer_id="$1" key="$2" override_value="$3"
  local profile="${BUILD_DIR}/install-defaults/defaults/${installer_id}.env"
  [[ -n "${override_value}" ]] || return 0
  [[ -f "${profile}" ]] || die "Missing profile for override: ${profile}"
  set_profile_var "${profile}" "${key}" "${override_value}"
  log "Applied curated ${key} for ${installer_id}"
}

REVISION="$(git -C "${ROOT}" rev-parse HEAD)"
CREATED="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
VERSION="dev"
if git -C "${ROOT}" describe --tags --exact-match >/dev/null 2>&1; then
  VERSION="$(git -C "${ROOT}" describe --tags --exact-match)"
fi

BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "${BUILD_DIR}"' EXIT

mkdir -p "${BUILD_DIR}/install-defaults"
cp -a "${SRC_DIR}/." "${BUILD_DIR}/install-defaults/"

apply_profile_override "matchbox" "OS_DEFAULT_REF" "${MATCHBOX_OS_DEFAULT_REF_OVERRIDE:-}"
apply_profile_override "matchbox" "AIRGAP_PLATFORM_DEFAULT_REF" "${MATCHBOX_AIRGAP_PLATFORM_DEFAULT_REF_OVERRIDE:-}"
apply_profile_override "woodbox" "OS_DEFAULT_REF" "${WOODBOX_OS_DEFAULT_REF_OVERRIDE:-}"
apply_profile_override "woodbox" "AIRGAP_PLATFORM_DEFAULT_REF" "${WOODBOX_AIRGAP_PLATFORM_DEFAULT_REF_OVERRIDE:-}"
apply_profile_override "tinderbox" "OS_DEFAULT_REF" "${TINDERBOX_OS_DEFAULT_REF_OVERRIDE:-}"

bash "${ROOT}/tools/install-defaults/validate-assignment-only.sh" \
  "${BUILD_DIR}/install-defaults/schema.env" \
  "${BUILD_DIR}/install-defaults/defaults/"*.env

for profile in "${BUILD_DIR}/install-defaults/defaults/"*.env; do
  [[ -f "${profile}" ]] || die "No profile files found in defaults/"
  grep -q '^INSTALLER_ID=' "${profile}" || die "Profile missing INSTALLER_ID: ${profile}"
  grep -q '^OS_REPO=' "${profile}" || die "Profile missing OS_REPO: ${profile}"
  grep -q '^OS_CATALOG_TAG=' "${profile}" || die "Profile missing OS_CATALOG_TAG: ${profile}"
  grep -q '^CHANNEL_STABLE_TAG=' "${profile}" || die "Profile missing CHANNEL_STABLE_TAG: ${profile}"
done

cat > "${BUILD_DIR}/install-defaults/manifest.env" <<EOF_MANIFEST
OURBOX_INSTALL_DEFAULTS_SCHEMA=1
OURBOX_INSTALL_DEFAULTS_KIND=install-defaults
OURBOX_INSTALL_DEFAULTS_SOURCE=https://github.com/techofourown/sw-ourbox-os
OURBOX_INSTALL_DEFAULTS_REVISION=${REVISION}
OURBOX_INSTALL_DEFAULTS_VERSION=${VERSION}
OURBOX_INSTALL_DEFAULTS_CREATED=${CREATED}
EOF_MANIFEST

TARBALL="${DIST_DIR}/install-defaults.tar.gz"
tar -C "${BUILD_DIR}" -czf "${TARBALL}" install-defaults

cat > "${DIST_DIR}/install-defaults.meta.env" <<EOF_META
OURBOX_INSTALL_DEFAULTS_SOURCE=https://github.com/techofourown/sw-ourbox-os
OURBOX_INSTALL_DEFAULTS_REVISION=${REVISION}
OURBOX_INSTALL_DEFAULTS_VERSION=${VERSION}
OURBOX_INSTALL_DEFAULTS_CREATED=${CREATED}
EOF_META

log "Built ${TARBALL}"
