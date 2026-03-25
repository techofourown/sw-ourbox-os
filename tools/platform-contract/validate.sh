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
GENERATED_APPLICATION_IMAGES_LOCK_FILE="${OUT_BASE}/images-lock-demo-apps.json"
GENERATED_PLATFORM_IMAGES_LOCK_FILE="${OUT_BASE}/platform-images-lock-demo-apps.json"
IDENTITY_CONTRACT_DIR="${OUT_BASE}/identity-contract"
trap 'rm -rf "${OUT_BASE}"' EXIT
FIXTURE_APPLICATION_CATALOG_FILE="${ROOT}/platform-contract/profiles/demo-apps/catalog.json"
FIXTURE_APPLICATION_IMAGE_SOURCES_FILE="${ROOT}/platform-contract/profiles/demo-apps/image-sources.json"
FIXTURE_PLATFORM_IMAGE_SOURCES_FILE="${ROOT}/platform-contract/profiles/demo-apps/platform-image-sources.json"

python3 "${ROOT}/tools/platform-contract/resolve-image-sources.py" \
  --input "${FIXTURE_APPLICATION_IMAGE_SOURCES_FILE}" \
  --catalog "${FIXTURE_APPLICATION_CATALOG_FILE}" \
  --profile demo-apps \
  --output "${GENERATED_APPLICATION_IMAGES_LOCK_FILE}"

python3 "${ROOT}/tools/platform-contract/resolve-image-sources.py" \
  --input "${FIXTURE_PLATFORM_IMAGE_SOURCES_FILE}" \
  --profile demo-apps \
  --require-used-by _platform \
  --output "${GENERATED_PLATFORM_IMAGES_LOCK_FILE}"

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
    --images-lock-file "${GENERATED_APPLICATION_IMAGES_LOCK_FILE}" \
    --platform-images-lock-file "${GENERATED_PLATFORM_IMAGES_LOCK_FILE}" \
    --box-host "validate.ourbox.local" \
    --tls-mode "lan-http" \
    --ingress-class "traefik" \
    --storage-class "local-path"
  )
  if [[ -n "${selected_apps_file}" ]]; then
    render_cmd+=(--selected-apps-file "${selected_apps_file}")
  fi

  "${render_cmd[@]}"
}

render_expect_failure() {
  local label="$1"
  local expected="$2"
  shift 2
  local log_file="${OUT_BASE}/${label}.log"

  if "$@" >"${log_file}" 2>&1; then
    echo "expected failure for ${label}" >&2
    cat "${log_file}" >&2
    exit 1
  fi

  grep -Fq "${expected}" "${log_file}" || {
    echo "expected ${label} output to contain: ${expected}" >&2
    cat "${log_file}" >&2
    exit 1
  }
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
    "dufs"
  ]
}
EOF

render_demo_apps "${OUT_DIR_SUBSET_A}" "${SELECTED_APPS_FILE}"
render_demo_apps "${OUT_DIR_SUBSET_B}" "${SELECTED_APPS_FILE}"

python3 - <<'PY' \
  "${FIXTURE_APPLICATION_CATALOG_FILE}" \
  "${GENERATED_APPLICATION_IMAGES_LOCK_FILE}" \
  "${MERGED_CATALOG_FILE}" \
  "${MERGED_IMAGES_LOCK_FILE}"
import json
import sys
from pathlib import Path

demo_catalog = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
demo_lock = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
demo_apps = {app["id"]: dict(app) for app in demo_catalog["apps"]}
demo_images = {image["name"]: dict(image) for image in demo_lock["images"]}


def stable_app(base_id: str, stable_id: str, *, local_app_id: str | None = None) -> dict:
    app = dict(demo_apps[base_id])
    app["id"] = stable_id
    app["app_uid"] = stable_id
    app["local_app_id"] = local_app_id or base_id
    return app


hello_world_app = {
    "id": "techofourown/hello-world",
    "app_uid": "techofourown/hello-world",
    "local_app_id": "hello-world",
    "display_name": "Hello World",
    "description": "Small hello-world app sourced from a second sw-ourbox-apps repo.",
    "service_name": "hello-world",
    "service_port": 80,
    "host_template": "hello.{box_host}",
    "path": "/",
    "expected_status": 200,
    "body_marker": "Hello, world.",
    "route_description": "hello-world-root",
    "default_backend": False,
    "image_names": ["hello-world"],
    "services": [
        {
            "name": "hello-world",
            "image": "hello-world",
            "port": 80,
            "command": [],
            "args": [],
            "env": {},
            "storage": None,
            "health_path": "/",
        }
    ],
}
ourbox_chat_app = {
    "id": "techofourown/ourbox-chat",
    "app_uid": "techofourown/ourbox-chat",
    "local_app_id": "ourbox-chat",
    "display_name": "OurBox Chat",
    "description": "CPU-only local chat UI backed by a bundled small GGUF model.",
    "service_name": "ourbox-chat",
    "service_port": 8080,
    "host_template": "chat.{box_host}",
    "path": "/",
    "expected_status": 200,
    "body_marker": "OurBox Chat",
    "route_description": "ourbox-chat-root",
    "default_backend": False,
    "image_names": ["ourbox-chat"],
    "services": [
        {
            "name": "ourbox-chat",
            "image": "ourbox-chat",
            "port": 8080,
            "command": [],
            "args": [],
            "env": {},
            "storage": None,
            "health_path": "/",
        }
    ],
}

