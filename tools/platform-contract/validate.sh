#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_BASE="$(mktemp -d "${TMPDIR:-/tmp}/ourbox-platform-contract-validation.XXXXXX")"
OUT_DIR_A="${OUT_BASE}/demo-apps-a"
OUT_DIR_B="${OUT_BASE}/demo-apps-b"
OUT_DIR_SUBSET_A="${OUT_BASE}/demo-apps-subset-a"
OUT_DIR_SUBSET_B="${OUT_BASE}/demo-apps-subset-b"
SELECTED_APPS_FILE="${OUT_BASE}/selected-apps.json"
IDENTITY_CONTRACT_DIR="${OUT_BASE}/identity-contract"
trap 'rm -rf "${OUT_BASE}"' EXIT

REVISION="$(git -C "${ROOT}" rev-parse HEAD)"
CREATED="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
VERSION="dev"
if git -C "${ROOT}" describe --tags --exact-match >/dev/null 2>&1; then
  VERSION="$(git -C "${ROOT}" describe --tags --exact-match)"
fi

render_demo_apps() {
  local out_dir="$1"
  local selected_apps_file="${2:-}"
  local -a render_cmd=()
  rm -rf "${out_dir}"
  mkdir -p "${out_dir}"

  render_cmd=(
    python3 "${ROOT}/tools/platform-contract/render-contract.py"
    --contract-root "${ROOT}/platform-contract" \
    --output-dir "${out_dir}" \
    --profile demo-apps \
    --box-host "validate.ourbox.local" \
    --tls-mode "lan-http" \
    --ingress-class "traefik" \
    --storage-class "local-path"
  )
  if [[ -n "${selected_apps_file}" ]]; then
    render_cmd+=(--selected-apps-file "${selected_apps_file}")
  fi

  OURBOX_PLATFORM_CONTRACT_SCHEMA=1 \
  OURBOX_PLATFORM_CONTRACT_KIND=platform-contract \
  OURBOX_PLATFORM_CONTRACT_SOURCE=https://github.com/techofourown/sw-ourbox-os \
  OURBOX_PLATFORM_CONTRACT_REVISION="${REVISION}" \
  OURBOX_PLATFORM_CONTRACT_VERSION="${VERSION}" \
  OURBOX_PLATFORM_CONTRACT_CREATED="${CREATED}" \
    "${render_cmd[@]}"
}

render_demo_apps "${OUT_DIR_A}"
render_demo_apps "${OUT_DIR_B}"

cat > "${SELECTED_APPS_FILE}" <<'EOF'
{
  "schema": 1,
  "kind": "ourbox-selected-applications",
  "catalog_id": "demo-apps",
  "selection_mode": "custom",
  "selected_app_ids": [
    "landing",
    "dufs"
  ]
}
EOF

render_demo_apps "${OUT_DIR_SUBSET_A}" "${SELECTED_APPS_FILE}"
render_demo_apps "${OUT_DIR_SUBSET_B}" "${SELECTED_APPS_FILE}"

diff -ru "${OUT_DIR_A}" "${OUT_DIR_B}"
diff -ru "${OUT_DIR_SUBSET_A}" "${OUT_DIR_SUBSET_B}"

python3 "${ROOT}/tools/platform-contract/lint-rendered-contract.py" \
  --contract-root "${ROOT}/platform-contract" \
  --render-dir "${OUT_DIR_A}"
python3 "${ROOT}/tools/platform-contract/lint-rendered-contract.py" \
  --contract-root "${ROOT}/platform-contract" \
  --render-dir "${OUT_DIR_SUBSET_A}"

[[ ! -f "${OUT_DIR_SUBSET_A}/manifests/22-todo-bloom-deployment.yaml" ]] || {
  echo "selected-app subset render unexpectedly included todo-bloom" >&2
  exit 1
}
[[ ! -f "${OUT_DIR_SUBSET_A}/manifests/41-flatnotes-deployment.yaml" ]] || {
  echo "selected-app subset render unexpectedly included flatnotes" >&2
  exit 1
}

mkdir -p "${IDENTITY_CONTRACT_DIR}"
cp -a "${ROOT}/platform-contract/." "${IDENTITY_CONTRACT_DIR}/"
cat > "${IDENTITY_CONTRACT_DIR}/contract.env" <<EOF_CONTRACT
OURBOX_PLATFORM_CONTRACT_SOURCE=https://github.com/techofourown/sw-ourbox-os
OURBOX_PLATFORM_CONTRACT_REVISION=${REVISION}
OURBOX_PLATFORM_CONTRACT_VERSION=${VERSION}
OURBOX_PLATFORM_CONTRACT_CREATED=${CREATED}
EOF_CONTRACT
printf 'sha256:%064d\n' 0 > "${IDENTITY_CONTRACT_DIR}/contract.digest"
cp -f "${OUT_DIR_SUBSET_A}/catalog.json" "${IDENTITY_CONTRACT_DIR}/catalog.json"
cp -f "${OUT_DIR_SUBSET_A}/images.lock.json" "${IDENTITY_CONTRACT_DIR}/images.lock.json"
cp -f "${SELECTED_APPS_FILE}" "${IDENTITY_CONTRACT_DIR}/selected-apps.json"

identity_output() {
  "${ROOT}/tools/platform-contract/contract-identity.sh" \
    --contract-dir "${IDENTITY_CONTRACT_DIR}" \
    --profile demo-apps \
    --box-host "validate.ourbox.local" \
    --tls-mode "lan-http" \
    --ingress-class "traefik" \
    --storage-class "local-path" \
    --selected-apps-file "${IDENTITY_CONTRACT_DIR}/selected-apps.json"
}

identity_before="$(identity_output)"

python3 - <<'PY' "${IDENTITY_CONTRACT_DIR}/catalog.json"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
catalog = json.loads(path.read_text(encoding="utf-8"))
catalog["catalog_description"] = "identity drift catalog mutation"
path.write_text(json.dumps(catalog, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

identity_after_catalog="$(identity_output)"
[[ "${identity_before}" != "${identity_after_catalog}" ]] || {
  echo "contract identity did not change after catalog.json changed" >&2
  exit 1
}

cp -f "${ROOT}/platform-contract/profiles/demo-apps/catalog.json" "${IDENTITY_CONTRACT_DIR}/catalog.json"
identity_before_images_lock="$(identity_output)"

python3 - <<'PY' "${IDENTITY_CONTRACT_DIR}/images.lock.json"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
images_lock = json.loads(path.read_text(encoding="utf-8"))
images_lock["images"][0]["ref"] = "ghcr.io/example/identity-drift@sha256:" + ("9" * 64)
path.write_text(json.dumps(images_lock, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

identity_after_images_lock="$(identity_output)"
[[ "${identity_before_images_lock}" != "${identity_after_images_lock}" ]] || {
  echo "contract identity did not change after images.lock.json changed" >&2
  exit 1
}

echo "Validated deterministic rendered platform contract: ${OUT_DIR_A}"
