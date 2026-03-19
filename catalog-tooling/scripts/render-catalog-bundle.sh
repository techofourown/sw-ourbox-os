#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CATALOG_DIR="${ROOT}/catalog"
DIST_DIR="${ROOT}/dist"
BUNDLE_DIR="${DIST_DIR}/application-catalog-bundle"
GENERATED_IMAGES_LOCK="${DIST_DIR}/images.lock.json"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/ourbox-catalog-render.XXXXXX")"
trap 'rm -rf "${TMP_ROOT}"' EXIT

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "required command not found: $1" >&2
    exit 1
  }
}

need_cmd oras
need_cmd python3
need_cmd sha256sum
need_cmd tar

mkdir -p "${DIST_DIR}"
rm -rf "${BUNDLE_DIR}"
mkdir -p "${BUNDLE_DIR}"

cp "${CATALOG_DIR}/catalog.json" "${BUNDLE_DIR}/catalog.json"
cp "${CATALOG_DIR}/profile.env" "${BUNDLE_DIR}/profile.env"
python3 - <<'PY' \
  "${CATALOG_DIR}/catalog.json" \
  "${CATALOG_DIR}/image-sources.json" \
  "${CATALOG_DIR}/profile.env" \
  "${GENERATED_IMAGES_LOCK}" \
  "${BUNDLE_DIR}/manifest.env"
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

DIGEST_RE = re.compile(r"^sha256:[0-9a-f]{64}$")
PINNED_REF_RE = re.compile(r"^[^\s]+@sha256:[0-9a-f]{64}$")


def load_env(path: Path) -> dict[str, str]:
    data: dict[str, str] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        key, value = line.split("=", 1)
        data[key] = value
    return data


def repository_for_ref(ref: str) -> str:
    without_digest = ref.split("@", 1)[0]
    last_slash = without_digest.rfind("/")
    last_colon = without_digest.rfind(":")
    if last_colon > last_slash:
        return without_digest[:last_colon]
    return without_digest


catalog = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
image_sources = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
profile = load_env(Path(sys.argv[3]))
generated_images_lock_path = Path(sys.argv[4])
manifest_path = Path(sys.argv[5])

if catalog.get("schema") != 1 or catalog.get("kind") != "ourbox-application-catalog":
    raise SystemExit("catalog.json must declare schema=1 and kind=ourbox-application-catalog")
if image_sources.get("schema") != 1:
    raise SystemExit("image-sources.json must declare schema=1")

apps = catalog.get("apps")
default_app_ids = catalog.get("default_app_ids")
if not isinstance(apps, list) or not apps:
    raise SystemExit("catalog.json must declare a non-empty apps list")
if not isinstance(default_app_ids, list) or not default_app_ids:
    raise SystemExit("catalog.json must declare non-empty default_app_ids")

catalog_id = str(catalog.get("catalog_id", "")).strip()
catalog_name = str(catalog.get("catalog_name", "")).strip()
name_slug = re.sub(r"[^a-z0-9]+", "-", catalog_name.lower()).strip("-")
if profile.get("OURBOX_APPLICATION_CATALOG_ID") != catalog_id:
    raise SystemExit("profile.env catalog id does not match catalog.json")
if profile.get("OURBOX_APPLICATION_CATALOG_NAME_SLUG") != name_slug:
    raise SystemExit("profile.env catalog slug does not match catalog.json")
if profile.get("OURBOX_APPLICATION_CATALOG_DEFAULT_APP_IDS") != ",".join(default_app_ids):
    raise SystemExit("profile.env default app ids do not match catalog.json")

platform_contract_digest = os.environ.get("OURBOX_PLATFORM_CONTRACT_DIGEST", "").strip()
if not DIGEST_RE.fullmatch(platform_contract_digest):
    raise SystemExit("OURBOX_PLATFORM_CONTRACT_DIGEST must be set in the environment")

app_ids: set[str] = set()
image_names_used_by_catalog: dict[str, set[str]] = {}
for app in apps:
    app_id = str(app.get("id", "")).strip()
    if not app_id:
        raise SystemExit("catalog.json contains an app without an id")
    if app_id in app_ids:
        raise SystemExit(f"catalog.json contains duplicate app id: {app_id}")
    app_ids.add(app_id)
    names = app.get("image_names")
    if not isinstance(names, list) or not names:
        raise SystemExit(f"catalog.json app {app_id!r} must declare non-empty image_names")
    for raw_name in names:
        image_name = str(raw_name).strip()
        if not image_name:
            raise SystemExit(f"catalog.json app {app_id!r} declares an empty image name")
        image_names_used_by_catalog.setdefault(image_name, set()).add(app_id)

