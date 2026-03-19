#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW="${ROOT}/.github/workflows/publish-catalog-bundle.yml"
SCRIPT="${ROOT}/scripts/publish-catalog-bundle.sh"

python3 - <<'PY' "${WORKFLOW}" "${SCRIPT}"
import sys
from pathlib import Path

workflow = Path(sys.argv[1]).read_text(encoding="utf-8")
script = Path(sys.argv[2]).read_text(encoding="utf-8")

workflow_lines = {line.strip() for line in workflow.splitlines()}
script_lines = {line.strip() for line in script.splitlines()}

workflow_required = [
    "bash scripts/publish-catalog-bundle.sh",
    "bash bootstrap.sh",
]

script_required = [
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

script_banned = [
    'DIGEST="$(oras resolve "${REF}")"',
    'oras tag "${REF}" "${IMMUTABLE_TAG}" >/dev/null',
]

messages = []

wf_missing = [i for i in workflow_required if not any(i in l for l in workflow_lines)]
if wf_missing:
    messages.append("workflow missing expected lines:")
    messages.extend(f"  - {item}" for item in wf_missing)

sc_missing = [i for i in script_required if i not in script_lines]
if sc_missing:
    messages.append("publish-catalog-bundle.sh missing expected invariants:")
    messages.extend(f"  - {item}" for item in sc_missing)

sc_banned = [i for i in script_banned if i in script_lines]
if sc_banned:
    messages.append("publish-catalog-bundle.sh has banned patterns:")
    messages.extend(f"  - {item}" for item in sc_banned)

if messages:
    raise SystemExit("\n".join(messages))
PY

echo "Workflow and publish script invariants look correct"
