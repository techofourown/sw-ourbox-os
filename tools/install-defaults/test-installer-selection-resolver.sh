#!/usr/bin/env bash
# shellcheck disable=SC2034  # test fixtures intentionally set env consumed by a sourced resolver
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RESOLVER="${ROOT}/tools/install-defaults/installer-selection-resolver.sh"

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
    printf '  expected to contain: %s\n' "${needle}" >&2
    printf '  actual: %s\n' "${haystack}" >&2
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
    case "${ref}" in
      *install-defaults*)
        cp -a "${FAKE_ORAS_INSTALL_DEFAULTS_DIR}/." "${out}/"
        ;;
      *catalog*)
        cp -a "${FAKE_ORAS_CATALOG_DIR}/." "${out}/"
        ;;
      *)
        exit 3
        ;;
    esac
    ;;
  resolve)
    ref="${1:-}"
    case "${ref}" in
      "${FAKE_ORAS_RESOLVE_REF:-__none__}")
        printf '%s\n' "${FAKE_ORAS_RESOLVE_DIGEST:-}"
        ;;
      *)
        exit 1
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

test_remote_defaults_bundle_shape() {
  local tmp pull_dir extract_dir fake_oras_dir defaults_src override_env digest64
  tmp="$(mktemp -d)"
  pull_dir="${tmp}/pull"
  extract_dir="${tmp}/extract"
  fake_oras_dir="${tmp}/bin"
  defaults_src="${tmp}/defaults-src"
  override_env="${tmp}/override.env"
  digest64="1111111111111111111111111111111111111111111111111111111111111111"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"

  mkdir -p "${defaults_src}/install-defaults/defaults" "${defaults_src}/dist"
  cat > "${defaults_src}/install-defaults/schema.env" <<'EOF_SCHEMA'
INSTALL_DEFAULTS_SCHEMA=1
EOF_SCHEMA
  cat > "${defaults_src}/install-defaults/manifest.env" <<'EOF_MANIFEST'
OURBOX_INSTALL_DEFAULTS_KIND=install-defaults
EOF_MANIFEST
  cat > "${defaults_src}/install-defaults/defaults/woodbox.env" <<'EOF_PROFILE'
INSTALLER_ID=woodbox
OS_REPO=ghcr.io/example/custom-woodbox-os
OS_CATALOG_TAG=custom-catalog
OS_DEFAULT_REF=
CHANNEL_STABLE_TAG=custom-stable
CHANNEL_BETA_TAG=custom-beta
CHANNEL_NIGHTLY_TAG=custom-nightly
CHANNEL_EXP_LABS_TAG=custom-exp-labs
AIRGAP_PLATFORM_REPO=ghcr.io/example/custom-airgap-platform
AIRGAP_PLATFORM_ARCH=amd64
AIRGAP_PLATFORM_CHANNEL=stable
AIRGAP_PLATFORM_CATALOG_ENABLED=1
AIRGAP_PLATFORM_CATALOG_TAG=catalog-amd64
EOF_PROFILE
  tar -C "${defaults_src}" -czf "${defaults_src}/dist/install-defaults.tar.gz" install-defaults
  export FAKE_ORAS_INSTALL_DEFAULTS_DIR="${defaults_src}"

  cat > "${override_env}" <<'EOF_OVERRIDE'
OS_CHANNEL=nightly
EOF_OVERRIDE

  # shellcheck disable=SC1090
  source "${RESOLVER}"
  normalize_payload_config() { :; }

  INSTALLER_ID="woodbox"
  INSTALL_DEFAULTS_REF="ghcr.io/example/install-defaults:edge"
  OS_DEFAULT_REF="ghcr.io/example/woodbox-os@sha256:${digest64}"
  OS_REPO="ghcr.io/techofourown/ourbox-woodbox-os"
  OS_TARGET="x86"
  OS_CHANNEL="stable"
  CHANNEL_STABLE_TAG="x86-stable"
  CHANNEL_BETA_TAG="x86-beta"
  CHANNEL_NIGHTLY_TAG="x86-nightly"
  CHANNEL_EXP_LABS_TAG="x86-exp-labs"

  ourbox_selection_reset_state
  ourbox_selection_load_remote_install_defaults "${pull_dir}" "${extract_dir}" "${override_env}"

  assert_eq "${OURBOX_INSTALL_DEFAULTS_SOURCE}" "remote" "remote defaults should apply"
  assert_eq "${OS_REPO}" "ghcr.io/example/custom-woodbox-os" "remote defaults should override repo"
  assert_eq "${OS_CATALOG_TAG}" "custom-catalog" "remote defaults should override catalog tag"
  assert_eq "${OS_DEFAULT_REF}" "ghcr.io/example/woodbox-os@sha256:${digest64}" "baked pinned default should survive empty remote OS_DEFAULT_REF"
  assert_eq "${AIRGAP_PLATFORM_REPO}" "ghcr.io/example/custom-airgap-platform" "remote defaults should override airgap-platform repo"
  assert_eq "${OS_CHANNEL}" "nightly" "override env should win after remote defaults"

  rm -rf "${tmp}"
}

test_precedence_prefers_os_ref_then_os_default_ref() {
  local tmp fake_oras_dir
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"

  # shellcheck disable=SC1090
  source "${RESOLVER}"

  OS_REPO="ghcr.io/techofourown/ourbox-matchbox-os"
  OS_TARGET="rpi"
  OS_CHANNEL="stable"
  OS_CATALOG_ENABLED="1"
  OS_CATALOG_TAG="rpi-catalog"
  CHANNEL_STABLE_TAG="rpi-stable"
  CHANNEL_BETA_TAG="rpi-beta"
  CHANNEL_NIGHTLY_TAG="rpi-nightly"
  CHANNEL_EXP_LABS_TAG="rpi-exp-labs"

  OS_REF="ghcr.io/example/custom-os:demo"
  OS_DEFAULT_REF="ghcr.io/example/custom-os@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  ourbox_selection_reset_state
  ourbox_selection_determine_default_ref "${tmp}/catalog"
  assert_eq "${OURBOX_INSTALL_SELECTION_SOURCE}" "os-ref" "OS_REF should have highest precedence"
  assert_eq "${OURBOX_SELECTED_REF}" "ghcr.io/example/custom-os:demo" "OS_REF should be selected"

  OS_REF=""
  ourbox_selection_reset_state
  ourbox_selection_determine_default_ref "${tmp}/catalog"
  assert_eq "${OURBOX_INSTALL_SELECTION_SOURCE}" "os-default-ref" "OS_DEFAULT_REF should outrank catalog"
  assert_eq "${OURBOX_SELECTED_REF}" "ghcr.io/example/custom-os@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" "OS_DEFAULT_REF should be selected"

  rm -rf "${tmp}"
}

test_catalog_resolution_uses_newest_valid_created_timestamp() {
  local tmp fake_oras_dir catalog_src expected
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"
  catalog_src="${tmp}/catalog-src"
  expected="ghcr.io/techofourown/ourbox-woodbox-os@sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"

  mkdir -p "${catalog_src}"
  cat > "${catalog_src}/catalog.tsv" <<'EOF_CATALOG'
channel	tag	created	version	variant	target	sku	git_sha	platform_contract_digest	k3s_version	payload_sha256	artifact_digest	pinned_ref	notes
stable	v0.5.0-x86	2026-03-07T07:34:04Z	v0.5.0	prod	x86	TOO	abc	sha256:1	v1	sha256:a	sha256:a	ghcr.io/techofourown/ourbox-woodbox-os@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa	old-good
stable	v0.5.9-x86	2026-03-07T23:59:59Z	v0.5.9	prod	x86	TOO	def	sha256:2	v1	sha256:b	sha256:b	ghcr.io/techofourown/ourbox-woodbox-os:stable	not-digest-pinned
nightly	nightly-x86	2026-03-08T00:00:01Z	nightly	prod	x86	TOO	ghi	sha256:3	v1	sha256:c	sha256:c	ghcr.io/techofourown/ourbox-woodbox-os@sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc	nightly-row
stable	v0.5.3-x86	2026-03-07T23:08:54Z	v0.5.3	prod	x86	TOO	jkl	sha256:4	v1	sha256:d	sha256:d	ghcr.io/techofourown/ourbox-woodbox-os@sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb	newest-valid
EOF_CATALOG
  export FAKE_ORAS_CATALOG_DIR="${catalog_src}"

  # shellcheck disable=SC1090
  source "${RESOLVER}"
  OS_REPO="ghcr.io/techofourown/ourbox-woodbox-os"
  OS_TARGET="x86"
  OS_CHANNEL="stable"
  OS_CATALOG_ENABLED="1"
  OS_CATALOG_TAG="x86-catalog"
  OS_REF=""
  OS_DEFAULT_REF=""
  CHANNEL_STABLE_TAG="x86-stable"
  CHANNEL_BETA_TAG="x86-beta"
  CHANNEL_NIGHTLY_TAG="x86-nightly"
  CHANNEL_EXP_LABS_TAG="x86-exp-labs"

  ourbox_selection_reset_state
  ourbox_selection_determine_default_ref "${tmp}/catalog"

  assert_eq "${OURBOX_INSTALL_SELECTION_SOURCE}" "catalog" "valid catalog row should be selected"
  assert_eq "${OURBOX_RELEASE_CHANNEL}" "stable" "catalog resolution should preserve release channel"
  assert_eq "${OURBOX_SELECTED_REF}" "${expected}" "catalog resolution should choose newest valid digest-pinned row by created"

  rm -rf "${tmp}"
}

