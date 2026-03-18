#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALIDATE="${ROOT}/tools/approved-upstream-inputs/validate.py"

assert_fails() {
  local cmd="$1"
  local message="$2"
  if bash -lc "${cmd}" >/dev/null 2>&1; then
    printf 'ASSERTION FAILED: %s\n' "${message}" >&2
    exit 1
  fi
}

make_fake_node() {
  local bin_dir="$1"
  mkdir -p "${bin_dir}"
  cat > "${bin_dir}/node" <<'EOF_NODE'
#!/usr/bin/env bash
exit 0
EOF_NODE
  chmod +x "${bin_dir}/node"
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
    case "${ref}" in
      ghcr.io/example/platform-contract:v9.9.9|ghcr.io/example/platform-contract@sha256:1111111111111111111111111111111111111111111111111111111111111111)
        printf '%s\n' 'sha256:1111111111111111111111111111111111111111111111111111111111111111'
        ;;
      ghcr.io/example/airgap-platform:v9.9.9-arm64|ghcr.io/example/airgap-platform@sha256:2222222222222222222222222222222222222222222222222222222222222222)
        printf '%s\n' 'sha256:2222222222222222222222222222222222222222222222222222222222222222'
        ;;
      ghcr.io/example/airgap-platform:v9.9.9-amd64|ghcr.io/example/airgap-platform@sha256:3333333333333333333333333333333333333333333333333333333333333333)
        printf '%s\n' 'sha256:3333333333333333333333333333333333333333333333333333333333333333'
        ;;
      *)
        exit 1
        ;;
    esac
    ;;
  pull)
    ref="${1:-}"
    shift || true
    out=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -o)
          out="$2"
          shift 2
          ;;
        *)
          shift
          ;;
      esac
    done
    [[ -n "${out}" ]] || exit 2
    mkdir -p "${out}"
    case "${ref}" in
      ghcr.io/example/platform-contract:v9.9.9)
        cp -a "${FAKE_PLATFORM_DIR}/." "${out}/"
        ;;
      ghcr.io/example/airgap-platform:v9.9.9-arm64)
        cp -a "${FAKE_AIRGAP_ARM64_DIR}/." "${out}/"
        ;;
      ghcr.io/example/airgap-platform:v9.9.9-amd64)
        cp -a "${FAKE_AIRGAP_AMD64_DIR}/." "${out}/"
        ;;
      *)
        exit 3
        ;;
    esac
    ;;
  *)
    exit 4
    ;;
esac
EOF_ORAS
  chmod +x "${bin_dir}/oras"
}

make_platform_contract_artifact() {
  local dst="$1"
  local marker="$2"

  mkdir -p \
    "${dst}/payload/platform-contract/landing" \
    "${dst}/payload/platform-contract/rendered/defaults/demo-apps/verification" \
    "${dst}/dist"
  touch "${dst}/payload/platform-contract/rendered/defaults/demo-apps/selected-app-surface.json"
  cat > "${dst}/payload/platform-contract/landing/index.html" <<EOF_HTML
<!doctype html>
<html><body>${marker}</body></html>
EOF_HTML
  cat > "${dst}/payload/platform-contract/rendered/defaults/demo-apps/verification/http-routes.tsv" <<EOF_TSV
host	path	expected_status	body_marker	description
ourbox.local	/	200	${marker}	landing-root
EOF_TSV
  tar -C "${dst}/payload" -czf "${dst}/dist/platform-contract.tar.gz" platform-contract
}

make_airgap_artifact() {
  local dst="$1"
  local version="$2"
  local arch="$3"
  local contract_ref="$4"
  local contract_digest="$5"

  mkdir -p "${dst}/payload" "${dst}/dist"
  cat > "${dst}/payload/manifest.env" <<EOF_MANIFEST
OURBOX_AIRGAP_PLATFORM_SOURCE=https://github.com/example/repo
OURBOX_AIRGAP_PLATFORM_REVISION=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
OURBOX_AIRGAP_PLATFORM_VERSION=${version}
OURBOX_AIRGAP_PLATFORM_CREATED=2026-03-11T20:32:31Z
OURBOX_PLATFORM_CONTRACT_REF=${contract_ref}
OURBOX_PLATFORM_CONTRACT_DIGEST=${contract_digest}
AIRGAP_PLATFORM_ARCH=${arch}
K3S_VERSION=v1.35.0+k3s1
OURBOX_PLATFORM_PROFILE=demo-apps
OURBOX_PLATFORM_IMAGES_LOCK_PATH=platform/images.lock.json
OURBOX_PLATFORM_IMAGES_LOCK_SHA256=f6d6171f7065059b7d7008961d0fecc5b7d65075dd7c7c3514ee5d8418f48118
EOF_MANIFEST
  tar -C "${dst}/payload" -czf "${dst}/dist/airgap-platform.tar.gz" manifest.env
}

