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

need_cmd oras
need_cmd python3
need_cmd tar
need_cmd sha256sum

python3 -m py_compile "${ROOT}/scripts/render-catalog-rows.py"

WORK_ROOT="${TMP_ROOT}/template-copy"
mkdir -p "${WORK_ROOT}"
cp -R "${ROOT}/catalog" "${WORK_ROOT}/catalog"
cp -R "${ROOT}/scripts" "${WORK_ROOT}/scripts"

python3 - <<'PY' "${WORK_ROOT}/catalog/image-sources.json"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
payload = json.loads(path.read_text(encoding="utf-8"))
for entry in payload.get("images", []):
    name = str(entry["name"])
    entry["ref"] = f"ghcr.io/example-org/example-apps/{name}@sha256:" + ("1" * 64)
path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

python3 - <<'PY' "${WORK_ROOT}/catalog/catalog.json" "${WORK_ROOT}/catalog/image-sources.json" "${WORK_ROOT}/catalog/profile.env"
import json
import re
import sys
from pathlib import Path

catalog = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
image_sources = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
profile_lines = Path(sys.argv[3]).read_text(encoding="utf-8").splitlines()

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

images = image_sources.get("images")
if image_sources.get("schema") != 1 or not isinstance(images, list) or not images:
    raise SystemExit("image-sources.json must declare schema=1 and a non-empty images list")

seen_names = set()
for image in images:
    name = str(image.get("name", "")).strip()
    ref = str(image.get("ref", "")).strip()
    used_by = image.get("used_by")
    if not name or not ref:
        raise SystemExit("every image must declare non-empty name and ref")
    if name in seen_names:
        raise SystemExit(f"duplicate image source name: {name}")
    if re.search(r"\s", ref):
        raise SystemExit(f"image source ref must not contain whitespace: {ref!r}")
    if not isinstance(used_by, list) or not used_by:
        raise SystemExit(f"image {name} must declare non-empty used_by")
    unknown_used_by = sorted(set(str(app_id).strip() for app_id in used_by) - app_ids)
    if unknown_used_by:
        raise SystemExit(f"image {name} declares unknown used_by ids: {', '.join(unknown_used_by)}")
    seen_names.add(name)

missing_image_names = sorted(image_names - seen_names)
if missing_image_names:
    raise SystemExit(f"catalog apps reference unknown image names: {', '.join(missing_image_names)}")

profile = {}
for raw_line in profile_lines:
    line = raw_line.strip()
    if not line or line.startswith("#"):
        continue
    key, value = line.split("=", 1)
    profile[key] = value

PY

bash "${WORK_ROOT}/scripts/render-catalog-bundle.sh"

test -f "${WORK_ROOT}/dist/application-catalog-bundle.tar.gz"
test -f "${WORK_ROOT}/dist/application-catalog-bundle.tar.gz.sha256"
test -f "${WORK_ROOT}/dist/images.lock.json"

expected_sha="$(awk 'NF>=1 {print $1; exit}' "${WORK_ROOT}/dist/application-catalog-bundle.tar.gz.sha256")"
actual_sha="$(sha256sum "${WORK_ROOT}/dist/application-catalog-bundle.tar.gz" | awk '{print $1}')"
[[ "${expected_sha}" == "${actual_sha}" ]] || {
  echo "bundle sha mismatch" >&2
  exit 1
}

mkdir -p "${TMP_ROOT}/extract"
tar -xzf "${WORK_ROOT}/dist/application-catalog-bundle.tar.gz" -C "${TMP_ROOT}/extract"
cmp -s "${WORK_ROOT}/catalog/catalog.json" "${TMP_ROOT}/extract/catalog.json"
cmp -s "${WORK_ROOT}/dist/images.lock.json" "${TMP_ROOT}/extract/images.lock.json"
cmp -s "${WORK_ROOT}/catalog/profile.env" "${TMP_ROOT}/extract/profile.env"

python3 - <<'PY' \
  "${TMP_ROOT}/extract/manifest.env" \
  "${TMP_ROOT}/extract/profile.env" \
  "${WORK_ROOT}/catalog/catalog.json" \
  "${WORK_ROOT}/catalog/image-sources.json" \
  "${WORK_ROOT}/dist/images.lock.json"
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
image_sources = json.loads(Path(sys.argv[4]).read_text(encoding="utf-8"))
images_lock = json.loads(Path(sys.argv[5]).read_text(encoding="utf-8"))

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

