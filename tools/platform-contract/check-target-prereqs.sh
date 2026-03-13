#!/usr/bin/env bash
set -euo pipefail

die() { echo "ERROR: $*" >&2; exit 1; }

need_cmd() {
  local cmd="$1"
  command -v "${cmd}" >/dev/null 2>&1 || die "required command not found: ${cmd}"
}

need_cmd python3

python3 - <<'PY' || die "python3 yaml module is missing (install PyYAML on the target image)"
import yaml  # noqa: F401
PY

echo "Target prerequisites present: python3, python3 yaml module"
