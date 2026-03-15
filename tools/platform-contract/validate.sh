#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_BASE="$(mktemp -d "${TMPDIR:-/tmp}/ourbox-platform-contract-validation.XXXXXX")"
OUT_DIR_A="${OUT_BASE}/demo-apps-a"
OUT_DIR_B="${OUT_BASE}/demo-apps-b"
OUT_DIR_SUBSET_A="${OUT_BASE}/demo-apps-subset-a"
OUT_DIR_SUBSET_B="${OUT_BASE}/demo-apps-subset-b"
OUT_DIR_MERGED="${OUT_BASE}/demo-apps-merged"
SELECTED_APPS_FILE="${OUT_BASE}/selected-apps.json"
MERGED_SELECTED_APPS_FILE="${OUT_BASE}/selected-apps-merged.json"
MERGED_CATALOG_FILE="${OUT_BASE}/catalog-merged.json"
MERGED_IMAGES_LOCK_FILE="${OUT_BASE}/images-lock-merged.json"
BROKEN_ASSET_DIR_CATALOG_FILE="${OUT_BASE}/catalog-broken-asset-dir.json"
BROKEN_ASSET_DIR_LOG="${OUT_BASE}/broken-asset-dir.log"
IDENTITY_CONTRACT_DIR="${OUT_BASE}/identity-contract"
trap 'rm -rf "${OUT_BASE}"' EXIT
FIXTURE_APPLICATION_CATALOG_FILE="${ROOT}/platform-contract/profiles/demo-apps/catalog.json"
FIXTURE_APPLICATION_IMAGES_LOCK_FILE="${ROOT}/platform-contract/profiles/demo-apps/images.lock.json"

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

python3 - <<'PY' \
  "${FIXTURE_APPLICATION_CATALOG_FILE}" \
  "${FIXTURE_APPLICATION_IMAGES_LOCK_FILE}" \
  "${MERGED_CATALOG_FILE}" \
  "${MERGED_IMAGES_LOCK_FILE}"
import json
import sys
from pathlib import Path

demo_catalog = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
demo_lock = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
ourbox_chat_app = {
    "id": "ourbox-chat",
    "app_uid": "techofourown/ourbox-chat",
    "display_name": "OurBox Chat",
    "description": "CPU-only local chat UI backed by a bundled small GGUF model.",
    "renderer": "static-http",
    "service_name": "ourbox-chat",
    "service_port": 8080,
    "host_template": "chat.{box_host}",
    "path": "/",
    "expected_status": 200,
    "body_marker": "OurBox Chat",
    "route_description": "ourbox-chat-root",
    "default_backend": False,
    "image_names": ["ourbox-chat"],
}
ourbox_chat_image = {
    "name": "ourbox-chat",
    "ref": "ghcr.io/techofourown/sw-ourbox-apps-chat/ourbox-chat@sha256:" + ("7" * 64),
    "used_by": ["ourbox-chat"],
}

merged_catalog = dict(demo_catalog)
merged_catalog["catalog_id"] = "merged-smoke"
merged_catalog["catalog_name"] = "Merged Smoke Catalog"
merged_catalog["catalog_description"] = "Validation-only merged catalog including OurBox Chat."
merged_catalog["apps"] = list(demo_catalog["apps"]) + [ourbox_chat_app]
merged_catalog["default_app_ids"] = [
    "landing",
    "todo-bloom",
    "dufs",
    "flatnotes",
    "ourbox-chat",
]

merged_lock = {"schema": demo_lock["schema"], "profile": "merged-smoke", "images": list(demo_lock["images"]) + [ourbox_chat_image]}