test_catalog_resolution_accepts_legacy_target_qualified_channel_rows() {
  local tmp fake_oras_dir catalog_src expected
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"
  catalog_src="${tmp}/catalog-src"
  expected="ghcr.io/techofourown/ourbox-matchbox-os@sha256:9999999999999999999999999999999999999999999999999999999999999999"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"

  mkdir -p "${catalog_src}"
  cat > "${catalog_src}/catalog.tsv" <<'EOF_CATALOG'
channel	tag	created	version	variant	target	sku	git_sha	platform_contract_digest	k3s_version	payload_sha256	artifact_digest	pinned_ref	notes
rpi-stable	v0.9.9-rpi	2026-03-09T01:23:45Z	v0.9.9	prod	rpi	TOO	abc	sha256:1	v1	sha256:a	sha256:a	ghcr.io/techofourown/ourbox-matchbox-os@sha256:9999999999999999999999999999999999999999999999999999999999999999	legacy-channel-row
EOF_CATALOG
  export FAKE_ORAS_CATALOG_DIR="${catalog_src}"

  # shellcheck disable=SC1090
  source "${RESOLVER}"
  OS_REPO="ghcr.io/techofourown/ourbox-matchbox-os"
  OS_TARGET="rpi"
  OS_CHANNEL="stable"
  OS_CATALOG_ENABLED="1"
  OS_CATALOG_TAG="rpi-catalog"
  OS_REF=""
  OS_DEFAULT_REF=""
  CHANNEL_STABLE_TAG="rpi-stable"
  CHANNEL_BETA_TAG="rpi-beta"
  CHANNEL_NIGHTLY_TAG="rpi-nightly"
  CHANNEL_EXP_LABS_TAG="rpi-exp-labs"

  ourbox_selection_reset_state
  ourbox_selection_determine_default_ref "${tmp}/catalog"

  assert_eq "${OURBOX_INSTALL_SELECTION_SOURCE}" "catalog" "legacy target-qualified catalog rows should remain selectable during channel-name migration"
  assert_eq "${OURBOX_RELEASE_CHANNEL}" "stable" "legacy catalog channel names should normalize back to the short release channel"
  assert_eq "${OURBOX_SELECTED_REF}" "${expected}" "legacy target-qualified catalog rows should resolve to their pinned ref"

  rm -rf "${tmp}"
}

test_missing_channel_tags_fall_back_to_target_defaults() {
  local tmp
  tmp="$(mktemp -d)"

  # shellcheck disable=SC1090
  source "${RESOLVER}"

  OS_REPO="ghcr.io/techofourown/ourbox-woodbox-os"
  OS_TARGET="x86"
  OS_CHANNEL="stable"
  OS_CATALOG_ENABLED="0"
  OS_REF=""
  OS_DEFAULT_REF=""
  unset CHANNEL_STABLE_TAG CHANNEL_BETA_TAG CHANNEL_NIGHTLY_TAG CHANNEL_EXP_LABS_TAG

  ourbox_selection_reset_state
  ourbox_selection_determine_default_ref "${tmp}/catalog"

  assert_eq "${OURBOX_INSTALL_SELECTION_SOURCE}" "channel-tag" "missing channel vars should fall back to OS_TARGET-derived tag"
  assert_eq "${OURBOX_SELECTED_REF}" "ghcr.io/techofourown/ourbox-woodbox-os:x86-stable" "stable fallback tag should be derived from target"

  rm -rf "${tmp}"
}

test_catalog_falls_back_to_channel_tag_without_valid_digest_row() {
  local tmp fake_oras_dir catalog_src
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"
  catalog_src="${tmp}/catalog-src"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"

  mkdir -p "${catalog_src}"
  cat > "${catalog_src}/catalog.tsv" <<'EOF_CATALOG'
channel	tag	created	version	variant	target	sku	git_sha	platform_contract_digest	k3s_version	img_sha256	artifact_digest	pinned_ref
stable	v0.9.4-rpi	2026-03-08T01:23:18Z	v0.9.4	prod	rpi	TOO	abc	sha256:1	v1	sha256:a	sha256:a	ghcr.io/techofourown/ourbox-matchbox-os:rpi-stable
EOF_CATALOG
  export FAKE_ORAS_CATALOG_DIR="${catalog_src}"

  # shellcheck disable=SC1090
  source "${RESOLVER}"
  OS_REPO="ghcr.io/techofourown/ourbox-matchbox-os"
  OS_TARGET="rpi"
  OS_CHANNEL="stable"
  OS_CATALOG_ENABLED="1"
  OS_CATALOG_TAG="rpi-catalog"
  OS_REF=""
  OS_DEFAULT_REF=""
  CHANNEL_STABLE_TAG="rpi-stable"
  CHANNEL_BETA_TAG="rpi-beta"
  CHANNEL_NIGHTLY_TAG="rpi-nightly"
  CHANNEL_EXP_LABS_TAG="rpi-exp-labs"

  ourbox_selection_reset_state
  ourbox_selection_determine_default_ref "${tmp}/catalog"

  assert_eq "${OURBOX_INSTALL_SELECTION_SOURCE}" "channel-tag" "invalid catalog rows should fall back to channel tag"
  assert_eq "${OURBOX_RELEASE_CHANNEL}" "stable" "channel fallback should preserve release channel"
  assert_eq "${OURBOX_SELECTED_REF}" "ghcr.io/techofourown/ourbox-matchbox-os:rpi-stable" "channel fallback should use the configured stable tag"

  rm -rf "${tmp}"
}

test_matchbox_style_command_substitution_keeps_stdout_clean_on_catalog_fallback() {
  local tmp fake_oras_dir stderr_file captured
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"
  stderr_file="${tmp}/stderr.log"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"
  export FAKE_ORAS_CATALOG_DIR="${tmp}/missing-catalog"

  # shellcheck disable=SC1090
  source "${RESOLVER}"

  OS_REPO="ghcr.io/techofourown/ourbox-matchbox-os"
  OS_TARGET="rpi"
  OS_CHANNEL="stable"
  OS_CATALOG_ENABLED="1"
  OS_CATALOG_TAG="rpi-catalog"
  OS_REF=""
  OS_DEFAULT_REF=""
  CHANNEL_STABLE_TAG="rpi-stable"
  CHANNEL_BETA_TAG="rpi-beta"
  CHANNEL_NIGHTLY_TAG="rpi-nightly"
  CHANNEL_EXP_LABS_TAG="rpi-exp-labs"

  matchbox_style_default_payload_ref() {
    ourbox_selection_determine_default_ref "${tmp}/catalog"
    printf '%s\n' "${OURBOX_SELECTED_REF}"
  }

  captured="$(matchbox_style_default_payload_ref 2>"${stderr_file}")"

  assert_eq "${captured}" "ghcr.io/techofourown/ourbox-matchbox-os:rpi-stable" "catalog fallback should leave stdout machine-readable for Matchbox-style command substitution"
  assert_contains "$(cat "${stderr_file}")" "Catalog unavailable; falling back to channel tag." "catalog fallback log should be routed to stderr"

  rm -rf "${tmp}"
}

