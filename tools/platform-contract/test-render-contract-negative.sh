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

contract_bad_catalog_id="${TMP_ROOT}/contract-bad-catalog-id"
prepare_contract_root "${contract_bad_catalog_id}"
python3 - <<'PY' "${contract_bad_catalog_id}/profiles/demo-apps/catalog.json"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
catalog = json.loads(path.read_text(encoding="utf-8"))
catalog["catalog_id"] = "Demo Apps"
path.write_text(json.dumps(catalog, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
render_expect_failure \
  bad-catalog-id \
  "declares invalid catalog_id" \
  "${contract_bad_catalog_id}" \
  "${TMP_ROOT}/out-bad-catalog-id"

contract_duplicate_app_uid="${TMP_ROOT}/contract-duplicate-app-uid"
prepare_contract_root "${contract_duplicate_app_uid}"
python3 - <<'PY' "${contract_duplicate_app_uid}/profiles/demo-apps/catalog.json"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
catalog = json.loads(path.read_text(encoding="utf-8"))
catalog["apps"][1]["app_uid"] = catalog["apps"][0]["app_uid"]
path.write_text(json.dumps(catalog, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
render_expect_failure \
  duplicate-app-uid \
  "contains a duplicate app_uid" \
  "${contract_duplicate_app_uid}" \
  "${TMP_ROOT}/out-duplicate-app-uid"

contract_multiple_default_backends="${TMP_ROOT}/contract-multiple-default-backends"
prepare_contract_root "${contract_multiple_default_backends}"
python3 - <<'PY' "${contract_multiple_default_backends}/profiles/demo-apps/catalog.json"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
catalog = json.loads(path.read_text(encoding="utf-8"))
catalog["apps"][1]["default_backend"] = True
path.write_text(json.dumps(catalog, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY
render_expect_failure \
  multiple-default-backends \
  "declares more than one default_backend app" \
  "${contract_multiple_default_backends}" \
  "${TMP_ROOT}/out-multiple-default-backends"

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

cat > "${TMP_ROOT}/selected-apps-bad-mode.json" <<'EOF_SELECTED_BAD_MODE'
{
  "schema": 1,
  "kind": "ourbox-selected-applications",
  "catalog_id": "demo-apps",
  "selection_mode": "surprise-mode",
  "selected_app_ids": [
    "landing"
  ]
}
EOF_SELECTED_BAD_MODE
render_expect_failure \
  bad-selected-mode \
  "declares unsupported selection_mode" \
  "${contract_bad_selected}" \
  "${TMP_ROOT}/out-bad-selected-mode" \
  --selected-apps-file "${TMP_ROOT}/selected-apps-bad-mode.json"

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
