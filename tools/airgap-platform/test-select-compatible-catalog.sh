#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${ROOT}/tools/airgap-platform/select-compatible-catalog.sh"

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

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"
  if [[ "${haystack}" != *"${needle}"* ]]; then
    printf 'ASSERTION FAILED: %s\n' "${message}" >&2
    printf '  expected to find: %s\n' "${needle}" >&2
    printf '  in: %s\n' "${haystack}" >&2
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

lookup_bound_digest() {
  local digest="$1" entry key value
  IFS=';' read -r -a entries <<< "${FAKE_ORAS_BOUND_MAP:-}"
  for entry in "${entries[@]}"; do
    key="${entry%%=*}"
    value="${entry#*=}"
    if [[ "${key}" == "${digest}" ]]; then
      printf '%s\n' "${value}"
      return 0
    fi
  done
  return 1
}

case "${cmd}" in
  resolve)
    ref="${1:-}"
    if [[ "${ref}" == "${FAKE_ORAS_LATEST_MUTABLE_REF:-__none__}" ]]; then
      count_file="${FAKE_ORAS_STATE_DIR:?}/latest-resolve-count"
      count=0
      [[ -f "${count_file}" ]] && count="$(cat "${count_file}")"
      IFS=',' read -r -a digests <<< "${FAKE_ORAS_LATEST_DIGEST_SEQUENCE:-}"
      [[ "${#digests[@]}" -gt 0 ]] || exit 1
      if (( count >= ${#digests[@]} )); then
        index=$((${#digests[@]} - 1))
      else
        index="${count}"
      fi
      printf '%s\n' "${digests[${index}]}"
      printf '%s\n' "$((count + 1))" > "${count_file}"
      exit 0
    fi

    if [[ "${ref}" == "${FAKE_ORAS_ORIGINAL_PINNED_REF:-__none__}" ]]; then
      printf '%s\n' "${ref##*@}"
      exit 0
    fi

    exit 1
    ;;
  pull)
    ref="${1:-}"
    shift || true
    output_dir=""
    while (($#)); do
      case "$1" in
        -o)
          output_dir="$2"
          shift 2
          ;;
        *)
          shift
          ;;
      esac
    done

    [[ -n "${output_dir}" ]] || exit 1
    mkdir -p "${output_dir}"

    digest="${ref##*@}"
    bound_digest="$(lookup_bound_digest "${digest}")" || exit 1

    work_dir="$(mktemp -d)"
    printf 'OURBOX_PLATFORM_CONTRACT_DIGEST=%s\n' "${bound_digest}" > "${work_dir}/manifest.env"
    tar -czf "${output_dir}/application-catalog-bundle.tar.gz" -C "${work_dir}" manifest.env
    rm -rf "${work_dir}"
    ;;
  *)
    exit 4
    ;;
esac
EOF_ORAS
  chmod +x "${bin_dir}/oras"
}

make_fake_curl() {
  local bin_dir="$1"
  mkdir -p "${bin_dir}"
  cat > "${bin_dir}/curl" <<'EOF_CURL'
#!/usr/bin/env bash
set -euo pipefail

status="${FAKE_CURL_STATUS:-204}"
body_file=""
stdout_format=""
payload=""
output_file=""

while (($#)); do
  case "$1" in
    -o)
      output_file="$2"
      shift 2
      ;;
    -w)
      stdout_format="$2"
      shift 2
      ;;
    -d)
      payload="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

if [[ -n "${FAKE_CURL_BODY_LOG:-}" ]]; then
  printf '%s\n' "${payload}" > "${FAKE_CURL_BODY_LOG}"
fi

if [[ -n "${output_file}" ]]; then
  : > "${output_file}"
fi

if [[ -n "${stdout_format}" ]]; then
  printf '%s' "${status}"
fi

if [[ "${status}" =~ ^2 ]]; then
  exit 0
fi

exit 22
EOF_CURL
  chmod +x "${bin_dir}/curl"
}

test_prefers_original_matching_ref_without_dispatch() {
  local tmp bin_dir output_file
  tmp="$(mktemp -d)"
  bin_dir="${tmp}/bin"
  output_file="${tmp}/github-output"

  make_fake_oras "${bin_dir}"
  make_fake_curl "${bin_dir}"

  (
    export PATH="${bin_dir}:${PATH}"
    export FAKE_ORAS_STATE_DIR="${tmp}/state"
    mkdir -p "${FAKE_ORAS_STATE_DIR}"
    export FAKE_ORAS_ORIGINAL_PINNED_REF="ghcr.io/techofourown/sw-ourbox-catalog-demo@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    export FAKE_ORAS_LATEST_MUTABLE_REF="ghcr.io/techofourown/sw-ourbox-catalog-demo:latest"
    export FAKE_ORAS_LATEST_DIGEST_SEQUENCE="sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
    export FAKE_ORAS_BOUND_MAP="sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa=sha256:1111111111111111111111111111111111111111111111111111111111111111;sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb=sha256:2222222222222222222222222222222222222222222222222222222222222222"
    export EXPECTED_CONTRACT_DIGEST="sha256:1111111111111111111111111111111111111111111111111111111111111111"
    export ORIGINAL_CATALOG_PINNED_REF="${FAKE_ORAS_ORIGINAL_PINNED_REF}"
    export DEFAULT_CATALOG_REPO="ghcr.io/techofourown/sw-ourbox-catalog-demo"
    export GITHUB_OUTPUT="${output_file}"
    bash "${SCRIPT}"
  )

  assert_eq \
    "$(cat "${output_file}")" \
    "pinned_ref=ghcr.io/techofourown/sw-ourbox-catalog-demo@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" \
    "selector should keep the original pinned ref when it already matches the expected contract digest"

  rm -rf "${tmp}"
}

test_dispatches_and_waits_for_refreshed_latest_bundle() {
  local tmp bin_dir output_file dispatch_body
  tmp="$(mktemp -d)"
  bin_dir="${tmp}/bin"
  output_file="${tmp}/github-output"
  dispatch_body="${tmp}/dispatch-body.json"

  make_fake_oras "${bin_dir}"
  make_fake_curl "${bin_dir}"

  (
    export PATH="${bin_dir}:${PATH}"
    export FAKE_ORAS_STATE_DIR="${tmp}/state"
    mkdir -p "${FAKE_ORAS_STATE_DIR}"
    export FAKE_ORAS_ORIGINAL_PINNED_REF="ghcr.io/techofourown/sw-ourbox-catalog-demo@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    export FAKE_ORAS_LATEST_MUTABLE_REF="ghcr.io/techofourown/sw-ourbox-catalog-demo:latest"
    export FAKE_ORAS_LATEST_DIGEST_SEQUENCE="sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb,sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb,sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
    export FAKE_ORAS_BOUND_MAP="sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa=sha256:0000000000000000000000000000000000000000000000000000000000000000;sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb=sha256:0000000000000000000000000000000000000000000000000000000000000000;sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc=sha256:1111111111111111111111111111111111111111111111111111111111111111"
    export EXPECTED_CONTRACT_DIGEST="sha256:1111111111111111111111111111111111111111111111111111111111111111"
    export ORIGINAL_CATALOG_PINNED_REF="${FAKE_ORAS_ORIGINAL_PINNED_REF}"
    export DEFAULT_CATALOG_REPO="ghcr.io/techofourown/sw-ourbox-catalog-demo"
    export CATALOG_REPO_DISPATCH_TOKEN="test-token"
    export CATALOG_REFRESH_TIMEOUT_SECONDS=3
    export CATALOG_REFRESH_POLL_SECONDS=0
    export FAKE_CURL_BODY_LOG="${dispatch_body}"
    export GITHUB_OUTPUT="${output_file}"
    export GITHUB_REPOSITORY="techofourown/sw-ourbox-os"
    export GITHUB_SHA="5011324d77385f7130b8daa06a75f3dfe21cb637"
    bash "${SCRIPT}"
  )

  assert_eq \
    "$(cat "${output_file}")" \
    "pinned_ref=ghcr.io/techofourown/sw-ourbox-catalog-demo@sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc" \
    "selector should wait for refreshed latest to match the expected contract digest"

  assert_contains \
    "$(cat "${dispatch_body}")" \
    "\"event_type\":\"refresh-from-upstream-image-publish\"" \
    "selector should dispatch the expected catalog refresh event"
  assert_contains \
    "$(cat "${dispatch_body}")" \
    "\"platform_contract_digest\":\"sha256:1111111111111111111111111111111111111111111111111111111111111111\"" \
    "selector should dispatch the requested platform contract digest"

  rm -rf "${tmp}"
}

test_fails_closed_when_refresh_is_needed_but_no_dispatch_token_exists() {
  local tmp bin_dir
  tmp="$(mktemp -d)"
  bin_dir="${tmp}/bin"

  make_fake_oras "${bin_dir}"
  make_fake_curl "${bin_dir}"

  export FAKE_ORAS_STATE_DIR="${tmp}/state"
  mkdir -p "${FAKE_ORAS_STATE_DIR}"
  export FAKE_ORAS_ORIGINAL_PINNED_REF="ghcr.io/techofourown/sw-ourbox-catalog-demo@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  export FAKE_ORAS_LATEST_MUTABLE_REF="ghcr.io/techofourown/sw-ourbox-catalog-demo:latest"
  export FAKE_ORAS_LATEST_DIGEST_SEQUENCE="sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
  export FAKE_ORAS_BOUND_MAP="sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa=sha256:0000000000000000000000000000000000000000000000000000000000000000;sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb=sha256:0000000000000000000000000000000000000000000000000000000000000000"
  export EXPECTED_CONTRACT_DIGEST="sha256:1111111111111111111111111111111111111111111111111111111111111111"
  export ORIGINAL_CATALOG_PINNED_REF="${FAKE_ORAS_ORIGINAL_PINNED_REF}"
  export DEFAULT_CATALOG_REPO="ghcr.io/techofourown/sw-ourbox-catalog-demo"

  assert_fails \
    "set -euo pipefail; PATH='${bin_dir}:\$PATH'; export FAKE_ORAS_STATE_DIR='${FAKE_ORAS_STATE_DIR}'; export FAKE_ORAS_ORIGINAL_PINNED_REF='${FAKE_ORAS_ORIGINAL_PINNED_REF}'; export FAKE_ORAS_LATEST_MUTABLE_REF='${FAKE_ORAS_LATEST_MUTABLE_REF}'; export FAKE_ORAS_LATEST_DIGEST_SEQUENCE='${FAKE_ORAS_LATEST_DIGEST_SEQUENCE}'; export FAKE_ORAS_BOUND_MAP='${FAKE_ORAS_BOUND_MAP}'; export EXPECTED_CONTRACT_DIGEST='${EXPECTED_CONTRACT_DIGEST}'; export ORIGINAL_CATALOG_PINNED_REF='${ORIGINAL_CATALOG_PINNED_REF}'; export DEFAULT_CATALOG_REPO='${DEFAULT_CATALOG_REPO}'; bash '${SCRIPT}'" \
    "selector should fail closed when the catalog is stale and no dispatch token is available"

  rm -rf "${tmp}"
}

main() {
  test_prefers_original_matching_ref_without_dispatch
  test_dispatches_and_waits_for_refreshed_latest_bundle
  test_fails_closed_when_refresh_is_needed_but_no_dispatch_token_exists
  printf 'airgap-platform compatible catalog selector tests: PASS\n'
}

main "$@"