test_interactive_accepts_default_ref() {
  local tmp captured digest
  tmp="$(mktemp -d)"
  digest="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

  captured="$(
    printf '\n' | bash -lc "
      set -euo pipefail
      source '${RESOLVER}'
      OS_REPO='ghcr.io/techofourown/ourbox-matchbox-os'
      OS_TARGET='rpi'
      OS_CHANNEL='stable'
      OS_CATALOG_ENABLED='0'
      OS_CATALOG_TAG='rpi-catalog'
      OS_REF=''
      OS_DEFAULT_REF='ghcr.io/techofourown/ourbox-matchbox-os@sha256:${digest}'
      CHANNEL_STABLE_TAG='rpi-stable'
      CHANNEL_BETA_TAG='rpi-beta'
      CHANNEL_NIGHTLY_TAG='rpi-nightly'
      CHANNEL_EXP_LABS_TAG='rpi-exp-labs'
      ourbox_selection_reset_state
      ourbox_selection_interactive_select_ref '${tmp}/catalog' >/dev/null
      printf '%s\t%s\t%s\n' \"\$OURBOX_SELECTED_REF\" \"\$OURBOX_INSTALL_SELECTION_SOURCE\" \"\${OURBOX_RELEASE_CHANNEL:-}\"
    " 2>/dev/null
  )"

  assert_eq "${captured}" $'ghcr.io/techofourown/ourbox-matchbox-os@sha256:'"${digest}"$'\tos-default-ref\t' "interactive Enter should keep the resolved default ref"

  rm -rf "${tmp}"
}

test_interactive_repo_override_clears_pinned_default() {
  local tmp captured digest
  tmp="$(mktemp -d)"
  digest="bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

  captured="$(
    printf 'o\nlocalhost:5000/custom/ourbox-matchbox-os\ncustom-catalog\n\n' | bash -lc "
      set -euo pipefail
      source '${RESOLVER}'
      OS_REPO='ghcr.io/techofourown/ourbox-matchbox-os'
      OS_TARGET='rpi'
      OS_CHANNEL='stable'
      OS_CATALOG_ENABLED='0'
      OS_CATALOG_TAG='rpi-catalog'
      OS_REF=''
      OS_DEFAULT_REF='ghcr.io/techofourown/ourbox-matchbox-os@sha256:${digest}'
      CHANNEL_STABLE_TAG='rpi-stable'
      CHANNEL_BETA_TAG='rpi-beta'
      CHANNEL_NIGHTLY_TAG='rpi-nightly'
      CHANNEL_EXP_LABS_TAG='rpi-exp-labs'
      ourbox_selection_reset_state
      ourbox_selection_interactive_select_ref '${tmp}/catalog' >/dev/null
      printf '%s\t%s\t%s\t%s\t%s\n' \"\$OURBOX_SELECTED_REF\" \"\$OURBOX_INSTALL_SELECTION_SOURCE\" \"\${OURBOX_RELEASE_CHANNEL:-}\" \"\$OS_REPO\" \"\$OS_CATALOG_TAG\"
    " 2>/dev/null
  )"

  assert_eq "${captured}" $'localhost:5000/custom/ourbox-matchbox-os:rpi-stable\tchannel-tag\tstable\tlocalhost:5000/custom/ourbox-matchbox-os\tcustom-catalog' "repo override should clear pinned defaults and rederive the default from the overridden repo"

  rm -rf "${tmp}"
}

test_interactive_channel_pick_prefers_catalog_row_over_baked_default() {
  local tmp fake_oras_dir catalog_src captured default_digest beta_digest
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"
  catalog_src="${tmp}/catalog-src"
  default_digest="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  beta_digest="2222222222222222222222222222222222222222222222222222222222222222"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"

  mkdir -p "${catalog_src}"
  cat > "${catalog_src}/catalog.tsv" <<'EOF_CATALOG'
channel	tag	created	version	variant	target	sku	git_sha	platform_contract_digest	k3s_version	payload_sha256	artifact_digest	pinned_ref	notes
stable	v0.9.0-rpi	2026-03-08T01:00:00Z	v0.9.0	prod	rpi	TOO	abc	sha256:1	v1	sha256:a	sha256:a	ghcr.io/techofourown/ourbox-matchbox-os@sha256:1111111111111111111111111111111111111111111111111111111111111111	stable-row
beta	v0.9.1-rpi	2026-03-08T02:00:00Z	v0.9.1	prod	rpi	TOO	def	sha256:2	v1	sha256:b	sha256:b	ghcr.io/techofourown/ourbox-matchbox-os@sha256:2222222222222222222222222222222222222222222222222222222222222222	beta-row
EOF_CATALOG
  export FAKE_ORAS_CATALOG_DIR="${catalog_src}"

  captured="$(
    printf 'c\n2\n' | bash -lc "
      set -euo pipefail
      PATH='${fake_oras_dir}':\"\$PATH\"
      export FAKE_ORAS_CATALOG_DIR='${catalog_src}'
      source '${RESOLVER}'
      OS_REPO='ghcr.io/techofourown/ourbox-matchbox-os'
      OS_TARGET='rpi'
      OS_CHANNEL='stable'
      OS_CATALOG_ENABLED='1'
      OS_CATALOG_TAG='rpi-catalog'
      OS_REF=''
      OS_DEFAULT_REF='ghcr.io/techofourown/ourbox-matchbox-os@sha256:${default_digest}'
      CHANNEL_STABLE_TAG='rpi-stable'
      CHANNEL_BETA_TAG='rpi-beta'
      CHANNEL_NIGHTLY_TAG='rpi-nightly'
      CHANNEL_EXP_LABS_TAG='rpi-exp-labs'
      ourbox_selection_reset_state
      ourbox_selection_interactive_select_ref '${tmp}/catalog' >/dev/null
      printf '%s\t%s\t%s\n' \"\$OURBOX_SELECTED_REF\" \"\$OURBOX_INSTALL_SELECTION_SOURCE\" \"\${OURBOX_RELEASE_CHANNEL:-}\"
    " 2>/dev/null
  )"

  assert_eq "${captured}" $'ghcr.io/techofourown/ourbox-matchbox-os@sha256:'"${beta_digest}"$'\tcatalog\tbeta' "interactive channel choice should bypass baked defaults and prefer the selected lane's catalog row"

  rm -rf "${tmp}"
}

test_interactive_catalog_pick_returns_pinned_ref() {
  local tmp fake_oras_dir catalog_src captured
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"
  catalog_src="${tmp}/catalog-src"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"

  mkdir -p "${catalog_src}"
  cat > "${catalog_src}/catalog.tsv" <<'EOF_CATALOG'
channel	tag	created	version	variant	target	sku	git_sha	platform_contract_digest	k3s_version	payload_sha256	artifact_digest	pinned_ref	notes
stable	v0.9.0-rpi	2026-03-08T01:00:00Z	v0.9.0	prod	rpi	TOO	abc	sha256:1	v1	sha256:a	sha256:a	ghcr.io/techofourown/ourbox-matchbox-os@sha256:1111111111111111111111111111111111111111111111111111111111111111	stable-row
beta	v0.9.1-rpi	2026-03-08T02:00:00Z	v0.9.1	prod	rpi	TOO	def	sha256:2	v1	sha256:b	sha256:b	ghcr.io/techofourown/ourbox-matchbox-os@sha256:2222222222222222222222222222222222222222222222222222222222222222	beta-row
EOF_CATALOG
  export FAKE_ORAS_CATALOG_DIR="${catalog_src}"

  captured="$(
    printf 'l\n2\n' | bash -lc "
      set -euo pipefail
      PATH='${fake_oras_dir}':\"\$PATH\"
      export FAKE_ORAS_CATALOG_DIR='${catalog_src}'
      source '${RESOLVER}'
      OS_REPO='ghcr.io/techofourown/ourbox-matchbox-os'
      OS_TARGET='rpi'
      OS_CHANNEL='stable'
      OS_CATALOG_ENABLED='1'
      OS_CATALOG_TAG='rpi-catalog'
      OS_REF=''
      OS_DEFAULT_REF=''
      CHANNEL_STABLE_TAG='rpi-stable'
      CHANNEL_BETA_TAG='rpi-beta'
      CHANNEL_NIGHTLY_TAG='rpi-nightly'
      CHANNEL_EXP_LABS_TAG='rpi-exp-labs'
      ourbox_selection_reset_state
      ourbox_selection_interactive_select_ref '${tmp}/catalog' >/dev/null
      printf '%s\t%s\t%s\n' \"\$OURBOX_SELECTED_REF\" \"\$OURBOX_INSTALL_SELECTION_SOURCE\" \"\${OURBOX_RELEASE_CHANNEL:-}\"
    " 2>/dev/null
  )"

  assert_eq "${captured}" $'ghcr.io/techofourown/ourbox-matchbox-os@sha256:1111111111111111111111111111111111111111111111111111111111111111\tcatalog\tstable' "interactive catalog browsing should return the selected digest-pinned ref"

  rm -rf "${tmp}"
}

