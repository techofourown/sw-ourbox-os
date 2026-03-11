#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROMOTE="${ROOT}/tools/platform-contract/promote.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"
  if [[ "${actual}" != "${expected}" ]]; then
    printf 'ASSERTION FAILED: %s\n' "${message}" >&2
    printf '  expected: %s\n' "${expected}" >&2
    printf '  actual:   %s\n' "${actual}" >&2
    exit 1
  fi
}

assert_fails() {
  local cmd="$1"
  local message="$2"
  if bash -lc "${cmd}" >/dev/null 2>&1; then
    printf 'ASSERTION FAILED: %s\n' "${message}" >&2
    exit 1
  fi
}

make_fake_oras() {
  local bin_dir="$1"
  mkdir -p "${bin_dir}"
  cat > "${bin_dir}/oras" <<'EOF_ORAS'
#!/usr/bin/env bash
set -euo pipefail

cmd="${1:-}"
shift || true

case "${cmd}" in
  resolve)
    ref="${1:-}"
    if [[ "${ref}" == "${FAKE_ORAS_RESOLVE_REF:-__none__}" ]]; then
      printf '%s\n' "${FAKE_ORAS_RESOLVE_DIGEST:-}"
      exit 0
    fi
    exit 1
    ;;
  tag)
    pinned_ref="${1:-}"
    tag="${2:-}"
    printf '%s %s\n' "${pinned_ref}" "${tag}" >> "${FAKE_ORAS_TAG_LOG:?}"
    ;;
  *)
    exit 4
    ;;
esac
EOF_ORAS
  chmod +x "${bin_dir}/oras"
}

test_promote_writes_outputs_and_tags_release_ref() {
  local tmp fake_oras_dir tag_log digest
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"
  tag_log="${tmp}/oras-tags.log"
  digest="sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"
  export FAKE_ORAS_TAG_LOG="${tag_log}"

  rm -rf "${ROOT}/dist"
  mkdir -p "${ROOT}/dist"

  (
    cd "${ROOT}"
    PROMOTE_SOURCE_PINNED_REF="ghcr.io/techofourown/sw-ourbox-os/platform-contract@${digest}" \
      PROMOTE_SOURCE_REF="ghcr.io/techofourown/sw-ourbox-os/platform-contract:edge" \
      bash "${PROMOTE}" "v0.16.2"
  )

  assert_eq \
    "$(cat "${ROOT}/dist/platform-contract.promote.source.ref")" \
    "ghcr.io/techofourown/sw-ourbox-os/platform-contract:edge" \
    "promote should preserve the operator-facing source ref"
  assert_eq \
    "$(cat "${ROOT}/dist/platform-contract.promote.digest.ref")" \
    "ghcr.io/techofourown/sw-ourbox-os/platform-contract@${digest}" \
    "promote should record the pinned source ref"
  assert_eq \
    "$(cat "${ROOT}/dist/platform-contract.promote.target.ref")" \
    "ghcr.io/techofourown/sw-ourbox-os/platform-contract:v0.16.2" \
    "promote should record the release-tag target ref"
  assert_eq \
    "$(cat "${tag_log}")" \
    "ghcr.io/techofourown/sw-ourbox-os/platform-contract@${digest} v0.16.2" \
    "promote should retag the pinned digest into the release tag"

  rm -rf "${ROOT}/dist" "${tmp}"
}

test_promote_rejects_conflicting_existing_release_tag() {
  local tmp fake_oras_dir tag_log source_digest existing_digest
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"
  tag_log="${tmp}/oras-tags.log"
  source_digest="sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
  existing_digest="sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"
  export FAKE_ORAS_TAG_LOG="${tag_log}"
  export FAKE_ORAS_RESOLVE_REF="ghcr.io/techofourown/sw-ourbox-os/platform-contract:v0.16.2"
  export FAKE_ORAS_RESOLVE_DIGEST="${existing_digest}"

  assert_fails \
    "set -euo pipefail; cd '${ROOT}'; PATH='${fake_oras_dir}:\$PATH'; export FAKE_ORAS_TAG_LOG='${tag_log}'; export FAKE_ORAS_RESOLVE_REF='${FAKE_ORAS_RESOLVE_REF}'; export FAKE_ORAS_RESOLVE_DIGEST='${existing_digest}'; PROMOTE_SOURCE_PINNED_REF='ghcr.io/techofourown/sw-ourbox-os/platform-contract@${source_digest}' bash '${PROMOTE}' v0.16.2" \
    "promote should fail closed if the target release tag already points to another digest"

  rm -rf "${tmp}"
}

main() {
  test_promote_writes_outputs_and_tags_release_ref
  test_promote_rejects_conflicting_existing_release_tag
  printf 'platform-contract promote tests: PASS\n'
}

main "$@"
