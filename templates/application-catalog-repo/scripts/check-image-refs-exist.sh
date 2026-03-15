#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "required command not found: $1" >&2
    exit 1
  }
}

need_cmd python3
need_cmd oras

mapfile -t refs < <(
  python3 - <<'PY' "${ROOT}/catalog/images.lock.json"
import json
import sys
from pathlib import Path

images = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))["images"]
seen = []
for image in images:
    ref = str(image["ref"]).strip()
    if ref not in seen:
        seen.append(ref)
for ref in seen:
    print(ref)
PY
)

for ref in "${refs[@]}"; do
  [[ -n "${ref}" ]] || continue
  oras resolve "${ref}" >/dev/null
done

printf '[%s] image ref existence check passed\n' "$(date -Is)"