make_snapshot() {
  local dst="$1"
  cat > "${dst}" <<'EOF_JSON'
{
  "schema": 1,
  "source_repo": "https://github.com/example/repo",
  "approved_release_tag": "v9.9.9",
  "platform_contract": {
    "versioned_ref": "ghcr.io/example/platform-contract:v9.9.9",
    "pinned_ref": "ghcr.io/example/platform-contract@sha256:1111111111111111111111111111111111111111111111111111111111111111",
    "digest": "sha256:1111111111111111111111111111111111111111111111111111111111111111",
    "required_route_marker": "marker-ok"
  },
  "airgap_platform": {
    "arm64": {
      "versioned_ref": "ghcr.io/example/airgap-platform:v9.9.9-arm64",
      "pinned_ref": "ghcr.io/example/airgap-platform@sha256:2222222222222222222222222222222222222222222222222222222222222222",
      "digest": "sha256:2222222222222222222222222222222222222222222222222222222222222222"
    },
    "amd64": {
      "versioned_ref": "ghcr.io/example/airgap-platform:v9.9.9-amd64",
      "pinned_ref": "ghcr.io/example/airgap-platform@sha256:3333333333333333333333333333333333333333333333333333333333333333",
      "digest": "sha256:3333333333333333333333333333333333333333333333333333333333333333"
    }
  }
}
EOF_JSON
}

test_validate_accepts_cross_bound_snapshot() {
  local tmp fake_bin snapshot
  tmp="$(mktemp -d)"
  fake_bin="${tmp}/bin"
  snapshot="${tmp}/approved.json"

  make_fake_node "${fake_bin}"
  make_fake_oras "${fake_bin}"
  make_snapshot "${snapshot}"
  make_platform_contract_artifact "${tmp}/platform" "marker-ok"
  make_airgap_artifact \
    "${tmp}/airgap-arm64" \
    "v9.9.9" \
    "arm64" \
    "ghcr.io/example/platform-contract@sha256:1111111111111111111111111111111111111111111111111111111111111111" \
    "sha256:1111111111111111111111111111111111111111111111111111111111111111"
  make_airgap_artifact \
    "${tmp}/airgap-amd64" \
    "v9.9.9" \
    "amd64" \
    "ghcr.io/example/platform-contract@sha256:1111111111111111111111111111111111111111111111111111111111111111" \
    "sha256:1111111111111111111111111111111111111111111111111111111111111111"

  FAKE_PLATFORM_DIR="${tmp}/platform" \
    FAKE_AIRGAP_ARM64_DIR="${tmp}/airgap-arm64" \
    FAKE_AIRGAP_AMD64_DIR="${tmp}/airgap-amd64" \
    PATH="${fake_bin}:${PATH}" \
    python3 "${VALIDATE}" --approved-inputs "${snapshot}" >/dev/null

  rm -rf "${tmp}"
}

test_validate_rejects_airgap_manifest_contract_mismatch() {
  local tmp fake_bin snapshot
  tmp="$(mktemp -d)"
  fake_bin="${tmp}/bin"
  snapshot="${tmp}/approved.json"

  make_fake_node "${fake_bin}"
  make_fake_oras "${fake_bin}"
  make_snapshot "${snapshot}"
  make_platform_contract_artifact "${tmp}/platform" "marker-ok"
  make_airgap_artifact \
    "${tmp}/airgap-arm64" \
    "v9.9.9" \
    "arm64" \
    "ghcr.io/example/platform-contract@sha256:9999999999999999999999999999999999999999999999999999999999999999" \
    "sha256:9999999999999999999999999999999999999999999999999999999999999999"
  make_airgap_artifact \
    "${tmp}/airgap-amd64" \
    "v9.9.9" \
    "amd64" \
    "ghcr.io/example/platform-contract@sha256:1111111111111111111111111111111111111111111111111111111111111111" \
    "sha256:1111111111111111111111111111111111111111111111111111111111111111"

  assert_fails \
    "set -euo pipefail; FAKE_PLATFORM_DIR='${tmp}/platform' FAKE_AIRGAP_ARM64_DIR='${tmp}/airgap-arm64' FAKE_AIRGAP_AMD64_DIR='${tmp}/airgap-amd64' PATH='${fake_bin}:${PATH}' python3 '${VALIDATE}' --approved-inputs '${snapshot}'" \
    "validator should reject approved snapshots whose airgap manifests are bound to a different platform-contract digest"

  rm -rf "${tmp}"
}

main() {
  test_validate_accepts_cross_bound_snapshot
  test_validate_rejects_airgap_manifest_contract_mismatch
  printf 'approved-upstream-inputs validator tests: PASS\n'
}

main "$@"