source_by_name = {entry["name"]: entry for entry in image_sources["images"]}
for image in images_lock["images"]:
    ref = str(image["ref"])
    if not re.fullmatch(r"[^\s]+@sha256:[0-9a-f]{64}", ref):
        raise SystemExit(f"generated image lock ref must be digest pinned: {ref}")
    source_entry = source_by_name.get(str(image["name"]))
    if source_entry is None:
        raise SystemExit(f"generated image lock name missing from image-sources.json: {image['name']}")
    if source_entry["used_by"] != image["used_by"]:
        raise SystemExit(f"generated image lock used_by mismatch for {image['name']}")
PY

python3 "${WORK_ROOT}/scripts/render-catalog-rows.py" \
  --catalog-json "${WORK_ROOT}/catalog/catalog.json" \
  --profile-env "${WORK_ROOT}/catalog/profile.env" \
  --images-lock "${WORK_ROOT}/dist/images.lock.json" \
  --out-catalog "${TMP_ROOT}/catalog.tsv" \
  --channel stable \
  --tag "sha-test-run-1" \
  --created "2026-03-17T00:00:00Z" \
  --version "main-deadbeefcafe" \
  --revision "deadbeefcafedeadbeefcafedeadbeefcafedead" \
  --arch amd64 \
  --artifact-digest "sha256:1111111111111111111111111111111111111111111111111111111111111111" \
  --pinned-ref "ghcr.io/example/sw-ourbox-catalog-example@sha256:1111111111111111111111111111111111111111111111111111111111111111"

python3 - <<'PY' "${TMP_ROOT}/catalog.tsv" "${WORK_ROOT}/catalog/profile.env" "${WORK_ROOT}/catalog/catalog.json"
import csv
import json
import sys
from pathlib import Path

rows = list(csv.DictReader(Path(sys.argv[1]).open("r", encoding="utf-8"), delimiter="\t"))
if len(rows) != 1:
    raise SystemExit(f"expected one rendered catalog row, got {len(rows)}")
row = rows[0]
profile = {}
for raw_line in Path(sys.argv[2]).read_text(encoding="utf-8").splitlines():
    line = raw_line.strip()
    if not line or line.startswith("#"):
        continue
    key, value = line.split("=", 1)
    profile[key] = value
catalog = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))
expected = {
    "channel": "stable",
    "tag": "sha-test-run-1",
    "created": "2026-03-17T00:00:00Z",
    "version": "main-deadbeefcafe",
    "revision": "deadbeefcafedeadbeefcafedeadbeefcafedead",
    "arch": "amd64",
    "platform_profile": catalog["catalog_id"],
    "artifact_digest": "sha256:1111111111111111111111111111111111111111111111111111111111111111",
    "pinned_ref": "ghcr.io/example/sw-ourbox-catalog-example@sha256:1111111111111111111111111111111111111111111111111111111111111111",
}
for key, expected_value in expected.items():
    if row.get(key) != expected_value:
        raise SystemExit(f"unexpected {key}: {row.get(key)!r}")
if len(str(row.get("platform_images_lock_sha256", ""))) != 64:
    raise SystemExit(f"unexpected platform_images_lock_sha256: {row.get('platform_images_lock_sha256')!r}")
PY

# --- Test: merge with existing catalog (correct 10-col schema) ---
CATALOG_ID="$(python3 -c "import json; print(json.loads(open('${WORK_ROOT}/catalog/catalog.json').read())['catalog_id'])")"
EXISTING_CATALOG="${TMP_ROOT}/existing-catalog.tsv"
printf 'channel\ttag\tcreated\tversion\trevision\tarch\tplatform_profile\tplatform_images_lock_sha256\tartifact_digest\tpinned_ref\n' \
  > "${EXISTING_CATALOG}"
printf 'stable\tsha-old-run-1\t2026-03-10T00:00:00Z\tmain-aabbccddeeff\taabbccddeeffaabbccddeeffaabbccddeeffaabb\tamd64\t%s\t%s\tsha256:%s\tghcr.io/example/old@sha256:%s\n' \
  "${CATALOG_ID}" \
  "$(printf '3%.0s' {1..64})" \
  "$(printf '4%.0s' {1..64})" \
  "$(printf '4%.0s' {1..64})" \
  >> "${EXISTING_CATALOG}"