merged_catalog = {
    "schema": 1,
    "kind": "ourbox-application-catalog",
    "catalog_id": "merged-live-smoke",
    "catalog_name": "Merged Live Smoke Catalog",
    "catalog_description": "Validation-only merged catalog shaped like the live stable-id app surface.",
    "default_app_ids": [
        "techofourown/hello-world",
        "techofourown/ourbox-chat",
        "techofourown/todo-bloom",
        "thirdparty/dufs",
        "thirdparty/flatnotes",
    ],
    "apps": [
        hello_world_app,
        ourbox_chat_app,
        stable_app("todo-bloom", "techofourown/todo-bloom", local_app_id="todo-bloom"),
        stable_app("dufs", "thirdparty/dufs", local_app_id="dufs"),
        stable_app("flatnotes", "thirdparty/flatnotes", local_app_id="flatnotes"),
    ],
}

merged_lock = {
    "schema": demo_lock["schema"],
    "profile": "merged-live-smoke",
    "images": [
        {
            "name": "nginx",
            "ref": demo_images["nginx"]["ref"],
            "used_by": ["techofourown/todo-bloom"],
        },
        {
            "name": "dufs",
            "ref": demo_images["dufs"]["ref"],
            "used_by": ["thirdparty/dufs"],
        },
        {
            "name": "flatnotes",
            "ref": demo_images["flatnotes"]["ref"],
            "used_by": ["thirdparty/flatnotes"],
        },
        {
            "name": "hello-world",
            "ref": "ghcr.io/techofourown/sw-ourbox-apps-hello-world/hello-world@sha256:" + ("6" * 64),
            "used_by": ["techofourown/hello-world"],
        },
        {
            "name": "ourbox-chat",
            "ref": "ghcr.io/techofourown/sw-ourbox-apps-chat/ourbox-chat@sha256:" + ("7" * 64),
            "used_by": ["techofourown/ourbox-chat"],
        },
    ],
}

