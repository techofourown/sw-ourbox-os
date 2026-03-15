#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - <<'PY' "${ROOT}/apps-manifest.json"
import json
import re
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
root = manifest_path.parent
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

if manifest.get("schema") != 1 or manifest.get("kind") != "ourbox-apps-collection":
    raise SystemExit("apps-manifest.json must declare schema=1 and kind=ourbox-apps-collection")

collection_id = str(manifest.get("collection_id", "")).strip()
display_name = str(manifest.get("display_name", "")).strip()
if not re.fullmatch(r"[a-z0-9][a-z0-9-]*", collection_id):
    raise SystemExit("apps-manifest.json must declare a lowercase collection_id")
if not display_name:
    raise SystemExit("apps-manifest.json must declare a non-empty display_name")

apps = manifest.get("apps")
if not isinstance(apps, list) or not apps:
    raise SystemExit("apps-manifest.json must declare a non-empty apps list")

seen_ids = set()
seen_repos = set()
for app in apps:
    app_id = str(app.get("app_id", "")).strip()
    app_name = str(app.get("display_name", "")).strip()
    source_path = str(app.get("source_path", "")).strip()
    image_repo = str(app.get("image_repo", "")).strip()
    default_tag = str(app.get("default_tag", "")).strip()

    if not re.fullmatch(r"[a-z0-9][a-z0-9-]*", app_id):
        raise SystemExit(f"invalid app_id: {app_id!r}")
    if not app_name or not source_path or not image_repo or not default_tag:
        raise SystemExit(f"app {app_id!r} must declare non-empty display_name, source_path, image_repo, and default_tag")
    if not image_repo.startswith("ghcr.io/"):
        raise SystemExit(f"app {app_id!r} image_repo must target GHCR: {image_repo}")
    if app_id in seen_ids:
        raise SystemExit(f"duplicate app_id: {app_id}")
    if image_repo in seen_repos:
        raise SystemExit(f"duplicate image_repo: {image_repo}")
    seen_ids.add(app_id)
    seen_repos.add(image_repo)

    app_dir = root / source_path
    if not app_dir.is_dir():
        raise SystemExit(f"missing source_path directory for {app_id}: {app_dir}")
    dockerfile = app_dir / "Dockerfile"
    if not dockerfile.is_file():
        raise SystemExit(f"missing Dockerfile for {app_id}: {dockerfile}")
PY

printf '[%s] apps manifest validation passed\n' "$(date -Is)"