test_interactive_catalog_pick_normalizes_legacy_channel_name() {
  local tmp fake_oras_dir catalog_src captured
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"
  catalog_src="${tmp}/catalog-src"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"

  mkdir -p "${catalog_src}"
  cat > "${catalog_src}/catalog.tsv" <<'EOF_CATALOG'
channel	tag	created	version	variant	target	sku	git_sha	platform_contract_digest	k3s_version	payload_sha256	artifact_digest	pinned_ref	notes
rpi-stable	v0.9.0-rpi	2026-03-08T01:00:00Z	v0.9.0	prod	rpi	TOO	abc	sha256:1	v1	sha256:a	sha256:a	ghcr.io/techofourown/ourbox-matchbox-os@sha256:1111111111111111111111111111111111111111111111111111111111111111	legacy-stable-row
EOF_CATALOG
  export FAKE_ORAS_CATALOG_DIR="${catalog_src}"

  captured="$(
    printf 'l\n1\n' | bash -lc "
      set -euo pipefail
      PATH='${fake_oras_dir}':\"\$PATH\"
      export FAKE_ORAS_CATALOG_DIR='${catalog_src}'
      source '${RESOLVER}'
      OS_REPO='ghcr.io/techofourown/ourbox-matchbox-os'
      OS_TARGET='rpi'
      OS_CHANNEL='stable'
      OS_CATALOG_ENABLED='1'
      OS_CATALOG_TAG='rpi-catalog'
      OS_REF=''
      OS_DEFAULT_REF=''
      CHANNEL_STABLE_TAG='rpi-stable'
      CHANNEL_BETA_TAG='rpi-beta'
      CHANNEL_NIGHTLY_TAG='rpi-nightly'
      CHANNEL_EXP_LABS_TAG='rpi-exp-labs'
      ourbox_selection_reset_state
      ourbox_selection_interactive_select_ref '${tmp}/catalog' >/dev/null
      printf '%s\t%s\t%s\n' \"\$OURBOX_SELECTED_REF\" \"\$OURBOX_INSTALL_SELECTION_SOURCE\" \"\${OURBOX_RELEASE_CHANNEL:-}\"
    " 2>/dev/null
  )"

  assert_eq "${captured}" $'ghcr.io/techofourown/ourbox-matchbox-os@sha256:1111111111111111111111111111111111111111111111111111111111111111\tcatalog\tstable' "interactive catalog browsing should normalize legacy target-qualified channel names back to the short release-channel provenance"

  rm -rf "${tmp}"
}

test_finalize_registry_ref_resolves_digest() {
  local tmp fake_oras_dir
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"
  export FAKE_ORAS_RESOLVE_REF="ghcr.io/techofourown/ourbox-matchbox-os:rpi-stable"
  export FAKE_ORAS_RESOLVE_DIGEST="sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"

  # shellcheck disable=SC1090
  source "${RESOLVER}"

  ourbox_selection_reset_state
  ourbox_selection_finalize_registry_ref "ghcr.io/techofourown/ourbox-matchbox-os:rpi-stable"

  assert_eq "${OURBOX_OS_ARTIFACT_REF}" "ghcr.io/techofourown/ourbox-matchbox-os:rpi-stable" "artifact ref should preserve the operator-facing ref"
  assert_eq "${OURBOX_OS_ARTIFACT_DIGEST}" "sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd" "artifact digest should come from oras resolve"
  assert_eq "${OURBOX_PULL_REF}" "ghcr.io/techofourown/ourbox-matchbox-os@sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd" "pull ref should be immutable"

  rm -rf "${tmp}"
}

test_finalize_registry_ref_handles_registry_ports_without_tags() {
  local tmp fake_oras_dir digest
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"
  digest="sha256:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"
  export FAKE_ORAS_RESOLVE_REF="localhost:5000/custom/ourbox-matchbox-os"
  export FAKE_ORAS_RESOLVE_DIGEST="${digest}"

  # shellcheck disable=SC1090
  source "${RESOLVER}"

  ourbox_selection_reset_state
  ourbox_selection_finalize_registry_ref "localhost:5000/custom/ourbox-matchbox-os"

  assert_eq "${OURBOX_OS_ARTIFACT_DIGEST}" "${digest}" "resolved digest should be recorded"
  assert_eq "${OURBOX_PULL_REF}" "localhost:5000/custom/ourbox-matchbox-os@${digest}" "registry port should be preserved when building digest pull ref"

  rm -rf "${tmp}"
}

test_finalize_registry_ref_dev_override_marks_unresolved() {
  local tmp fake_oras_dir
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"
  export FAKE_ORAS_RESOLVE_REF="ghcr.io/techofourown/ourbox-woodbox-os:x86-stable"
  export FAKE_ORAS_RESOLVE_DIGEST=""
  export OURBOX_ALLOW_UNRESOLVED_PULL="1"

  # shellcheck disable=SC1090
  source "${RESOLVER}"

  ourbox_selection_reset_state
  ourbox_selection_finalize_registry_ref "ghcr.io/techofourown/ourbox-woodbox-os:x86-stable"

  assert_eq "${OURBOX_OS_ARTIFACT_DIGEST}" "unresolved" "dev override should mark unresolved digest explicitly"
  assert_eq "${OURBOX_PULL_REF}" "ghcr.io/techofourown/ourbox-woodbox-os:x86-stable" "dev override should pull the original floating ref"

  unset OURBOX_ALLOW_UNRESOLVED_PULL
  rm -rf "${tmp}"
}

test_finalize_registry_ref_fails_closed_without_dev_override() {
  local tmp fake_oras_dir
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"
  export FAKE_ORAS_RESOLVE_REF="ghcr.io/techofourown/ourbox-woodbox-os:x86-stable"
  export FAKE_ORAS_RESOLVE_DIGEST=""

  if bash -lc "set -euo pipefail; PATH='${fake_oras_dir}:${PATH}'; source '${RESOLVER}'; ourbox_selection_reset_state; ourbox_selection_finalize_registry_ref 'ghcr.io/techofourown/ourbox-woodbox-os:x86-stable'" >/dev/null 2>&1; then
    printf 'ASSERTION FAILED: unresolved floating ref should fail closed by default\n' >&2
    exit 1
  fi

  rm -rf "${tmp}"
}

