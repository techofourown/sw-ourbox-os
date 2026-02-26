#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONTRACT_DIR="${ROOT}/platform-contract"
DIST_DIR="${ROOT}/dist"
mkdir -p "${DIST_DIR}"

if [[ ! -d "${CONTRACT_DIR}/manifests" ]]; then
  echo "platform-contract/manifests is missing" >&2
  exit 1
fi

REVISION="$(git -C "${ROOT}" rev-parse HEAD)"
CREATED="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

VERSION="dev"
if git -C "${ROOT}" describe --tags --exact-match >/dev/null 2>&1; then
  VERSION="$(git -C "${ROOT}" describe --tags --exact-match)"
fi

BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "${BUILD_DIR}"' EXIT

mkdir -p "${BUILD_DIR}/platform-contract"
cp -a "${CONTRACT_DIR}/." "${BUILD_DIR}/platform-contract/"

cat > "${BUILD_DIR}/platform-contract/contract.env" <<METADATA
OURBOX_PLATFORM_CONTRACT_SCHEMA=1
OURBOX_PLATFORM_CONTRACT_KIND=platform-contract
OURBOX_PLATFORM_CONTRACT_SOURCE=https://github.com/techofourown/sw-ourbox-os
OURBOX_PLATFORM_CONTRACT_REVISION=${REVISION}
OURBOX_PLATFORM_CONTRACT_VERSION=${VERSION}
OURBOX_PLATFORM_CONTRACT_CREATED=${CREATED}
METADATA

tar -C "${BUILD_DIR}" -czf "${DIST_DIR}/platform-contract.tar.gz" platform-contract

cat > "${DIST_DIR}/platform-contract.meta.env" <<METADATA
OURBOX_PLATFORM_CONTRACT_SOURCE=https://github.com/techofourown/sw-ourbox-os
OURBOX_PLATFORM_CONTRACT_REVISION=${REVISION}
OURBOX_PLATFORM_CONTRACT_VERSION=${VERSION}
OURBOX_PLATFORM_CONTRACT_CREATED=${CREATED}
METADATA

echo "Built: ${DIST_DIR}/platform-contract.tar.gz"
