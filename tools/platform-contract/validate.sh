#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_BASE="$(mktemp -d "${TMPDIR:-/tmp}/ourbox-platform-contract-validation.XXXXXX")"
OUT_DIR_A="${OUT_BASE}/demo-apps-a"
OUT_DIR_B="${OUT_BASE}/demo-apps-b"
trap 'rm -rf "${OUT_BASE}"' EXIT

REVISION="$(git -C "${ROOT}" rev-parse HEAD)"
CREATED="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
VERSION="dev"
if git -C "${ROOT}" describe --tags --exact-match >/dev/null 2>&1; then
  VERSION="$(git -C "${ROOT}" describe --tags --exact-match)"
fi

render_demo_apps() {
  local out_dir="$1"
  rm -rf "${out_dir}"
  mkdir -p "${out_dir}"

  OURBOX_PLATFORM_CONTRACT_SCHEMA=1 \
  OURBOX_PLATFORM_CONTRACT_KIND=platform-contract \
  OURBOX_PLATFORM_CONTRACT_SOURCE=https://github.com/techofourown/sw-ourbox-os \
  OURBOX_PLATFORM_CONTRACT_REVISION="${REVISION}" \
  OURBOX_PLATFORM_CONTRACT_VERSION="${VERSION}" \
  OURBOX_PLATFORM_CONTRACT_CREATED="${CREATED}" \
  python3 "${ROOT}/tools/platform-contract/render-contract.py" \
    --contract-root "${ROOT}/platform-contract" \
    --output-dir "${out_dir}" \
    --profile demo-apps \
    --box-host "validate.ourbox.local" \
    --tls-mode "lan-http" \
    --ingress-class "traefik" \
    --storage-class "local-path"
}

render_demo_apps "${OUT_DIR_A}"
render_demo_apps "${OUT_DIR_B}"

diff -ru "${OUT_DIR_A}" "${OUT_DIR_B}"

python3 "${ROOT}/tools/platform-contract/lint-rendered-contract.py" \
  --contract-root "${ROOT}/platform-contract" \
  --render-dir "${OUT_DIR_A}"

echo "Validated deterministic rendered platform contract: ${OUT_DIR_A}"