unknown_defaults = sorted(set(str(item).strip() for item in default_app_ids) - app_ids)
if unknown_defaults:
    raise SystemExit(f"catalog.json declares unknown default_app_ids: {', '.join(unknown_defaults)}")

source_entries = image_sources.get("images")
if not isinstance(source_entries, list) or not source_entries:
    raise SystemExit("image-sources.json must declare a non-empty images list")

resolved_entries = []
seen_names: set[str] = set()
for entry in source_entries:
    name = str(entry.get("name", "")).strip()
    source_ref = str(entry.get("ref", "")).strip()
    used_by = entry.get("used_by")
    if not name or not source_ref:
        raise SystemExit("image-sources.json entries must declare non-empty name and ref")
    if name in seen_names:
        raise SystemExit(f"image-sources.json contains duplicate image name: {name}")
    if any(ch.isspace() for ch in source_ref):
        raise SystemExit(f"image-sources.json ref must be a single-line OCI ref without whitespace: {source_ref!r}")
    if not isinstance(used_by, list) or not used_by:
        raise SystemExit(f"image-sources.json entry {name!r} must declare non-empty used_by")
    used_by_ids = [str(item).strip() for item in used_by]
    if any(not app_id for app_id in used_by_ids):
        raise SystemExit(f"image-sources.json entry {name!r} contains an empty used_by id")
    unknown_used_by = sorted(set(used_by_ids) - app_ids)
    if unknown_used_by:
        raise SystemExit(f"image-sources.json entry {name!r} declares unknown used_by ids: {', '.join(unknown_used_by)}")
    expected_used_by = image_names_used_by_catalog.get(name)
    if not expected_used_by:
        raise SystemExit(f"image-sources.json entry {name!r} is not referenced by catalog.json")
    if set(used_by_ids) != expected_used_by:
        raise SystemExit(
            f"image-sources.json entry {name!r} used_by does not match catalog.json references: "
            f"expected {sorted(expected_used_by)}, got {sorted(set(used_by_ids))}"
        )

    if PINNED_REF_RE.fullmatch(source_ref):
        pinned_ref = source_ref
    else:
        digest = subprocess.run(
            ["oras", "resolve", source_ref],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        if not DIGEST_RE.fullmatch(digest):
            raise SystemExit(f"oras resolve returned an invalid digest for {source_ref!r}: {digest!r}")
        pinned_ref = f"{repository_for_ref(source_ref)}@{digest}"

    resolved_entries.append(
        {
            "name": name,
            "ref": pinned_ref,
            "used_by": used_by_ids,
        }
    )
    seen_names.add(name)

missing_image_names = sorted(set(image_names_used_by_catalog) - seen_names)
if missing_image_names:
    raise SystemExit(f"catalog.json references image names missing from image-sources.json: {', '.join(missing_image_names)}")

generated_images_lock = {
    "schema": 1,
    "profile": str(image_sources.get("profile", catalog_id)).strip() or catalog_id,
    "images": resolved_entries,
}
generated_images_lock_path.write_text(
    json.dumps(generated_images_lock, indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)

created = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
lines = [
    f"OURBOX_APPLICATION_CATALOG_ID={catalog_id}",
    f"OURBOX_APPLICATION_CATALOG_NAME_SLUG={name_slug}",
    f"OURBOX_APPLICATION_CATALOG_CREATED={created}",
    f"OURBOX_APPLICATION_CATALOG_DEFAULT_APP_IDS={','.join(default_app_ids)}",
    f"OURBOX_APPLICATION_CATALOG_APP_COUNT={len(apps)}",
    f"OURBOX_APPLICATION_CATALOG_IMAGE_COUNT={len(resolved_entries)}",
    f"OURBOX_PLATFORM_CONTRACT_DIGEST={platform_contract_digest}",
]
manifest_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY

cp "${GENERATED_IMAGES_LOCK}" "${BUNDLE_DIR}/images.lock.json"

tar -czf "${DIST_DIR}/application-catalog-bundle.tar.gz" -C "${BUNDLE_DIR}" .
sha256sum "${DIST_DIR}/application-catalog-bundle.tar.gz" \
  | awk '{print $1}' > "${DIST_DIR}/application-catalog-bundle.tar.gz.sha256"

echo "Rendered catalog bundle at ${DIST_DIR}/application-catalog-bundle.tar.gz"
