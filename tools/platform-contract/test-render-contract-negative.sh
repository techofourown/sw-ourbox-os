#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/ourbox-render-contract-negative.XXXXXX")"
trap 'rm -rf "${TMP_ROOT}"' EXIT

REVISION="$(git -C "${ROOT}" rev-parse HEAD)"
CREATED="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
VERSION="dev"
if git -C "${ROOT}" describe --tags --exact-match >/dev/null 2>&1; then
  VERSION="$(git -C "${ROOT}" describe --tags --exact-match)"
fi

render_expect_failure() {
  local label="$1"
  local expected="$2"
  local contract_root="$3"
  local out_dir="$4"
  shift 4
  local log_file="${TMP_ROOT}/${label}.log"

  if OURBOX_PLATFORM_CONTRACT_SCHEMA=1 \
     OURBOX_PLATFORM_CONTRACT_KIND=platform-contract \
     OURBOX_PLATFORM_CONTRACT_SOURCE=https://github.com/techofourown/sw-ourbox-os \
     OURBOX_PLATFORM_CONTRACT_REVISION="${REVISION}" \
     OURBOX_PLATFORM_CONTRACT_VERSION="${VERSION}" \
     OURBOX_PLATFORM_CONTRACT_CREATED="${CREATED}" \
     python3 "${ROOT}/tools/platform-contract/render-contract.py" \
       --contract-root "${contract_root}" \
       --output-dir "${out_dir}" \
       --profile demo-apps \
       --box-host "negative.ourbox.local" \
       --tls-mode "lan-http" \
       --ingress-class "traefik" \
       --storage-class "local-path" \
       "$@" >"${log_file}" 2>&1; then
    echo "expected render-contract.py to fail for ${label}" >&2
    cat "${log_file}" >&2
    exit 1
  fi

  grep -Fq "${expected}" "${log_file}" || {
    echo "expected ${label} failure output to contain: ${expected}" >&2
    cat "${log_file}" >&2
    exit 1
  }
}

prepare_contract_root() {
  local dest="$1"
  rm -rf "${dest}"
  mkdir -p "${dest}"
  cp -a "${ROOT}/platform-contract/." "${dest}/"
}

contract_missing_route="${TMP_ROOT}/contract-missing-route"
prepare_contract_root "${contract_missing_route}"
python3 - <<'PY' "${contract_missing_route}/profiles/demo-apps/catalog.json"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
catalog = json.loads(path.read_text(encoding="utf-8"))
for app in catalog["apps"]:
    if app["id"] == "landing":
        app.pop("host_template", None)
        break
path.write_text(json.dumps(catalog, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
render_expect_failure \
  missing-route-keys \
  "missing required route keys" \
  "${contract_missing_route}" \
  "${TMP_ROOT}/out-missing-route"

contract_bad_defaults="${TMP_ROOT}/contract-bad-defaults"
prepare_contract_root "${contract_bad_defaults}"
python3 - <<'PY' "${contract_bad_defaults}/profiles/demo-apps/catalog.json"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
catalog = json.loads(path.read_text(encoding="utf-8"))
catalog["default_app_ids"] = ["landing", "missing-app"]
path.write_text(json.dumps(catalog, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
render_expect_failure \
  bad-default-app-ids \
  "unknown default_app_ids" \
  "${contract_bad_defaults}" \
  "${TMP_ROOT}/out-bad-defaults"

contract_bad_selected="${TMP_ROOT}/contract-bad-selected"
prepare_contract_root "${contract_bad_selected}"
cat > "${TMP_ROOT}/selected-apps-unknown.json" <<'EOF_SELECTED'
{
  "schema": 1,
  "kind": "ourbox-selected-applications",
  "catalog_id": "demo-apps",
  "selection_mode": "custom",
  "selected_app_ids": [
    "landing",
    "does-not-exist"
  ]
}
EOF_SELECTED
render_expect_failure \
  bad-selected-apps \
  "references unknown app id does-not-exist" \
  "${contract_bad_selected}" \
  "${TMP_ROOT}/out-bad-selected" \
  --selected-apps-file "${TMP_ROOT}/selected-apps-unknown.json"

contract_bad_images="${TMP_ROOT}/contract-bad-images"
prepare_contract_root "${contract_bad_images}"
python3 - <<'PY' "${contract_bad_images}/profiles/demo-apps/images.lock.json"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
images_lock = json.loads(path.read_text(encoding="utf-8"))
images_lock["images"] = [image for image in images_lock["images"] if image["name"] != "nginx"]
path.write_text(json.dumps(images_lock, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
render_expect_failure \
  bad-images-lock \
  "references unknown image name 'nginx'" \
  "${contract_bad_images}" \
  "${TMP_ROOT}/out-bad-images"

printf '[%s] render-contract negative tests passed\n' "$(date -Is)"
