#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/resolve-promotable-release-smoke.XXXXXX")"
BIN_DIR="${TMP_ROOT}/bin"
trap 'rm -rf "${TMP_ROOT}"' EXIT

mkdir -p "${BIN_DIR}"

# Build an isolated git repo with a source commit + chore(release) bump on top.
git -C "${TMP_ROOT}" init -q
git -C "${TMP_ROOT}" config user.email "smoke@test"
git -C "${TMP_ROOT}" config user.name "Smoke Test"
git -C "${TMP_ROOT}" config core.hooksPath /dev/null
git -C "${TMP_ROOT}" commit --allow-empty -m "feat: add calculator"
SOURCE_SHA="$(git -C "${TMP_ROOT}" rev-parse HEAD)"
git -C "${TMP_ROOT}" commit --allow-empty -m "chore(release): 1.0.0"
RELEASE_SHA="$(git -C "${TMP_ROOT}" rev-parse HEAD)"
git -C "${TMP_ROOT}" tag v1.0.0

# Stub gh: return a single non-draft, non-prerelease release for 'release list'.
cat > "${BIN_DIR}/gh" <<'EOF_GH'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "release" && "${2:-}" == "list" ]]; then
  printf '[{"tagName":"v1.0.0","isDraft":false,"isPrerelease":false}]\n'
  exit 0
fi
echo "unexpected gh command: $*" >&2
exit 95
EOF_GH
chmod +x "${BIN_DIR}/gh"

run_script() {
  RELEASE_CONTROL_ROOT="${TMP_ROOT}" \
  GITHUB_REPOSITORY="test/test" \
  PATH="${BIN_DIR}:${PATH}" \
    bash "${SCRIPT_DIR}/resolve-promotable-release.sh" "$@"
}

# Case 1: source commit → should find v1.0.0
result="$(run_script stable "${SOURCE_SHA}")"
[[ "${result}" == "v1.0.0" ]] || {
  printf 'FAIL source-commit: expected v1.0.0, got %s\n' "${result}" >&2
  exit 1
}

# Case 2: release commit (the bug scenario) → should also find v1.0.0 after normalization
result="$(run_script stable "${RELEASE_SHA}")"
[[ "${result}" == "v1.0.0" ]] || {
  printf 'FAIL release-commit: expected v1.0.0, got %s\n' "${result}" >&2
  exit 1
}

# Case 3: unrelated commit → should exit 3 (no match)
set +e
run_script stable "0000000000000000000000000000000000000000" >/dev/null 2>&1
no_match_status=$?
set -e
[[ "${no_match_status}" -eq 3 ]] || {
  printf 'FAIL no-match: expected exit 3, got %d\n' "${no_match_status}" >&2
  exit 1
}

printf '[%s] resolve-promotable-release smoke passed\n' "$(date -Is)"
