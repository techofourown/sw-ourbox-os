#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONTRACT_DIR="${ROOT}/platform-contract"
DIST_DIR="${ROOT}/dist"
mkdir -p "${DIST_DIR}"

if [[ ! -d "${CONTRACT_DIR}/profiles" ]]; then
  echo "platform-contract/profiles is missing" >&2
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
mkdir -p \
  "${BUILD_DIR}/platform-contract/landing" \
  "${BUILD_DIR}/platform-contract/todo-bloom" \
  "${BUILD_DIR}/platform-contract/profiles" \
  "${BUILD_DIR}/platform-contract/tools" \
  "${BUILD_DIR}/platform-contract/rendered/defaults"

cp -a "${CONTRACT_DIR}/landing/." "${BUILD_DIR}/platform-contract/landing/"
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