test_airgap_platform_default_precedence_prefers_exact_ref_then_catalog() {
  local tmp fake_oras_dir catalog_src contract_digest ref_digest catalog_digest
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"
  catalog_src="${tmp}/catalog-src"
  contract_digest="sha256:1111111111111111111111111111111111111111111111111111111111111111"
  ref_digest="2222222222222222222222222222222222222222222222222222222222222222"
  catalog_digest="3333333333333333333333333333333333333333333333333333333333333333"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"

  mkdir -p "${catalog_src}"
  cat > "${catalog_src}/catalog.tsv" <<EOF_CATALOG
channel	tag	created	version	revision	arch	platform_contract_digest	platform_profile	k3s_version	platform_images_lock_sha256	artifact_digest	pinned_ref
stable	stable-arm64	2026-03-09T00:00:00Z	v0.15.0	aaaa1111	arm64	${contract_digest}	demo-apps	v1.35.0+k3s1	aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa	sha256:${catalog_digest}	ghcr.io/techofourown/sw-ourbox-os/airgap-platform@sha256:${catalog_digest}
EOF_CATALOG
  export FAKE_ORAS_CATALOG_DIR="${catalog_src}"

  # shellcheck disable=SC1090
  source "${RESOLVER}"

  AIRGAP_PLATFORM_REPO="ghcr.io/techofourown/sw-ourbox-os/airgap-platform"
  AIRGAP_PLATFORM_ARCH="arm64"
  AIRGAP_PLATFORM_CHANNEL="stable"
  AIRGAP_PLATFORM_CATALOG_ENABLED="1"
  AIRGAP_PLATFORM_CATALOG_TAG="catalog-arm64"

  AIRGAP_PLATFORM_REF="ghcr.io/techofourown/sw-ourbox-os/airgap-platform@sha256:${ref_digest}"
  ourbox_airgap_platform_selection_reset_state
  ourbox_airgap_platform_determine_default_ref "${tmp}/catalog" "${contract_digest}"
  assert_eq "${OURBOX_AIRGAP_PLATFORM_INSTALL_SELECTION_SOURCE}" "airgap-platform-ref" "AIRGAP_PLATFORM_REF should have highest precedence"
  assert_eq "${OURBOX_AIRGAP_PLATFORM_SELECTED_REF}" "ghcr.io/techofourown/sw-ourbox-os/airgap-platform@sha256:${ref_digest}" "AIRGAP_PLATFORM_REF should be selected directly"

  AIRGAP_PLATFORM_REF=""
  ourbox_airgap_platform_selection_reset_state
  ourbox_airgap_platform_determine_default_ref "${tmp}/catalog" "${contract_digest}"
  assert_eq "${OURBOX_AIRGAP_PLATFORM_INSTALL_SELECTION_SOURCE}" "catalog" "catalog resolution should supply the default when no exact airgap ref is set"
  assert_eq "${OURBOX_AIRGAP_PLATFORM_SELECTED_REF}" "ghcr.io/techofourown/sw-ourbox-os/airgap-platform@sha256:${catalog_digest}" "catalog resolution should choose the matching digest-pinned row"

  rm -rf "${tmp}"
}

test_airgap_platform_catalog_resolution_uses_newest_matching_created_timestamp() {
  local tmp fake_oras_dir catalog_src contract_a contract_b expected
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"
  catalog_src="${tmp}/catalog-src"
  contract_a="sha256:4444444444444444444444444444444444444444444444444444444444444444"
  contract_b="sha256:5555555555555555555555555555555555555555555555555555555555555555"
  expected="ghcr.io/techofourown/sw-ourbox-os/airgap-platform@sha256:7777777777777777777777777777777777777777777777777777777777777777"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"

  mkdir -p "${catalog_src}"
  cat > "${catalog_src}/catalog.tsv" <<EOF_CATALOG
channel	tag	created	version	revision	arch	platform_contract_digest	platform_profile	k3s_version	platform_images_lock_sha256	artifact_digest	pinned_ref
stable	stable-arm64	2026-03-08T00:00:00Z	v0.14.0	aaaa1111	arm64	${contract_a}	demo-apps	v1.35.0+k3s1	aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa	sha256:6666666666666666666666666666666666666666666666666666666666666666	ghcr.io/techofourown/sw-ourbox-os/airgap-platform@sha256:6666666666666666666666666666666666666666666666666666666666666666
stable	stable-arm64	2026-03-09T00:00:00Z	v0.15.0	bbbb2222	arm64	${contract_a}	demo-apps	v1.35.0+k3s1	bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb	sha256:7777777777777777777777777777777777777777777777777777777777777777	${expected}
stable	stable-arm64	2026-03-10T00:00:00Z	v0.16.0	cccc3333	amd64	${contract_a}	demo-apps	v1.35.0+k3s1	cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc	sha256:8888888888888888888888888888888888888888888888888888888888888888	ghcr.io/techofourown/sw-ourbox-os/airgap-platform@sha256:8888888888888888888888888888888888888888888888888888888888888888
stable	stable-arm64	2026-03-11T00:00:00Z	v0.17.0	dddd4444	arm64	${contract_b}	demo-apps	v1.35.0+k3s1	dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd	sha256:9999999999999999999999999999999999999999999999999999999999999999	ghcr.io/techofourown/sw-ourbox-os/airgap-platform@sha256:9999999999999999999999999999999999999999999999999999999999999999
EOF_CATALOG
  export FAKE_ORAS_CATALOG_DIR="${catalog_src}"

  # shellcheck disable=SC1090
  source "${RESOLVER}"

  AIRGAP_PLATFORM_REPO="ghcr.io/techofourown/sw-ourbox-os/airgap-platform"
  AIRGAP_PLATFORM_ARCH="arm64"
  AIRGAP_PLATFORM_CHANNEL="stable"
  AIRGAP_PLATFORM_REF=""
  AIRGAP_PLATFORM_CATALOG_ENABLED="1"
  AIRGAP_PLATFORM_CATALOG_TAG="catalog-arm64"

  ourbox_airgap_platform_selection_reset_state
  ourbox_airgap_platform_determine_default_ref "${tmp}/catalog" "${contract_a}"

  assert_eq "${OURBOX_AIRGAP_PLATFORM_INSTALL_SELECTION_SOURCE}" "catalog" "airgap resolver should prefer catalog rows when a matching digest-pinned row exists"
  assert_eq "${OURBOX_AIRGAP_PLATFORM_RELEASE_CHANNEL}" "stable" "airgap catalog resolution should preserve the selected release channel"
  assert_eq "${OURBOX_AIRGAP_PLATFORM_SELECTED_REF}" "${expected}" "airgap catalog resolution should choose the newest matching row by created timestamp"

  rm -rf "${tmp}"
}

test_airgap_platform_channel_requires_catalog_when_no_exact_ref() {
  local tmp fake_oras_dir contract_digest
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"
  contract_digest="sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"
  export FAKE_ORAS_CATALOG_DIR="${tmp}/missing-catalog"

  # shellcheck disable=SC1090
  source "${RESOLVER}"

  AIRGAP_PLATFORM_REPO="ghcr.io/techofourown/sw-ourbox-os/airgap-platform"
  AIRGAP_PLATFORM_ARCH="amd64"
  AIRGAP_PLATFORM_CHANNEL="beta"
  AIRGAP_PLATFORM_REF=""
  AIRGAP_PLATFORM_CATALOG_ENABLED="1"
  AIRGAP_PLATFORM_CATALOG_TAG="catalog-amd64"

  ourbox_airgap_platform_selection_reset_state
  if ourbox_airgap_platform_determine_default_ref "${tmp}/catalog" "${contract_digest}"; then
    printf 'ASSERTION FAILED: airgap selection should require a matching catalog row when no exact ref is set\n' >&2
    exit 1
  fi

  assert_eq "${OURBOX_AIRGAP_PLATFORM_INSTALL_SELECTION_SOURCE}" "" "airgap selection should not synthesize a fallback source when the catalog is unavailable"
  assert_eq "${OURBOX_AIRGAP_PLATFORM_RELEASE_CHANNEL}" "" "airgap selection should not record a release channel when no catalog-backed default exists"
  assert_eq "${OURBOX_AIRGAP_PLATFORM_SELECTED_REF}" "" "airgap selection should leave the selected ref empty when no catalog-backed default exists"

  rm -rf "${tmp}"
}