python3 "${WORK_ROOT}/scripts/render-catalog-rows.py" \
  --catalog-json "${WORK_ROOT}/catalog/catalog.json" \
  --profile-env "${WORK_ROOT}/catalog/profile.env" \
  --images-lock "${WORK_ROOT}/dist/images.lock.json" \
  --existing-catalog "${EXISTING_CATALOG}" \
  --out-catalog "${TMP_ROOT}/merged-catalog.tsv" \
  --channel stable \
  --tag "sha-merge-test-1" \
  --created "2026-03-17T01:00:00Z" \
  --version "main-deadbeefcafe" \
  --revision "deadbeefcafedeadbeefcafedeadbeefcafedead" \
  --arch amd64 \
  --artifact-digest "sha256:5555555555555555555555555555555555555555555555555555555555555555" \
  --pinned-ref "ghcr.io/example/new@sha256:5555555555555555555555555555555555555555555555555555555555555555"

python3 - <<'PY' "${TMP_ROOT}/merged-catalog.tsv"
import csv
import sys
from pathlib import Path

EXPECTED_HEADER = [
    "channel", "tag", "created", "version", "revision", "arch",
    "platform_profile", "platform_images_lock_sha256",
    "artifact_digest", "pinned_ref",
]

with Path(sys.argv[1]).open("r", encoding="utf-8") as f:
    reader = csv.DictReader(f, delimiter="\t")
    header = list(reader.fieldnames or [])
    rows = list(reader)

if header != EXPECTED_HEADER:
    raise SystemExit(f"merged catalog has wrong header: {header}")
if len(rows) != 2:
    raise SystemExit(f"expected 2 rows after merge, got {len(rows)}")
if rows[0]["tag"] != "sha-merge-test-1":
    raise SystemExit(f"newest row should be first (desc created), got {rows[0]['tag']}")
if rows[1]["tag"] != "sha-old-run-1":
    raise SystemExit(f"old row should be second, got {rows[1]['tag']}")
PY

# --- Test: stale 11-col header is discarded (warns, starts fresh) ---
STALE_CATALOG="${TMP_ROOT}/stale-catalog.tsv"
printf 'channel\ttag\tcreated\tversion\trevision\tarch\tplatform_contract_digest\tplatform_profile\tplatform_images_lock_sha256\tartifact_digest\tpinned_ref\n' \
  > "${STALE_CATALOG}"
printf 'stable\tsha-stale-1\t2026-03-01T00:00:00Z\tmain-stale\taaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\tamd64\tsha256:%s\tstale-id\t%s\tsha256:%s\tghcr.io/example/stale@sha256:%s\n' \
  "$(printf '2%.0s' {1..64})" \
  "$(printf '3%.0s' {1..64})" \
  "$(printf '4%.0s' {1..64})" \
  "$(printf '4%.0s' {1..64})" \
  >> "${STALE_CATALOG}"

STALE_STDERR="${TMP_ROOT}/stale-stderr.txt"
python3 "${WORK_ROOT}/scripts/render-catalog-rows.py" \
  --catalog-json "${WORK_ROOT}/catalog/catalog.json" \
  --profile-env "${WORK_ROOT}/catalog/profile.env" \
  --images-lock "${WORK_ROOT}/dist/images.lock.json" \
  --existing-catalog "${STALE_CATALOG}" \
  --out-catalog "${TMP_ROOT}/stale-output.tsv" \
  --channel stable \
  --tag "sha-stale-test-1" \
  --created "2026-03-17T02:00:00Z" \
  --version "main-deadbeefcafe" \
  --revision "deadbeefcafedeadbeefcafedeadbeefcafedead" \
  --arch amd64 \
  --artifact-digest "sha256:6666666666666666666666666666666666666666666666666666666666666666" \
  --pinned-ref "ghcr.io/example/fresh@sha256:6666666666666666666666666666666666666666666666666666666666666666" 2>"${STALE_STDERR}"

grep -q "stale catalog.tsv header" "${STALE_STDERR}" || {
  echo "ERROR: expected stale-header warning on stderr" >&2
  exit 1
}

python3 - <<'PY' "${TMP_ROOT}/stale-output.tsv"
import csv
import sys
from pathlib import Path

with Path(sys.argv[1]).open("r", encoding="utf-8") as f:
    reader = csv.DictReader(f, delimiter="\t")
    header = list(reader.fieldnames or [])
    rows = list(reader)

expected_header = [
    "channel", "tag", "created", "version", "revision", "arch",
    "platform_profile", "platform_images_lock_sha256",
    "artifact_digest", "pinned_ref",
]
if header != expected_header:
    raise SystemExit(f"stale-test output has wrong header: {header}")
if len(rows) != 1:
    raise SystemExit(f"expected 1 row (old rows discarded), got {len(rows)}")
if rows[0]["tag"] != "sha-stale-test-1":
    raise SystemExit(f"expected fresh row, got tag={rows[0]['tag']}")
PY

printf '[%s] catalog bundle smoke passed\n' "$(date -Is)"
