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
SCRIPT_NAMES_VALUE="${SCRIPT_NAMES[*]}"

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

{
  printf 'OURBOX_CATALOG_TOOLING_SOURCE=%q\n' "https://github.com/techofourown/sw-ourbox-os"
  printf 'OURBOX_CATALOG_TOOLING_REVISION=%q\n' "${REVISION}"
  printf 'OURBOX_CATALOG_TOOLING_VERSION=%q\n' "${VERSION}"
  printf 'OURBOX_CATALOG_TOOLING_CREATED=%q\n' "${CREATED}"
  printf 'OURBOX_CATALOG_TOOLING_INTERFACE_VERSION=%q\n' "1"
  printf 'SCRIPT_COUNT=%q\n' "${SCRIPT_COUNT}"
  printf 'SCRIPT_NAMES=%q\n' "${SCRIPT_NAMES_VALUE}"
} > "${DIST_DIR}/catalog-tooling.meta.env"

bash -c '
  set -euo pipefail
  source "$1"
  : "${OURBOX_CATALOG_TOOLING_SOURCE:?}"
  : "${OURBOX_CATALOG_TOOLING_REVISION:?}"
  : "${OURBOX_CATALOG_TOOLING_VERSION:?}"
  : "${OURBOX_CATALOG_TOOLING_CREATED:?}"
  : "${OURBOX_CATALOG_TOOLING_INTERFACE_VERSION:?}"
  : "${SCRIPT_COUNT:?}"
  : "${SCRIPT_NAMES:?}"
' _ "${DIST_DIR}/catalog-tooling.meta.env"

log "Built ${TARBALL}"
