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

for profile in "${BUILD_DIR}/install-defaults/defaults/"*.env; do
  [[ -f "${profile}" ]] || die "No profile files found in defaults/"
  grep -q '^INSTALLER_ID=' "${profile}" || die "Profile missing INSTALLER_ID: ${profile}"
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
