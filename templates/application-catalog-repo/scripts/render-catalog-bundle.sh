#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CATALOG_DIR="${ROOT}/catalog"
DIST_DIR="${ROOT}/dist"
BUNDLE_DIR="${DIST_DIR}/application-catalog-bundle"

mkdir -p "${DIST_DIR}"
rm -rf "${BUNDLE_DIR}"
mkdir -p "${BUNDLE_DIR}"

cp "${CATALOG_DIR}/catalog.json" "${BUNDLE_DIR}/catalog.json"
cp "${CATALOG_DIR}/images.lock.json" "${BUNDLE_DIR}/images.lock.json"
cp "${CATALOG_DIR}/profile.env" "${BUNDLE_DIR}/profile.env"

python3 - <<'PY' "${CATALOG_DIR}/catalog.json" "${CATALOG_DIR}/images.lock.json" > "${BUNDLE_DIR}/manifest.env"
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

catalog = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
images = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

name_slug = re.sub(r"[^a-z0-9]+", "-", catalog["catalog_name"].strip().lower()).strip("-")
default_ids = ",".join(catalog["default_app_ids"])
created = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

lines = [
    f"OURBOX_APPLICATION_CATALOG_ID={catalog['catalog_id']}",
    f"OURBOX_APPLICATION_CATALOG_NAME_SLUG={name_slug}",
    f"OURBOX_APPLICATION_CATALOG_CREATED={created}",
    f"OURBOX_APPLICATION_CATALOG_DEFAULT_APP_IDS={default_ids}",
    f"OURBOX_APPLICATION_CATALOG_APP_COUNT={len(catalog['apps'])}",
    f"OURBOX_APPLICATION_CATALOG_IMAGE_COUNT={len(images['images'])}",
]
print("\n".join(lines))
PY

tar -czf "${DIST_DIR}/application-catalog-bundle.tar.gz" -C "${BUNDLE_DIR}" .
sha256sum "${DIST_DIR}/application-catalog-bundle.tar.gz" \
  | awk '{print $1}' > "${DIST_DIR}/application-catalog-bundle.tar.gz.sha256"

echo "Rendered catalog bundle at ${DIST_DIR}/application-catalog-bundle.tar.gz"
