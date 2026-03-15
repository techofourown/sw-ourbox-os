#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/ourbox-catalog-bundle-smoke.XXXXXX")"
trap 'rm -rf "${TMP_ROOT}"' EXIT

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "required command not found: $1" >&2
    exit 1
  }
}

need_cmd python3
need_cmd tar
need_cmd sha256sum

python3 - <<'PY' "${ROOT}/catalog/catalog.json" "${ROOT}/catalog/images.lock.json"
import json
import re
import sys
from pathlib import Path

catalog = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
images_lock = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

if catalog.get("schema") != 1 or catalog.get("kind") != "ourbox-application-catalog":
    raise SystemExit("catalog.json must declare schema=1 and kind=ourbox-application-catalog")

apps = catalog.get("apps")
if not isinstance(apps, list) or not apps:
    raise SystemExit("catalog.json must declare a non-empty apps list")

app_ids = set()
app_uids = set()
image_names = set()
for app in apps:
    app_id = str(app.get("id", "")).strip()
    app_uid = str(app.get("app_uid", "")).strip()
    names = app.get("image_names")
    if not app_id or not app_uid:
        raise SystemExit("every app must declare non-empty id and app_uid")
    if app_id in app_ids:
        raise SystemExit(f"duplicate app id: {app_id}")
    if app_uid in app_uids:
        raise SystemExit(f"duplicate app_uid: {app_uid}")
    if not isinstance(names, list) or not names:
        raise SystemExit(f"app {app_id} must declare non-empty image_names")
    app_ids.add(app_id)
    app_uids.add(app_uid)
    image_names.update(str(name).strip() for name in names)

defaults = catalog.get("default_app_ids")
if not isinstance(defaults, list) or not defaults:
    raise SystemExit("catalog.json must declare non-empty default_app_ids")
unknown_defaults = sorted(set(defaults) - app_ids)
if unknown_defaults:
    raise SystemExit(f"catalog.json declares unknown default_app_ids: {', '.join(unknown_defaults)}")

images = images_lock.get("images")
if images_lock.get("schema") != 1 or not isinstance(images, list) or not images:
    raise SystemExit("images.lock.json must declare schema=1 and a non-empty images list")

seen_names = set()
for image in images:
    name = str(image.get("name", "")).strip()
    ref = str(image.get("ref", "")).strip()
    used_by = image.get("used_by")
    if not name or not ref:
        raise SystemExit("every image must declare non-empty name and ref")
    if name in seen_names:
        raise SystemExit(f"duplicate image lock name: {name}")
    if not re.fullmatch(r"[^\s]+@sha256:[0-9a-f]{64}", ref):
        raise SystemExit(f"image ref must be digest-pinned: {ref}")
    if not isinstance(used_by, list) or not used_by:
        raise SystemExit(f"image {name} must declare non-empty used_by")
    unknown_used_by = sorted(set(str(app_id).strip() for app_id in used_by) - app_ids)
    if unknown_used_by:
        raise SystemExit(f"image {name} declares unknown used_by ids: {', '.join(unknown_used_by)}")
    seen_names.add(name)

missing_image_names = sorted(image_names - seen_names)
if missing_image_names:
    raise SystemExit(f"catalog apps reference unknown image names: {', '.join(missing_image_names)}")
PY

bash "${ROOT}/scripts/render-catalog-bundle.sh"

test -f "${ROOT}/dist/application-catalog-bundle.tar.gz"
test -f "${ROOT}/dist/application-catalog-bundle.tar.gz.sha256"

expected_sha="$(awk 'NF>=1 {print $1; exit}' "${ROOT}/dist/application-catalog-bundle.tar.gz.sha256")"
actual_sha="$(sha256sum "${ROOT}/dist/application-catalog-bundle.tar.gz" | awk '{print $1}')"
[[ "${expected_sha}" == "${actual_sha}" ]] || {
  echo "bundle sha mismatch" >&2
  exit 1
}

mkdir -p "${TMP_ROOT}/extract"
tar -xzf "${ROOT}/dist/application-catalog-bundle.tar.gz" -C "${TMP_ROOT}/extract"
cmp -s "${ROOT}/catalog/catalog.json" "${TMP_ROOT}/extract/catalog.json"
cmp -s "${ROOT}/catalog/images.lock.json" "${TMP_ROOT}/extract/images.lock.json"
cmp -s "${ROOT}/catalog/profile.env" "${TMP_ROOT}/extract/profile.env"

python3 - <<'PY' "${TMP_ROOT}/extract/manifest.env" "${TMP_ROOT}/extract/profile.env" "${ROOT}/catalog/catalog.json" "${ROOT}/catalog/images.lock.json"
import json
import re
import sys
from pathlib import Path

strict_line = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=[^\s]+$")

def load_env(path):
    data = {}
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        if not line or line.startswith("#"):
            continue
        if not strict_line.fullmatch(line):
            raise SystemExit(f"strict metadata violation in {path}: {line}")
        key, value = line.split("=", 1)
        data[key] = value
    return data

manifest = load_env(sys.argv[1])
profile = load_env(sys.argv[2])
catalog = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))
images_lock = json.loads(Path(sys.argv[4]).read_text(encoding="utf-8"))

expected_slug = re.sub(r"[^a-z0-9]+", "-", catalog["catalog_name"].strip().lower()).strip("-")
if manifest.get("OURBOX_APPLICATION_CATALOG_ID") != catalog["catalog_id"]:
    raise SystemExit("manifest catalog id mismatch")
if manifest.get("OURBOX_APPLICATION_CATALOG_NAME_SLUG") != expected_slug:
    raise SystemExit("manifest catalog name slug mismatch")
if manifest.get("OURBOX_APPLICATION_CATALOG_DEFAULT_APP_IDS") != ",".join(catalog["default_app_ids"]):
    raise SystemExit("manifest default app ids mismatch")
if manifest.get("OURBOX_APPLICATION_CATALOG_APP_COUNT") != str(len(catalog["apps"])):
    raise SystemExit("manifest app count mismatch")
if manifest.get("OURBOX_APPLICATION_CATALOG_IMAGE_COUNT") != str(len(images_lock["images"])):
    raise SystemExit("manifest image count mismatch")
if profile.get("OURBOX_APPLICATION_CATALOG_ID") != catalog["catalog_id"]:
    raise SystemExit("profile catalog id mismatch")
if profile.get("OURBOX_APPLICATION_CATALOG_NAME_SLUG") != expected_slug:
    raise SystemExit("profile catalog name slug mismatch")
if profile.get("OURBOX_APPLICATION_CATALOG_DEFAULT_APP_IDS") != ",".join(catalog["default_app_ids"]):
    raise SystemExit("profile default app ids mismatch")
PY

printf '[%s] catalog bundle smoke passed\n' "$(date -Is)"