test_airgap_platform_catalog_filters_non_matching_contract_digest() {
  local tmp fake_oras_dir catalog_src required_contract other_contract
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"
  catalog_src="${tmp}/catalog-src"
  required_contract="sha256:1212121212121212121212121212121212121212121212121212121212121212"
  other_contract="sha256:3434343434343434343434343434343434343434343434343434343434343434"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"

  mkdir -p "${catalog_src}"
  cat > "${catalog_src}/catalog.tsv" <<EOF_CATALOG
channel	tag	created	version	revision	arch	platform_contract_digest	platform_profile	k3s_version	platform_images_lock_sha256	artifact_digest	pinned_ref
stable	stable-arm64	2026-03-09T00:00:00Z	v0.15.0	aaaa1111	arm64	${other_contract}	demo-apps	v1.35.0+k3s1	aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa	sha256:5656565656565656565656565656565656565656565656565656565656565656	ghcr.io/techofourown/sw-ourbox-os/airgap-platform@sha256:5656565656565656565656565656565656565656565656565656565656565656
EOF_CATALOG
  export FAKE_ORAS_CATALOG_DIR="${catalog_src}"

  # shellcheck disable=SC1090
  source "${RESOLVER}"

  AIRGAP_PLATFORM_REPO="ghcr.io/techofourown/sw-ourbox-os/airgap-platform"
  AIRGAP_PLATFORM_ARCH="arm64"
  AIRGAP_PLATFORM_CHANNEL="stable"
  AIRGAP_PLATFORM_REF=""
  AIRGAP_PLATFORM_CATALOG_ENABLED="1"
  AIRGAP_PLATFORM_CATALOG_TAG="catalog-arm64"

  ourbox_airgap_platform_selection_reset_state
  if ourbox_airgap_platform_determine_default_ref "${tmp}/catalog" "${required_contract}"; then
    printf 'ASSERTION FAILED: airgap selection should reject catalog rows whose platform contract digest does not match the selected OS payload\n' >&2
    exit 1
  fi

  assert_eq "${OURBOX_AIRGAP_PLATFORM_INSTALL_SELECTION_SOURCE}" "" "airgap resolver should reject catalog rows whose platform contract digest does not match the selected OS payload"
  assert_eq "${OURBOX_AIRGAP_PLATFORM_SELECTED_REF}" "" "airgap resolver should leave the selected ref empty when no contract-matching row exists"

  rm -rf "${tmp}"
}

test_airgap_platform_interactive_repo_override_supports_custom_ref_without_catalog_default() {
  local tmp captured contract_digest custom_digest
  tmp="$(mktemp -d)"
  contract_digest="sha256:7878787878787878787878787878787878787878787878787878787878787878"
  custom_digest="9090909090909090909090909090909090909090909090909090909090909090"

  captured="$(
    printf "o\nlocalhost:5000/custom/airgap-platform\ncustom-catalog\nr\nlocalhost:5000/custom/airgap-platform@sha256:${custom_digest}\n" | bash -lc "
      set -euo pipefail
      source '${RESOLVER}'
      AIRGAP_PLATFORM_REPO='ghcr.io/techofourown/sw-ourbox-os/airgap-platform'
      AIRGAP_PLATFORM_ARCH='arm64'
      AIRGAP_PLATFORM_CHANNEL='stable'
      AIRGAP_PLATFORM_REF=''
      AIRGAP_PLATFORM_CATALOG_ENABLED='0'
      AIRGAP_PLATFORM_CATALOG_TAG='catalog-arm64'
      ourbox_airgap_platform_selection_reset_state
      ourbox_airgap_platform_selection_interactive_select_ref '${tmp}/catalog' '${contract_digest}' >/dev/null
      printf '%s\t%s\t%s\t%s\t%s\n' \"\$OURBOX_AIRGAP_PLATFORM_SELECTED_REF\" \"\$OURBOX_AIRGAP_PLATFORM_INSTALL_SELECTION_SOURCE\" \"\${OURBOX_AIRGAP_PLATFORM_RELEASE_CHANNEL:-}\" \"\$AIRGAP_PLATFORM_REPO\" \"\$AIRGAP_PLATFORM_CATALOG_TAG\"
    " 2>/dev/null
  )"

  assert_eq "${captured}" $'localhost:5000/custom/airgap-platform@sha256:'"${custom_digest}"$'\toperator-override\t\tlocalhost:5000/custom/airgap-platform\tcustom-catalog' "airgap repo override should preserve the overridden repo and allow an explicit custom ref when no catalog-backed default exists"

  rm -rf "${tmp}"
}

test_airgap_platform_interactive_channel_pick_prefers_catalog_row() {
  local tmp fake_oras_dir catalog_src captured contract_digest beta_digest
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"
  catalog_src="${tmp}/catalog-src"
  contract_digest="sha256:5656565656565656565656565656565656565656565656565656565656565656"
  beta_digest="bcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbc"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"

  mkdir -p "${catalog_src}"
  cat > "${catalog_src}/catalog.tsv" <<EOF_CATALOG
channel	tag	created	version	revision	arch	platform_contract_digest	platform_profile	k3s_version	platform_images_lock_sha256	artifact_digest	pinned_ref
stable	stable-arm64	2026-03-08T01:00:00Z	v0.9.0	aaaa1111	arm64	${contract_digest}	demo-apps	v1.35.0+k3s1	aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa	sha256:1111111111111111111111111111111111111111111111111111111111111111	ghcr.io/techofourown/sw-ourbox-os/airgap-platform@sha256:1111111111111111111111111111111111111111111111111111111111111111
beta	beta-arm64	2026-03-08T02:00:00Z	v0.9.1	bbbb2222	arm64	${contract_digest}	demo-apps	v1.35.0+k3s1	bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb	sha256:${beta_digest}	ghcr.io/techofourown/sw-ourbox-os/airgap-platform@sha256:${beta_digest}
EOF_CATALOG
  export FAKE_ORAS_CATALOG_DIR="${catalog_src}"

  captured="$(
    printf 'c\n2\n' | bash -lc "
      set -euo pipefail
      PATH='${fake_oras_dir}':\"\$PATH\"
      export FAKE_ORAS_CATALOG_DIR='${catalog_src}'
      source '${RESOLVER}'
      AIRGAP_PLATFORM_REPO='ghcr.io/techofourown/sw-ourbox-os/airgap-platform'
      AIRGAP_PLATFORM_ARCH='arm64'
      AIRGAP_PLATFORM_CHANNEL='stable'
      AIRGAP_PLATFORM_REF=''
      AIRGAP_PLATFORM_CATALOG_ENABLED='1'
      AIRGAP_PLATFORM_CATALOG_TAG='catalog-arm64'
      ourbox_airgap_platform_selection_reset_state
      ourbox_airgap_platform_selection_interactive_select_ref '${tmp}/catalog' '${contract_digest}' >/dev/null
      printf '%s\t%s\t%s\n' \"\$OURBOX_AIRGAP_PLATFORM_SELECTED_REF\" \"\$OURBOX_AIRGAP_PLATFORM_INSTALL_SELECTION_SOURCE\" \"\${OURBOX_AIRGAP_PLATFORM_RELEASE_CHANNEL:-}\"
    " 2>/dev/null
  )"

  assert_eq "${captured}" $'ghcr.io/techofourown/sw-ourbox-os/airgap-platform@sha256:'"${beta_digest}"$'\tcatalog\tbeta' "interactive airgap channel choice should prefer the selected lane's catalog row"

  rm -rf "${tmp}"
}

test_airgap_platform_finalize_registry_ref_resolves_digest() {
  local tmp fake_oras_dir digest
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"
  digest="sha256:abababababababababababababababababababababababababababababababab"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"
  export FAKE_ORAS_RESOLVE_REF="ghcr.io/techofourown/sw-ourbox-os/airgap-platform:stable-arm64"
  export FAKE_ORAS_RESOLVE_DIGEST="${digest}"

  # shellcheck disable=SC1090
  source "${RESOLVER}"

  ourbox_airgap_platform_selection_reset_state
  ourbox_airgap_platform_selection_finalize_registry_ref "ghcr.io/techofourown/sw-ourbox-os/airgap-platform:stable-arm64"

  assert_eq "${OURBOX_AIRGAP_PLATFORM_ARTIFACT_REF}" "ghcr.io/techofourown/sw-ourbox-os/airgap-platform:stable-arm64" "airgap artifact ref should preserve the operator-facing ref"
  assert_eq "${OURBOX_AIRGAP_PLATFORM_ARTIFACT_DIGEST}" "${digest}" "airgap artifact digest should come from oras resolve"
  assert_eq "${OURBOX_AIRGAP_PLATFORM_PULL_REF}" "ghcr.io/techofourown/sw-ourbox-os/airgap-platform@${digest}" "airgap pull ref should be immutable"

  rm -rf "${tmp}"
}

