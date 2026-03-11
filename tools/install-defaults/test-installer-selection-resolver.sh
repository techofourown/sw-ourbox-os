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
  printf 'installer-selection resolver tests: PASS\n'
}

main "$@"