Path(sys.argv[3]).write_text(json.dumps(merged_catalog, indent=2, sort_keys=True) + "\n", encoding="utf-8")
Path(sys.argv[4]).write_text(json.dumps(merged_lock, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

cat > "${MERGED_SELECTED_APPS_FILE}" <<'EOF'
{
  "schema": 1,
  "kind": "ourbox-selected-applications",
  "catalog_id": "merged-smoke",
  "selection_mode": "custom",
  "selected_app_ids": [
    "landing",
    "todo-bloom",
    "dufs",
    "flatnotes",
    "ourbox-chat"
  ]
}
EOF

python3 - <<'PY' "${FIXTURE_APPLICATION_CATALOG_FILE}" "${BROKEN_ASSET_DIR_CATALOG_FILE}"
import json
import sys
from pathlib import Path

catalog = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
for app in catalog["apps"]:
    if app["id"] == "landing":
        app["asset_dir"] = "missing-landing-assets"
        break
else:
    raise SystemExit("fixture catalog did not contain landing app")

Path(sys.argv[2]).write_text(json.dumps(catalog, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

OURBOX_PLATFORM_CONTRACT_SCHEMA=1 \
OURBOX_PLATFORM_CONTRACT_KIND=platform-contract \
OURBOX_PLATFORM_CONTRACT_SOURCE=https://github.com/techofourown/sw-ourbox-os \
OURBOX_PLATFORM_CONTRACT_REVISION="${REVISION}" \
OURBOX_PLATFORM_CONTRACT_VERSION="${VERSION}" \
OURBOX_PLATFORM_CONTRACT_CREATED="${CREATED}" \
python3 "${ROOT}/tools/platform-contract/render-contract.py" \
  --contract-root "${ROOT}/platform-contract" \
  --output-dir "${OUT_DIR_MERGED}" \
  --profile demo-apps \
  --application-catalog "${MERGED_CATALOG_FILE}" \
  --images-lock-file "${MERGED_IMAGES_LOCK_FILE}" \
  --selected-apps-file "${MERGED_SELECTED_APPS_FILE}" \
  --box-host "validate.ourbox.local" \
  --tls-mode "lan-http" \
  --ingress-class "traefik" \
  --storage-class "local-path"

diff -ru "${OUT_DIR_A}" "${OUT_DIR_B}"
diff -ru "${OUT_DIR_SUBSET_A}" "${OUT_DIR_SUBSET_B}"

python3 "${ROOT}/tools/platform-contract/lint-rendered-contract.py" \
  --contract-root "${ROOT}/platform-contract" \
  --render-dir "${OUT_DIR_A}"
python3 "${ROOT}/tools/platform-contract/lint-rendered-contract.py" \
  --contract-root "${ROOT}/platform-contract" \
  --render-dir "${OUT_DIR_SUBSET_A}"
python3 "${ROOT}/tools/platform-contract/lint-rendered-contract.py" \
  --contract-root "${ROOT}/platform-contract" \
  --render-dir "${OUT_DIR_MERGED}"

if OURBOX_PLATFORM_CONTRACT_SCHEMA=1 \
  OURBOX_PLATFORM_CONTRACT_KIND=platform-contract \
  OURBOX_PLATFORM_CONTRACT_SOURCE=https://github.com/techofourown/sw-ourbox-os \
  OURBOX_PLATFORM_CONTRACT_REVISION="${REVISION}" \
  OURBOX_PLATFORM_CONTRACT_VERSION="${VERSION}" \
  OURBOX_PLATFORM_CONTRACT_CREATED="${CREATED}" \
  python3 "${ROOT}/tools/platform-contract/render-contract.py" \
    --contract-root "${ROOT}/platform-contract" \
    --output-dir "${OUT_BASE}/broken-asset-dir-render" \
    --profile demo-apps \
    --application-catalog "${BROKEN_ASSET_DIR_CATALOG_FILE}" \
    --selected-apps-file "${SELECTED_APPS_FILE}" \
    --box-host "validate.ourbox.local" \
    --tls-mode "lan-http" \
    --ingress-class "traefik" \
    --storage-class "local-path" \
    > /dev/null 2> "${BROKEN_ASSET_DIR_LOG}"; then
  echo "render-contract unexpectedly accepted a missing explicit asset_dir" >&2
  exit 1
fi

grep -Fq "app 'landing' declares asset_dir 'missing-landing-assets'" "${BROKEN_ASSET_DIR_LOG}" || {
  echo "render-contract did not report the missing explicit asset_dir clearly" >&2
  cat "${BROKEN_ASSET_DIR_LOG}" >&2
  exit 1
}

[[ ! -f "${OUT_DIR_SUBSET_A}/manifests/22-todo-bloom-deployment.yaml" ]] || {
  echo "selected-app subset render unexpectedly included todo-bloom" >&2
  exit 1
}
[[ ! -f "${OUT_DIR_SUBSET_A}/manifests/41-flatnotes-deployment.yaml" ]] || {
  echo "selected-app subset render unexpectedly included flatnotes" >&2
  exit 1
}

python3 - <<'PY' "${OUT_DIR_SUBSET_A}/manifests/landing-configmap.yaml"
import json
import sys
from pathlib import Path

import yaml

path = Path(sys.argv[1])
config = yaml.safe_load(path.read_text(encoding="utf-8"))
payload = json.loads(config["data"]["ourbox-apps.json"])
apps = payload["apps"]
if apps != [
    {
        "description": "Simple file browser rooted on the shared data volume.",
        "host": "files.validate.ourbox.local",
        "id": "dufs",
        "name": "Dufs",
        "path": "/",
    }
]:
    raise SystemExit(f"unexpected landing app list for subset render: {apps!r}")
PY

python3 - <<'PY' "${OUT_DIR_SUBSET_A}/manifests/landing-status-configmap.yaml"
import json
import sys
from pathlib import Path

import yaml

path = Path(sys.argv[1])
config = yaml.safe_load(path.read_text(encoding="utf-8"))
payload = json.loads(config["data"]["ourbox-app-targets.json"])
apps = payload["apps"]
if apps != [
    {
        "description": "Simple file browser rooted on the shared data volume.",
        "host": "files.validate.ourbox.local",
        "id": "dufs",
        "name": "Dufs",
        "path": "/",
        "service_name": "dufs",
    }
]:
    raise SystemExit(f"unexpected landing status targets for subset render: {apps!r}")
PY

python3 - <<'PY' "${OUT_DIR_MERGED}/manifests/landing-configmap.yaml"
import json
import sys
from pathlib import Path

import yaml

path = Path(sys.argv[1])
config = yaml.safe_load(path.read_text(encoding="utf-8"))
payload = json.loads(config["data"]["ourbox-apps.json"])
apps = payload["apps"]
chat_apps = [app for app in apps if app["id"] == "ourbox-chat"]
if chat_apps != [
    {
        "description": "CPU-only local chat UI backed by a bundled small GGUF model.",
        "host": "chat.validate.ourbox.local",
        "id": "ourbox-chat",
        "name": "OurBox Chat",
        "path": "/",
    }
]:
    raise SystemExit(f"unexpected landing chat entry for merged render: {chat_apps!r}")
PY

python3 - <<'PY' "${OUT_DIR_MERGED}/manifests/landing-status-configmap.yaml"
import json
import sys
from pathlib import Path

import yaml

path = Path(sys.argv[1])
config = yaml.safe_load(path.read_text(encoding="utf-8"))
payload = json.loads(config["data"]["ourbox-app-targets.json"])
apps = payload["apps"]
chat_apps = [app for app in apps if app["id"] == "ourbox-chat"]
if chat_apps != [
    {
        "description": "CPU-only local chat UI backed by a bundled small GGUF model.",
        "host": "chat.validate.ourbox.local",
        "id": "ourbox-chat",
        "name": "OurBox Chat",
        "path": "/",
        "service_name": "ourbox-chat",
    }
]:
    raise SystemExit(f"unexpected landing status chat target for merged render: {chat_apps!r}")
PY

python3 - <<'PY' "${OUT_DIR_MERGED}/manifests/05-contract-metadata-configmap.yaml"
import json
import sys
from pathlib import Path

import yaml

path = Path(sys.argv[1])
config = yaml.safe_load(path.read_text(encoding="utf-8"))
platform_images = json.loads(config["data"]["platform_images.json"])
image_ref = platform_images.get("landing-status", "")
if not image_ref.startswith("docker.io/library/python:3.12-alpine@sha256:"):
    raise SystemExit(f"unexpected landing-status platform image ref: {image_ref!r}")
PY

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

# Use the local fixture catalog here on purpose so the identity check keeps
# covering the checked-in validation corpus as well as external bundle inputs.
cp -f "${FIXTURE_APPLICATION_CATALOG_FILE}" "${IDENTITY_CONTRACT_DIR}/catalog.json"
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

(
  cd "${ROOT}"
  ./tools/platform-contract/build.sh >/dev/null
)
tar -tzf "${ROOT}/dist/platform-contract.tar.gz" \
  | grep -Fx 'platform-contract/landing-status/app.py' >/dev/null \
  || {
    echo "built platform-contract tarball is missing landing-status/app.py" >&2
    exit 1
  }

echo "Validated deterministic rendered platform contract: ${OUT_DIR_A}"