test_airgap_platform_finalize_registry_ref_dev_override_marks_unresolved() {
  local tmp fake_oras_dir
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"
  export FAKE_ORAS_RESOLVE_REF="ghcr.io/techofourown/sw-ourbox-os/airgap-platform:nightly-amd64"
  export FAKE_ORAS_RESOLVE_DIGEST=""
  export OURBOX_ALLOW_UNRESOLVED_PULL="1"

  # shellcheck disable=SC1090
  source "${RESOLVER}"

  ourbox_airgap_platform_selection_reset_state
  ourbox_airgap_platform_selection_finalize_registry_ref "ghcr.io/techofourown/sw-ourbox-os/airgap-platform:nightly-amd64"

  assert_eq "${OURBOX_AIRGAP_PLATFORM_ARTIFACT_DIGEST}" "unresolved" "airgap dev override should mark unresolved digest explicitly"
  assert_eq "${OURBOX_AIRGAP_PLATFORM_PULL_REF}" "ghcr.io/techofourown/sw-ourbox-os/airgap-platform:nightly-amd64" "airgap dev override should pull the original floating ref"

  unset OURBOX_ALLOW_UNRESOLVED_PULL
  rm -rf "${tmp}"
}

test_airgap_platform_validate_extracted_bundle_rejects_invalid_manifest_contract_digest() {
  local tmp bundle_dir required_contract
  tmp="$(mktemp -d)"
  bundle_dir="${tmp}/bundle"
  required_contract="sha256:cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd"

  mkdir -p "${bundle_dir}/k3s" "${bundle_dir}/platform/images"
  touch "${bundle_dir}/k3s/k3s-airgap-images-arm64.tar" "${bundle_dir}/platform/images.lock.json" "${bundle_dir}/platform/profile.env" "${bundle_dir}/platform/images/app.tar"
  cat > "${bundle_dir}/manifest.env" <<'EOF_MANIFEST'
OURBOX_AIRGAP_PLATFORM_SOURCE=https://github.com/techofourown/sw-ourbox-os
OURBOX_AIRGAP_PLATFORM_REVISION=6472fb5919d187daf832082eeaef6086b336a632
OURBOX_AIRGAP_PLATFORM_VERSION=v0.15.1
OURBOX_AIRGAP_PLATFORM_CREATED=2026-03-11T04:59:06Z
OURBOX_PLATFORM_CONTRACT_REF=ghcr.io/techofourown/sw-ourbox-os/platform-contract@sha256:1111111111111111111111111111111111111111111111111111111111111111
OURBOX_PLATFORM_CONTRACT_DIGEST=invalid-digest
AIRGAP_PLATFORM_ARCH=arm64
K3S_VERSION=v1.35.0+k3s1
OURBOX_PLATFORM_PROFILE=demo-apps
OURBOX_PLATFORM_IMAGES_LOCK_PATH=platform/images.lock.json
OURBOX_PLATFORM_IMAGES_LOCK_SHA256=f6d6171f7065059b7d7008961d0fecc5b7d65075dd7c7c3514ee5d8418f48118
EOF_MANIFEST
  printf '#!/bin/sh\nexit 0\n' > "${bundle_dir}/k3s/k3s"
  chmod +x "${bundle_dir}/k3s/k3s"

  assert_fails "set -euo pipefail; source '${RESOLVER}'; ourbox_airgap_platform_selection_validate_extracted_bundle '${bundle_dir}' '${required_contract}' 'arm64'" \
    "airgap manifest validation should reject an invalid platform contract digest"

  rm -rf "${tmp}"
}

test_airgap_platform_validate_extracted_bundle_exports_manifest_metadata() {
  local tmp bundle_dir required_contract
  tmp="$(mktemp -d)"
  bundle_dir="${tmp}/bundle"
  required_contract="sha256:abababababababababababababababababababababababababababababababab"

  mkdir -p "${bundle_dir}/k3s" "${bundle_dir}/platform/images"
  touch "${bundle_dir}/k3s/k3s-airgap-images-arm64.tar" "${bundle_dir}/platform/images.lock.json" "${bundle_dir}/platform/profile.env" "${bundle_dir}/platform/images/app.tar"
  cat > "${bundle_dir}/manifest.env" <<EOF_MANIFEST
OURBOX_AIRGAP_PLATFORM_SOURCE=https://github.com/techofourown/sw-ourbox-os
OURBOX_AIRGAP_PLATFORM_REVISION=6472fb5919d187daf832082eeaef6086b336a632
OURBOX_AIRGAP_PLATFORM_VERSION=v0.15.1
OURBOX_AIRGAP_PLATFORM_CREATED=2026-03-11T04:59:06Z
OURBOX_PLATFORM_CONTRACT_REF=ghcr.io/techofourown/sw-ourbox-os/platform-contract@${required_contract}
OURBOX_PLATFORM_CONTRACT_DIGEST=${required_contract}
AIRGAP_PLATFORM_ARCH=arm64
K3S_VERSION=v1.35.0+k3s1
OURBOX_PLATFORM_PROFILE=demo-apps
OURBOX_PLATFORM_IMAGES_LOCK_PATH=platform/images.lock.json
OURBOX_PLATFORM_IMAGES_LOCK_SHA256=f6d6171f7065059b7d7008961d0fecc5b7d65075dd7c7c3514ee5d8418f48118
EOF_MANIFEST
  printf '#!/bin/sh\nexit 0\n' > "${bundle_dir}/k3s/k3s"
  chmod +x "${bundle_dir}/k3s/k3s"

  # shellcheck disable=SC1090
  source "${RESOLVER}"

  OURBOX_AIRGAP_PLATFORM_SOURCE="stale-source"
  OURBOX_AIRGAP_PLATFORM_REVISION="stale-revision"
  OURBOX_AIRGAP_PLATFORM_VERSION="stale-version"
  OURBOX_AIRGAP_PLATFORM_CREATED="stale-created"
  OURBOX_AIRGAP_PLATFORM_ARCH="stale-arch"
  OURBOX_AIRGAP_PLATFORM_PROFILE="stale-profile"
  OURBOX_AIRGAP_PLATFORM_K3S_VERSION="stale-k3s"
  OURBOX_AIRGAP_PLATFORM_IMAGES_LOCK_SHA256="stale-lock"

  ourbox_airgap_platform_selection_validate_extracted_bundle "${bundle_dir}" "${required_contract}" "arm64"

  assert_eq "${OURBOX_AIRGAP_PLATFORM_SOURCE}" "https://github.com/techofourown/sw-ourbox-os" "validated bundle should export airgap source"
  assert_eq "${OURBOX_AIRGAP_PLATFORM_REVISION}" "6472fb5919d187daf832082eeaef6086b336a632" "validated bundle should export airgap revision"
  assert_eq "${OURBOX_AIRGAP_PLATFORM_VERSION}" "v0.15.1" "validated bundle should export airgap version"
  assert_eq "${OURBOX_AIRGAP_PLATFORM_CREATED}" "2026-03-11T04:59:06Z" "validated bundle should export airgap created timestamp"
  assert_eq "${OURBOX_AIRGAP_PLATFORM_ARCH}" "arm64" "validated bundle should export airgap arch"
  assert_eq "${OURBOX_AIRGAP_PLATFORM_PROFILE}" "demo-apps" "validated bundle should export platform profile"
  assert_eq "${OURBOX_AIRGAP_PLATFORM_K3S_VERSION}" "v1.35.0+k3s1" "validated bundle should export k3s version"
  assert_eq "${OURBOX_AIRGAP_PLATFORM_IMAGES_LOCK_SHA256}" "f6d6171f7065059b7d7008961d0fecc5b7d65075dd7c7c3514ee5d8418f48118" "validated bundle should export images lock sha"

  rm -rf "${tmp}"
}

