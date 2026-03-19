#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW="${ROOT}/.github/workflows/publish-catalog-bundle.yml"

python3 - <<'PY' "${WORKFLOW}"
import sys
from pathlib import Path

workflow = Path(sys.argv[1]).read_text(encoding="utf-8")
lines = {line.strip() for line in workflow.splitlines()}
required = [
    'IMMUTABLE_TAG="sha-${GITHUB_SHA}-run-${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT}"',
    'VERSION_TAG="main-${GITHUB_SHA::12}"',
    '"${IMMUTABLE_REF}" \\',
    'DIGEST="$(oras resolve "${IMMUTABLE_REF}")"',
    'oras tag "${IMMUTABLE_REF}" latest >/dev/null',
    'oras tag "${IMMUTABLE_REF}" stable >/dev/null',
    'oras tag "${IMMUTABLE_REF}" "${VERSION_TAG}" >/dev/null',
    'LATEST_DIGEST="$(oras resolve "${REF}")"',
    '[[ "${LATEST_DIGEST}" == "${DIGEST}" ]] || {',
    'python3 scripts/render-catalog-rows.py \\',
    'dist/catalog.tsv:text/tab-separated-values',
]
banned = [
    'DIGEST="$(oras resolve "${REF}")"',
    'oras tag "${REF}" "${IMMUTABLE_TAG}" >/dev/null',
]

missing = [item for item in required if item not in lines]
unexpected = [item for item in banned if item in lines]
if missing or unexpected:
    messages = []
    if missing:
        messages.append("missing expected workflow invariants:")
        messages.extend(f"  - {item}" for item in missing)
    if unexpected:
        messages.append("found banned workflow patterns:")
        messages.extend(f"  - {item}" for item in unexpected)
    raise SystemExit("\n".join(messages))
PY

echo "Workflow publish invariants look correct: ${WORKFLOW}"