Path(sys.argv[3]).write_text(json.dumps(merged_catalog, indent=2, sort_keys=True) + "\n", encoding="utf-8")
Path(sys.argv[4]).write_text(json.dumps(merged_lock, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

cat > "${MERGED_SELECTED_APPS_FILE}" <<'EOF'
{
  "schema": 1,
  "kind": "ourbox-selected-applications",
  "catalog_id": "merged-live-smoke",
  "selection_mode": "custom",
  "selected_app_ids": [
    "techofourown/hello-world",
    "techofourown/ourbox-chat",
    "techofourown/todo-bloom",
    "thirdparty/dufs",
    "thirdparty/flatnotes"
  ]
}
EOF

python3 "${ROOT}/tools/platform-contract/render-contract.py" \
  --contract-root "${ROOT}/platform-contract" \
  --output-dir "${OUT_DIR_MERGED}" \
  --profile demo-apps \
  --application-catalog "${MERGED_CATALOG_FILE}" \
  --images-lock-file "${MERGED_IMAGES_LOCK_FILE}" \
  --platform-images-lock-file "${GENERATED_PLATFORM_IMAGES_LOCK_FILE}" \
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

[[ ! -f "${OUT_DIR_SUBSET_A}/manifests/todo-bloom-deployment.yaml" ]] || {
  echo "selected-app subset render unexpectedly included todo-bloom" >&2
  exit 1
}
[[ ! -f "${OUT_DIR_SUBSET_A}/manifests/flatnotes-deployment.yaml" ]] || {
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
expected_ids = [
    "techofourown/hello-world",
    "techofourown/ourbox-chat",
    "techofourown/todo-bloom",
    "thirdparty/dufs",
    "thirdparty/flatnotes",
]
actual_ids = [app["id"] for app in apps]
if actual_ids != expected_ids:
    raise SystemExit(f"unexpected landing app ids for merged render: {actual_ids!r}")
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
expected_ids = [
    "techofourown/hello-world",
    "techofourown/ourbox-chat",
    "techofourown/todo-bloom",
    "thirdparty/dufs",
    "thirdparty/flatnotes",
]
actual_ids = [app["id"] for app in apps]
if actual_ids != expected_ids:
    raise SystemExit(f"unexpected landing status app ids for merged render: {actual_ids!r}")
PY

python3 - <<'PY' "${OUT_DIR_MERGED}/selected-app-surface.json"
import json
import sys
from pathlib import Path

surface = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
if surface["default_backend_app_id"] is not None:
    raise SystemExit(f"unexpected default backend app id: {surface['default_backend_app_id']!r}")
if surface["status_route"]["path"] != "/_ourbox/app-status.json":
    raise SystemExit(f"unexpected status route path: {surface['status_route']!r}")
if surface["status_route"]["path_type"] != "Exact":
    raise SystemExit(f"unexpected status route path_type: {surface['status_route']!r}")
apps = {app["id"]: app for app in surface["apps"]}
for app_id in (
    "techofourown/hello-world",
    "techofourown/ourbox-chat",
    "techofourown/todo-bloom",
    "thirdparty/dufs",
    "thirdparty/flatnotes",
):
    if app_id not in apps:
        raise SystemExit(f"selected app surface missing {app_id}")
hello = apps["techofourown/hello-world"]
chat = apps["techofourown/ourbox-chat"]
if hello["publish_mdns_alias"] is not True or hello["include_in_status"] is not True:
    raise SystemExit(f"unexpected hello flags: {hello!r}")
if chat["publish_mdns_alias"] is not True or chat["include_in_status"] is not True:
    raise SystemExit(f"unexpected chat flags: {chat!r}")
PY

python3 - <<'PY' "${OUT_DIR_MERGED}/manifests/50-demo-apps-ingress.yaml"
import sys
from pathlib import Path

import yaml

ingress = yaml.safe_load(Path(sys.argv[1]).read_text(encoding="utf-8"))
status_paths = [
    path
    for rule in ingress["spec"]["rules"]
    if rule.get("host") == "validate.ourbox.local"
    for path in rule.get("http", {}).get("paths", [])
    if path.get("path") == "/_ourbox/app-status.json"
]
if status_paths != [
    {
        "path": "/_ourbox/app-status.json",
        "pathType": "Exact",
        "backend": {
            "service": {
                "name": "landing-status",
                "port": {"number": 8080},
            }
        },
    }
]:
    raise SystemExit(f"unexpected landing status ingress path: {status_paths!r}")
PY

python3 - <<'PY' "${OUT_DIR_MERGED}/manifests/05-contract-metadata-configmap.yaml"
import json
import sys
from pathlib import Path

import yaml

path = Path(sys.argv[1])
config = yaml.safe_load(path.read_text(encoding="utf-8"))
platform_images = json.loads(config["data"]["platform_images.json"])
landing_ref = platform_images.get("landing", "")
if not landing_ref.startswith("docker.io/library/nginx:1.27-alpine@sha256:"):
    raise SystemExit(f"unexpected landing platform image ref: {landing_ref!r}")
status_ref = platform_images.get("landing-status", "")
if not status_ref.startswith("docker.io/library/python:3.12-alpine@sha256:"):
    raise SystemExit(f"unexpected landing-status platform image ref: {status_ref!r}")
PY

render_expect_failure \
  rejected-catalog-ref \
  "platform-contract build no longer accepts OURBOX_APPLICATION_CATALOG_REF" \
  env OURBOX_APPLICATION_CATALOG_REF=ghcr.io/example/catalog@sha256:0000000000000000000000000000000000000000000000000000000000000000 \
  "${ROOT}/tools/platform-contract/build.sh"

render_expect_failure \
  rejected-fixture-gate \
  "platform-contract build no longer uses OURBOX_ALLOW_FIXTURE_APPLICATION_CATALOG" \
  env OURBOX_ALLOW_FIXTURE_APPLICATION_CATALOG=1 \
  "${ROOT}/tools/platform-contract/build.sh"

mkdir -p "${IDENTITY_CONTRACT_DIR}"
cp -a "${ROOT}/platform-contract/." "${IDENTITY_CONTRACT_DIR}/"
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
tar -tzf "${ROOT}/dist/platform-contract.tar.gz" \
  | grep -Fx 'platform-contract/rendered/defaults/demo-apps/selected-apps.json' >/dev/null \
  || {
    echo "built platform-contract tarball is missing rendered/defaults/demo-apps/selected-apps.json" >&2
    exit 1
  }
tar -tzf "${ROOT}/dist/platform-contract.tar.gz" \
  | grep -Fx 'platform-contract/rendered/defaults/demo-apps/selected-app-surface.json' >/dev/null \
  || {
    echo "built platform-contract tarball is missing rendered/defaults/demo-apps/selected-app-surface.json" >&2
    exit 1
  }

echo "Validated deterministic rendered platform contract: ${OUT_DIR_A}"