test_airgap_platform_validate_extracted_bundle_rejects_missing_contract_digest_hidden_by_ambient_env() {
  local tmp bundle_dir required_contract
  tmp="$(mktemp -d)"
  bundle_dir="${tmp}/bundle"
  required_contract="sha256:5656565656565656565656565656565656565656565656565656565656565656"

  mkdir -p "${bundle_dir}/k3s" "${bundle_dir}/platform/images"
  touch "${bundle_dir}/k3s/k3s-airgap-images-arm64.tar" "${bundle_dir}/platform/images.lock.json" "${bundle_dir}/platform/profile.env" "${bundle_dir}/platform/images/app.tar"
  cat > "${bundle_dir}/manifest.env" <<'EOF_MANIFEST'
OURBOX_AIRGAP_PLATFORM_SOURCE=https://github.com/techofourown/sw-ourbox-os
OURBOX_AIRGAP_PLATFORM_REVISION=6472fb5919d187daf832082eeaef6086b336a632
OURBOX_AIRGAP_PLATFORM_VERSION=v0.15.1
OURBOX_AIRGAP_PLATFORM_CREATED=2026-03-11T04:59:06Z
OURBOX_PLATFORM_CONTRACT_REF=ghcr.io/techofourown/sw-ourbox-os/platform-contract@sha256:5656565656565656565656565656565656565656565656565656565656565656
AIRGAP_PLATFORM_ARCH=arm64
K3S_VERSION=v1.35.0+k3s1
OURBOX_PLATFORM_PROFILE=demo-apps
OURBOX_PLATFORM_IMAGES_LOCK_PATH=platform/images.lock.json
OURBOX_PLATFORM_IMAGES_LOCK_SHA256=f6d6171f7065059b7d7008961d0fecc5b7d65075dd7c7c3514ee5d8418f48118
EOF_MANIFEST
  printf '#!/bin/sh\nexit 0\n' > "${bundle_dir}/k3s/k3s"
  chmod +x "${bundle_dir}/k3s/k3s"

  assert_fails "set -euo pipefail; source '${RESOLVER}'; export OURBOX_PLATFORM_CONTRACT_DIGEST='${required_contract}'; ourbox_airgap_platform_selection_validate_extracted_bundle '${bundle_dir}' '${required_contract}' 'arm64'" \
    "ambient shell variables must not satisfy missing airgap manifest fields"

  rm -rf "${tmp}"
}

test_airgap_platform_validate_extracted_bundle_rejects_missing_k3s_airgap_images_tar() {
  local tmp bundle_dir required_contract
  tmp="$(mktemp -d)"
  bundle_dir="${tmp}/bundle"
  required_contract="sha256:efefefefefefefefefefefefefefefefefefefefefefefefefefefefefefefef"

  mkdir -p "${bundle_dir}/k3s" "${bundle_dir}/platform/images"
  touch "${bundle_dir}/platform/images.lock.json" "${bundle_dir}/platform/profile.env" "${bundle_dir}/platform/images/app.tar"
  cat > "${bundle_dir}/manifest.env" <<EOF_MANIFEST
OURBOX_AIRGAP_PLATFORM_SOURCE=https://github.com/techofourown/sw-ourbox-os
OURBOX_AIRGAP_PLATFORM_REVISION=6472fb5919d187daf832082eeaef6086b336a632
OURBOX_AIRGAP_PLATFORM_VERSION=v0.15.1
OURBOX_AIRGAP_PLATFORM_CREATED=2026-03-11T04:59:06Z
OURBOX_PLATFORM_CONTRACT_REF=ghcr.io/techofourown/sw-ourbox-os/platform-contract@${required_contract}
OURBOX_PLATFORM_CONTRACT_DIGEST=${required_contract}
AIRGAP_PLATFORM_ARCH=arm64
K3S_VERSION=v1.35.0+k3s1
OURBOX_PLATFORM_PROFILE=demo-apps
OURBOX_PLATFORM_IMAGES_LOCK_PATH=platform/images.lock.json
OURBOX_PLATFORM_IMAGES_LOCK_SHA256=f6d6171f7065059b7d7008961d0fecc5b7d65075dd7c7c3514ee5d8418f48118
EOF_MANIFEST
  printf '#!/bin/sh\nexit 0\n' > "${bundle_dir}/k3s/k3s"
  chmod +x "${bundle_dir}/k3s/k3s"

  assert_fails "set -euo pipefail; source '${RESOLVER}'; ourbox_airgap_platform_selection_validate_extracted_bundle '${bundle_dir}' '${required_contract}' 'arm64'" \
    "airgap bundle validation should reject a missing k3s airgap images tar"

  rm -rf "${tmp}"
}

test_airgap_platform_validate_extracted_bundle_rejects_missing_platform_image_tars() {
  local tmp bundle_dir required_contract
  tmp="$(mktemp -d)"
  bundle_dir="${tmp}/bundle"
  required_contract="sha256:1212121212121212121212121212121212121212121212121212121212121212"

  mkdir -p "${bundle_dir}/k3s" "${bundle_dir}/platform/images"
  touch "${bundle_dir}/k3s/k3s-airgap-images-arm64.tar" "${bundle_dir}/platform/images.lock.json" "${bundle_dir}/platform/profile.env"
  cat > "${bundle_dir}/manifest.env" <<EOF_MANIFEST
OURBOX_AIRGAP_PLATFORM_SOURCE=https://github.com/techofourown/sw-ourbox-os
OURBOX_AIRGAP_PLATFORM_REVISION=6472fb5919d187daf832082eeaef6086b336a632
OURBOX_AIRGAP_PLATFORM_VERSION=v0.15.1
OURBOX_AIRGAP_PLATFORM_CREATED=2026-03-11T04:59:06Z
OURBOX_PLATFORM_CONTRACT_REF=ghcr.io/techofourown/sw-ourbox-os/platform-contract@${required_contract}
OURBOX_PLATFORM_CONTRACT_DIGEST=${required_contract}
AIRGAP_PLATFORM_ARCH=arm64
K3S_VERSION=v1.35.0+k3s1
OURBOX_PLATFORM_PROFILE=demo-apps
OURBOX_PLATFORM_IMAGES_LOCK_PATH=platform/images.lock.json
OURBOX_PLATFORM_IMAGES_LOCK_SHA256=f6d6171f7065059b7d7008961d0fecc5b7d65075dd7c7c3514ee5d8418f48118
EOF_MANIFEST
  printf '#!/bin/sh\nexit 0\n' > "${bundle_dir}/k3s/k3s"
  chmod +x "${bundle_dir}/k3s/k3s"

  assert_fails "set -euo pipefail; source '${RESOLVER}'; ourbox_airgap_platform_selection_validate_extracted_bundle '${bundle_dir}' '${required_contract}' 'arm64'" \
    "airgap bundle validation should reject missing platform image tar payloads"

  rm -rf "${tmp}"
}

main() {
  test_remote_defaults_bundle_shape
  test_precedence_prefers_os_ref_then_os_default_ref
  test_catalog_resolution_uses_newest_valid_created_timestamp
  test_catalog_resolution_accepts_legacy_target_qualified_channel_rows
  test_missing_channel_tags_fall_back_to_target_defaults
  test_catalog_falls_back_to_channel_tag_without_valid_digest_row
  test_matchbox_style_command_substitution_keeps_stdout_clean_on_catalog_fallback
  test_interactive_accepts_default_ref
  test_interactive_repo_override_clears_pinned_default
  test_interactive_channel_pick_prefers_catalog_row_over_baked_default
  test_interactive_catalog_pick_returns_pinned_ref
  test_interactive_catalog_pick_normalizes_legacy_channel_name
  test_finalize_registry_ref_resolves_digest
  test_finalize_registry_ref_handles_registry_ports_without_tags
  test_finalize_registry_ref_dev_override_marks_unresolved
  test_finalize_registry_ref_fails_closed_without_dev_override
  test_airgap_platform_default_precedence_prefers_exact_ref_then_catalog
  test_airgap_platform_catalog_resolution_uses_newest_matching_created_timestamp
  test_airgap_platform_channel_requires_catalog_when_no_exact_ref
  test_airgap_platform_catalog_filters_non_matching_contract_digest
  test_airgap_platform_interactive_repo_override_supports_custom_ref_without_catalog_default
  test_airgap_platform_interactive_channel_pick_prefers_catalog_row
  test_airgap_platform_finalize_registry_ref_resolves_digest
  test_airgap_platform_finalize_registry_ref_dev_override_marks_unresolved
  test_airgap_platform_validate_extracted_bundle_rejects_invalid_manifest_contract_digest
  test_airgap_platform_validate_extracted_bundle_exports_manifest_metadata
  test_airgap_platform_validate_extracted_bundle_rejects_missing_contract_digest_hidden_by_ambient_env
  test_airgap_platform_validate_extracted_bundle_rejects_missing_k3s_airgap_images_tar
  test_airgap_platform_validate_extracted_bundle_rejects_missing_platform_image_tars
  printf 'installer-selection resolver tests: PASS\n'
}

main "$@"
