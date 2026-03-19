#!/usr/bin/env bash
set -euo pipefail

log() { echo "[$(date -Is)] $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC_DIR="${ROOT}/catalog-tooling"
DIST_DIR="${ROOT}/dist"

[[ -d "${SRC_DIR}/scripts" ]] || die "Missing ${SRC_DIR}/scripts"

mkdir -p "${DIST_DIR}"

REVISION="$(git -C "${ROOT}" rev-parse HEAD)"
CREATED="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
VERSION="dev"
if git -C "${ROOT}" describe --tags --exact-match >/dev/null 2>&1; then
  VERSION="$(git -C "${ROOT}" describe --tags --exact-match)"
fi

BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "${BUILD_DIR}"' EXIT

mkdir -p "${BUILD_DIR}/catalog-tooling"
cp -a "${SRC_DIR}/scripts" "${BUILD_DIR}/catalog-tooling/scripts"

mapfile -t SCRIPT_NAMES < <(
  find "${BUILD_DIR}/catalog-tooling/scripts" -maxdepth 1 -type f \( -name '*.sh' -o -name '*.py' \) -printf '%f\n' | sort
)
SCRIPT_COUNT="${#SCRIPT_NAMES[@]}"

cat > "${BUILD_DIR}/catalog-tooling/manifest.env" <<EOF_MANIFEST
OURBOX_CATALOG_TOOLING_SCHEMA=1
OURBOX_CATALOG_TOOLING_KIND=catalog-tooling
OURBOX_CATALOG_TOOLING_SOURCE=https://github.com/techofourown/sw-ourbox-os
OURBOX_CATALOG_TOOLING_REVISION=${REVISION}
OURBOX_CATALOG_TOOLING_VERSION=${VERSION}
OURBOX_CATALOG_TOOLING_CREATED=${CREATED}
OURBOX_CATALOG_TOOLING_INTERFACE_VERSION=1
EOF_MANIFEST

TARBALL="${DIST_DIR}/catalog-tooling.tar.gz"
tar -C "${BUILD_DIR}" -czf "${TARBALL}" catalog-tooling

cat > "${DIST_DIR}/catalog-tooling.meta.env" <<EOF_META
OURBOX_CATALOG_TOOLING_SOURCE=https://github.com/techofourown/sw-ourbox-os
OURBOX_CATALOG_TOOLING_REVISION=${REVISION}
OURBOX_CATALOG_TOOLING_VERSION=${VERSION}
OURBOX_CATALOG_TOOLING_CREATED=${CREATED}
OURBOX_CATALOG_TOOLING_INTERFACE_VERSION=1
SCRIPT_COUNT=${SCRIPT_COUNT}
SCRIPT_NAMES=${SCRIPT_NAMES[*]}
EOF_META

log "Built ${TARBALL}"
