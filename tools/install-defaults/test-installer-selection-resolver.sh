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
  local tmp pull_dir extract_dir fake_oras_dir defaults_src override_env
  tmp="$(mktemp -d)"
  pull_dir="${tmp}/pull"
  extract_dir="${tmp}/extract"
  fake_oras_dir="${tmp}/bin"
  defaults_src="${tmp}/defaults-src"
  override_env="${tmp}/override.env"
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
OURBOX_SUBSTRATE_REPO=ghcr.io/example/custom-ourbox-substrate
OURBOX_SUBSTRATE_ARCH=amd64
OURBOX_SUBSTRATE_CHANNEL=stable
OURBOX_SUBSTRATE_CATALOG_ENABLED=1
OURBOX_SUBSTRATE_CATALOG_TAG=catalog-amd64
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
  OS_REPO="ghcr.io/techofourown/ourbox-woodbox-os"
  OS_TARGET="x86"
  OS_CHANNEL="stable"

  ourbox_selection_reset_state
  ourbox_selection_load_remote_install_defaults "${pull_dir}" "${extract_dir}" "${override_env}"

  assert_eq "${OURBOX_INSTALL_DEFAULTS_SOURCE}" "remote" "remote defaults should apply"
  assert_eq "${OS_REPO}" "ghcr.io/example/custom-woodbox-os" "remote defaults should override repo"
  assert_eq "${OS_CATALOG_TAG}" "custom-catalog" "remote defaults should override catalog tag"
  assert_eq "${OURBOX_SUBSTRATE_REPO}" "ghcr.io/example/custom-ourbox-substrate" "remote defaults should override ourbox-substrate repo"
  assert_eq "${OS_CHANNEL}" "nightly" "override env should win after remote defaults"

  rm -rf "${tmp}"
}

test_precedence_prefers_os_ref_then_catalog() {
  local tmp fake_oras_dir catalog_src
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"
  catalog_src="${tmp}/catalog-src"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"

  mkdir -p "${catalog_src}"
  cat > "${catalog_src}/catalog.tsv" <<'EOF_CATALOG'
channel	tag	created	version	variant	target	sku	git_sha	k3s_version	payload_sha256	artifact_digest	pinned_ref	notes
stable	v0.9.0-rpi	2026-03-08T01:00:00Z	v0.9.0	prod	rpi	TOO	abc	v1	sha256:a	sha256:a	ghcr.io/techofourown/ourbox-matchbox-os@sha256:1111111111111111111111111111111111111111111111111111111111111111	stable-row
EOF_CATALOG
  export FAKE_ORAS_CATALOG_DIR="${catalog_src}"

  # shellcheck disable=SC1090
  source "${RESOLVER}"

  OS_REPO="ghcr.io/techofourown/ourbox-matchbox-os"
  OS_TARGET="rpi"
  OS_CHANNEL="stable"
  OS_CATALOG_ENABLED="1"
  OS_CATALOG_TAG="rpi-catalog"

  OS_REF="ghcr.io/example/custom-os:demo"
  ourbox_selection_reset_state
  ourbox_selection_determine_default_ref "${tmp}/catalog"
  assert_eq "${OURBOX_INSTALL_SELECTION_SOURCE}" "os-ref" "OS_REF should have highest precedence"
  assert_eq "${OURBOX_SELECTED_REF}" "ghcr.io/example/custom-os:demo" "OS_REF should be selected"

  OS_REF=""
  ourbox_selection_reset_state
  ourbox_selection_determine_default_ref "${tmp}/catalog"
  assert_eq "${OURBOX_INSTALL_SELECTION_SOURCE}" "catalog" "catalog should supply the default when no exact ref is set"
  assert_eq "${OURBOX_SELECTED_REF}" "ghcr.io/techofourown/ourbox-matchbox-os@sha256:1111111111111111111111111111111111111111111111111111111111111111" "catalog row should be selected"

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
channel	tag	created	version	variant	target	sku	git_sha	k3s_version	payload_sha256	artifact_digest	pinned_ref	notes
stable	v0.5.0-x86	2026-03-07T07:34:04Z	v0.5.0	prod	x86	TOO	abc	v1	sha256:a	sha256:a	ghcr.io/techofourown/ourbox-woodbox-os@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa	old-good
stable	v0.5.9-x86	2026-03-07T23:59:59Z	v0.5.9	prod	x86	TOO	def	v1	sha256:b	sha256:b	ghcr.io/techofourown/ourbox-woodbox-os:stable	not-digest-pinned
nightly	nightly-x86	2026-03-08T00:00:01Z	nightly	prod	x86	TOO	ghi	v1	sha256:c	sha256:c	ghcr.io/techofourown/ourbox-woodbox-os@sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc	nightly-row
stable	v0.5.3-x86	2026-03-07T23:08:54Z	v0.5.3	prod	x86	TOO	jkl	v1	sha256:d	sha256:d	ghcr.io/techofourown/ourbox-woodbox-os@sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb	newest-valid
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
channel	tag	created	version	variant	target	sku	git_sha	k3s_version	payload_sha256	artifact_digest	pinned_ref	notes
rpi-stable	v0.9.9-rpi	2026-03-09T01:23:45Z	v0.9.9	prod	rpi	TOO	abc	v1	sha256:a	sha256:a	ghcr.io/techofourown/ourbox-matchbox-os@sha256:9999999999999999999999999999999999999999999999999999999999999999	legacy-channel-row
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

  ourbox_selection_reset_state
  ourbox_selection_determine_default_ref "${tmp}/catalog"

  assert_eq "${OURBOX_INSTALL_SELECTION_SOURCE}" "catalog" "legacy target-qualified catalog rows should remain selectable during channel-name migration"
  assert_eq "${OURBOX_RELEASE_CHANNEL}" "stable" "legacy catalog channel names should normalize back to the short release channel"
  assert_eq "${OURBOX_SELECTED_REF}" "${expected}" "legacy target-qualified catalog rows should resolve to their pinned ref"

  rm -rf "${tmp}"
}

test_catalog_disabled_leaves_no_default() {
  local tmp
  tmp="$(mktemp -d)"

  # shellcheck disable=SC1090
  source "${RESOLVER}"

  OS_REPO="ghcr.io/techofourown/ourbox-woodbox-os"
  OS_TARGET="x86"
  OS_CHANNEL="stable"
  OS_CATALOG_ENABLED="0"
  OS_REF=""

  ourbox_selection_reset_state
  if ourbox_selection_determine_default_ref "${tmp}/catalog"; then
    printf 'ASSERTION FAILED: OS selection should require a catalog-backed default when no exact ref is set\n' >&2
    exit 1
  fi

  assert_eq "${OURBOX_INSTALL_SELECTION_SOURCE}" "" "disabled catalog should leave the selection source empty"
  assert_eq "${OURBOX_SELECTED_REF}" "" "disabled catalog should leave the selected ref empty"

  rm -rf "${tmp}"
}

test_catalog_requires_valid_digest_row() {
  local tmp fake_oras_dir catalog_src
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"
  catalog_src="${tmp}/catalog-src"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"

  mkdir -p "${catalog_src}"
  cat > "${catalog_src}/catalog.tsv" <<'EOF_CATALOG'
channel	tag	created	version	variant	target	sku	git_sha	k3s_version	img_sha256	artifact_digest	pinned_ref
stable	v0.9.4-rpi	2026-03-08T01:23:18Z	v0.9.4	prod	rpi	TOO	abc	v1	sha256:a	sha256:a	ghcr.io/techofourown/ourbox-matchbox-os:rpi-stable
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

  ourbox_selection_reset_state
  if ourbox_selection_determine_default_ref "${tmp}/catalog"; then
    printf 'ASSERTION FAILED: OS selection should reject catalog rows without digest-pinned refs\n' >&2
    exit 1
  fi

  assert_eq "${OURBOX_INSTALL_SELECTION_SOURCE}" "" "invalid catalog rows should not synthesize a selection source"
  assert_eq "${OURBOX_RELEASE_CHANNEL}" "" "invalid catalog rows should not record a release channel"
  assert_eq "${OURBOX_SELECTED_REF}" "" "invalid catalog rows should leave the selected ref empty"

  rm -rf "${tmp}"
}

test_matchbox_style_command_substitution_keeps_stdout_clean_on_catalog_failure() {
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

  matchbox_style_default_payload_ref() {
    if ! ourbox_selection_determine_default_ref "${tmp}/catalog"; then
      :
    fi
    printf '%s\n' "${OURBOX_SELECTED_REF}"
  }

  captured="$(matchbox_style_default_payload_ref 2>"${stderr_file}")"

  assert_eq "${captured}" "" "catalog failure should leave stdout machine-readable for Matchbox-style command substitution"
  assert_contains "$(cat "${stderr_file}")" "Catalog unavailable for ghcr.io/techofourown/ourbox-matchbox-os:rpi-catalog." "catalog failure log should be routed to stderr"

  rm -rf "${tmp}"
}

test_interactive_accepts_default_ref() {
  local tmp fake_oras_dir catalog_src captured digest
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"
  catalog_src="${tmp}/catalog-src"
  digest="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"

  mkdir -p "${catalog_src}"
  cat > "${catalog_src}/catalog.tsv" <<EOF_CATALOG
channel	tag	created	version	variant	target	sku	git_sha	k3s_version	payload_sha256	artifact_digest	pinned_ref	notes
stable	v0.9.0-rpi	2026-03-08T01:00:00Z	v0.9.0	prod	rpi	TOO	abc	v1	sha256:a	sha256:a	ghcr.io/techofourown/ourbox-matchbox-os@sha256:${digest}	stable-row
EOF_CATALOG
  export FAKE_ORAS_CATALOG_DIR="${catalog_src}"

  captured="$(
    printf '\n' | bash -lc "
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
      ourbox_selection_reset_state
      ourbox_selection_interactive_select_ref '${tmp}/catalog' >/dev/null
      printf '%s\t%s\t%s\n' \"\$OURBOX_SELECTED_REF\" \"\$OURBOX_INSTALL_SELECTION_SOURCE\" \"\${OURBOX_RELEASE_CHANNEL:-}\"
    " 2>/dev/null
  )"

  assert_eq "${captured}" $'ghcr.io/techofourown/ourbox-matchbox-os@sha256:'"${digest}"$'\tcatalog\tstable' "interactive Enter should keep the resolved catalog-backed default ref"

  rm -rf "${tmp}"
}

test_interactive_repo_override_rederives_catalog_default() {
  local tmp fake_oras_dir catalog_src captured digest
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"
  catalog_src="${tmp}/catalog-src"
  digest="bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"

  mkdir -p "${catalog_src}"
  cat > "${catalog_src}/catalog.tsv" <<EOF_CATALOG
channel	tag	created	version	variant	target	sku	git_sha	k3s_version	payload_sha256	artifact_digest	pinned_ref	notes
stable	v0.9.0-rpi	2026-03-08T01:00:00Z	v0.9.0	prod	rpi	TOO	abc	v1	sha256:a	sha256:a	localhost:5000/custom/ourbox-matchbox-os@sha256:${digest}	stable-row
EOF_CATALOG
  export FAKE_ORAS_CATALOG_DIR="${catalog_src}"

  captured="$(
    printf 'o\nlocalhost:5000/custom/ourbox-matchbox-os\ncustom-catalog\n\n' | bash -lc "
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
      ourbox_selection_reset_state
      ourbox_selection_interactive_select_ref '${tmp}/catalog' >/dev/null
      printf '%s\t%s\t%s\t%s\t%s\n' \"\$OURBOX_SELECTED_REF\" \"\$OURBOX_INSTALL_SELECTION_SOURCE\" \"\${OURBOX_RELEASE_CHANNEL:-}\" \"\$OS_REPO\" \"\$OS_CATALOG_TAG\"
    " 2>/dev/null
  )"

  assert_eq "${captured}" $'localhost:5000/custom/ourbox-matchbox-os@sha256:'"${digest}"$'\tcatalog\tstable\tlocalhost:5000/custom/ourbox-matchbox-os\tcustom-catalog' "repo override should rederive the default from the overridden repo's catalog"

  rm -rf "${tmp}"
}

test_interactive_channel_pick_prefers_selected_catalog_row() {
  local tmp fake_oras_dir catalog_src captured beta_digest
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"
  catalog_src="${tmp}/catalog-src"
  beta_digest="2222222222222222222222222222222222222222222222222222222222222222"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"

  mkdir -p "${catalog_src}"
  cat > "${catalog_src}/catalog.tsv" <<'EOF_CATALOG'
channel	tag	created	version	variant	target	sku	git_sha	k3s_version	payload_sha256	artifact_digest	pinned_ref	notes
stable	v0.9.0-rpi	2026-03-08T01:00:00Z	v0.9.0	prod	rpi	TOO	abc	v1	sha256:a	sha256:a	ghcr.io/techofourown/ourbox-matchbox-os@sha256:1111111111111111111111111111111111111111111111111111111111111111	stable-row
beta	v0.9.1-rpi	2026-03-08T02:00:00Z	v0.9.1	prod	rpi	TOO	def	v1	sha256:b	sha256:b	ghcr.io/techofourown/ourbox-matchbox-os@sha256:2222222222222222222222222222222222222222222222222222222222222222	beta-row
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
      ourbox_selection_reset_state
      ourbox_selection_interactive_select_ref '${tmp}/catalog' >/dev/null
      printf '%s\t%s\t%s\n' \"\$OURBOX_SELECTED_REF\" \"\$OURBOX_INSTALL_SELECTION_SOURCE\" \"\${OURBOX_RELEASE_CHANNEL:-}\"
    " 2>/dev/null
  )"

  assert_eq "${captured}" $'ghcr.io/techofourown/ourbox-matchbox-os@sha256:'"${beta_digest}"$'\tcatalog\tbeta' "interactive channel choice should prefer the selected lane's catalog row"

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
channel	tag	created	version	variant	target	sku	git_sha	k3s_version	payload_sha256	artifact_digest	pinned_ref	notes
stable	v0.9.0-rpi	2026-03-08T01:00:00Z	v0.9.0	prod	rpi	TOO	abc	v1	sha256:a	sha256:a	ghcr.io/techofourown/ourbox-matchbox-os@sha256:1111111111111111111111111111111111111111111111111111111111111111	stable-row
beta	v0.9.1-rpi	2026-03-08T02:00:00Z	v0.9.1	prod	rpi	TOO	def	v1	sha256:b	sha256:b	ghcr.io/techofourown/ourbox-matchbox-os@sha256:2222222222222222222222222222222222222222222222222222222222222222	beta-row
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
channel	tag	created	version	variant	target	sku	git_sha	k3s_version	payload_sha256	artifact_digest	pinned_ref	notes
rpi-stable	v0.9.0-rpi	2026-03-08T01:00:00Z	v0.9.0	prod	rpi	TOO	abc	v1	sha256:a	sha256:a	ghcr.io/techofourown/ourbox-matchbox-os@sha256:1111111111111111111111111111111111111111111111111111111111111111	legacy-stable-row
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

test_substrate_default_precedence_prefers_exact_ref_then_catalog() {
  local tmp fake_oras_dir catalog_src ref_digest catalog_digest
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"
  catalog_src="${tmp}/catalog-src"
  ref_digest="2222222222222222222222222222222222222222222222222222222222222222"
  catalog_digest="3333333333333333333333333333333333333333333333333333333333333333"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"

  mkdir -p "${catalog_src}"
  cat > "${catalog_src}/catalog.tsv" <<EOF_CATALOG
channel	tag	created	version	revision	arch	platform_profile	k3s_version	platform_images_lock_sha256	artifact_digest	pinned_ref
stable	stable-arm64	2026-03-09T00:00:00Z	v0.15.0	aaaa1111	arm64	demo-apps	v1.35.0+k3s1	aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa	sha256:${catalog_digest}	ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate@sha256:${catalog_digest}
EOF_CATALOG
  export FAKE_ORAS_CATALOG_DIR="${catalog_src}"

  # shellcheck disable=SC1090
  source "${RESOLVER}"

  OURBOX_SUBSTRATE_REPO="ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate"
  OURBOX_SUBSTRATE_ARCH="arm64"
  OURBOX_SUBSTRATE_CHANNEL="stable"
  OURBOX_SUBSTRATE_CATALOG_ENABLED="1"
  OURBOX_SUBSTRATE_CATALOG_TAG="catalog-arm64"

  OURBOX_SUBSTRATE_REF="ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate@sha256:${ref_digest}"
  ourbox_substrate_selection_reset_state
  ourbox_substrate_determine_default_ref "${tmp}/catalog"
  assert_eq "${OURBOX_SUBSTRATE_INSTALL_SELECTION_SOURCE}" "ourbox-substrate-ref" "OURBOX_SUBSTRATE_REF should have highest precedence"
  assert_eq "${OURBOX_SUBSTRATE_SELECTED_REF}" "ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate@sha256:${ref_digest}" "OURBOX_SUBSTRATE_REF should be selected directly"

  OURBOX_SUBSTRATE_REF=""
  ourbox_substrate_selection_reset_state
  ourbox_substrate_determine_default_ref "${tmp}/catalog"
  assert_eq "${OURBOX_SUBSTRATE_INSTALL_SELECTION_SOURCE}" "catalog" "catalog resolution should supply the default when no exact substrate ref is set"
  assert_eq "${OURBOX_SUBSTRATE_SELECTED_REF}" "ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate@sha256:${catalog_digest}" "catalog resolution should choose the matching digest-pinned row"

  rm -rf "${tmp}"
}

test_substrate_catalog_resolution_uses_newest_matching_created_timestamp() {
  local tmp fake_oras_dir catalog_src expected
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"
  catalog_src="${tmp}/catalog-src"
  expected="ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate@sha256:9999999999999999999999999999999999999999999999999999999999999999"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"

  mkdir -p "${catalog_src}"
  cat > "${catalog_src}/catalog.tsv" <<'EOF_CATALOG'
channel	tag	created	version	revision	arch	platform_profile	k3s_version	platform_images_lock_sha256	artifact_digest	pinned_ref
stable	stable-arm64	2026-03-08T00:00:00Z	v0.14.0	aaaa1111	arm64	demo-apps	v1.35.0+k3s1	aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa	sha256:6666666666666666666666666666666666666666666666666666666666666666	ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate@sha256:6666666666666666666666666666666666666666666666666666666666666666
stable	stable-arm64	2026-03-09T00:00:00Z	v0.15.0	bbbb2222	arm64	demo-apps	v1.35.0+k3s1	bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb	sha256:7777777777777777777777777777777777777777777777777777777777777777	ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate@sha256:7777777777777777777777777777777777777777777777777777777777777777
stable	stable-arm64	2026-03-10T00:00:00Z	v0.16.0	cccc3333	amd64	demo-apps	v1.35.0+k3s1	cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc	sha256:8888888888888888888888888888888888888888888888888888888888888888	ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate@sha256:8888888888888888888888888888888888888888888888888888888888888888
stable	stable-arm64	2026-03-11T00:00:00Z	v0.17.0	dddd4444	arm64	demo-apps	v1.35.0+k3s1	dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd	sha256:9999999999999999999999999999999999999999999999999999999999999999	ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate@sha256:9999999999999999999999999999999999999999999999999999999999999999
EOF_CATALOG
  export FAKE_ORAS_CATALOG_DIR="${catalog_src}"

  # shellcheck disable=SC1090
  source "${RESOLVER}"

  OURBOX_SUBSTRATE_REPO="ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate"
  OURBOX_SUBSTRATE_ARCH="arm64"
  OURBOX_SUBSTRATE_CHANNEL="stable"
  OURBOX_SUBSTRATE_REF=""
  OURBOX_SUBSTRATE_CATALOG_ENABLED="1"
  OURBOX_SUBSTRATE_CATALOG_TAG="catalog-arm64"

  ourbox_substrate_selection_reset_state
  ourbox_substrate_determine_default_ref "${tmp}/catalog"

  assert_eq "${OURBOX_SUBSTRATE_INSTALL_SELECTION_SOURCE}" "catalog" "substrate resolver should prefer catalog rows when a digest-pinned row exists"
  assert_eq "${OURBOX_SUBSTRATE_RELEASE_CHANNEL}" "stable" "substrate catalog resolution should preserve the selected release channel"
  assert_eq "${OURBOX_SUBSTRATE_SELECTED_REF}" "${expected}" "substrate catalog resolution should choose the newest arm64 row by created timestamp"

  rm -rf "${tmp}"
}

test_substrate_channel_requires_catalog_when_no_exact_ref() {
  local tmp fake_oras_dir
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"
  export FAKE_ORAS_CATALOG_DIR="${tmp}/missing-catalog"

  # shellcheck disable=SC1090
  source "${RESOLVER}"

  OURBOX_SUBSTRATE_REPO="ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate"
  OURBOX_SUBSTRATE_ARCH="amd64"
  OURBOX_SUBSTRATE_CHANNEL="beta"
  OURBOX_SUBSTRATE_REF=""
  OURBOX_SUBSTRATE_CATALOG_ENABLED="1"
  OURBOX_SUBSTRATE_CATALOG_TAG="catalog-amd64"

  ourbox_substrate_selection_reset_state
  if ourbox_substrate_determine_default_ref "${tmp}/catalog"; then
    printf 'ASSERTION FAILED: substrate selection should require a matching catalog row when no exact ref is set\n' >&2
    exit 1
  fi

  assert_eq "${OURBOX_SUBSTRATE_INSTALL_SELECTION_SOURCE}" "" "substrate selection should not synthesize a selection source when the catalog is unavailable"
  assert_eq "${OURBOX_SUBSTRATE_RELEASE_CHANNEL}" "" "substrate selection should not record a release channel when no catalog-backed default exists"
  assert_eq "${OURBOX_SUBSTRATE_SELECTED_REF}" "" "substrate selection should leave the selected ref empty when no catalog-backed default exists"

  rm -rf "${tmp}"
}


test_substrate_interactive_repo_override_supports_custom_ref_without_catalog_default() {
  local tmp captured custom_digest
  tmp="$(mktemp -d)"
  custom_digest="9090909090909090909090909090909090909090909090909090909090909090"

  captured="$(
    printf "o\nlocalhost:5000/custom/ourbox-substrate\ncustom-catalog\nr\nlocalhost:5000/custom/ourbox-substrate@sha256:${custom_digest}\n" | bash -lc "
      set -euo pipefail
      source '${RESOLVER}'
      OURBOX_SUBSTRATE_REPO='ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate'
      OURBOX_SUBSTRATE_ARCH='arm64'
      OURBOX_SUBSTRATE_CHANNEL='stable'
      OURBOX_SUBSTRATE_REF=''
      OURBOX_SUBSTRATE_CATALOG_ENABLED='0'
      OURBOX_SUBSTRATE_CATALOG_TAG='catalog-arm64'
      ourbox_substrate_selection_reset_state
      ourbox_substrate_selection_interactive_select_ref '${tmp}/catalog' >/dev/null
      printf '%s\t%s\t%s\t%s\t%s\n' \"\$OURBOX_SUBSTRATE_SELECTED_REF\" \"\$OURBOX_SUBSTRATE_INSTALL_SELECTION_SOURCE\" \"\${OURBOX_SUBSTRATE_RELEASE_CHANNEL:-}\" \"\$OURBOX_SUBSTRATE_REPO\" \"\$OURBOX_SUBSTRATE_CATALOG_TAG\"
    " 2>/dev/null
  )"

  assert_eq "${captured}" $'localhost:5000/custom/ourbox-substrate@sha256:'"${custom_digest}"$'\toperator-override\t\tlocalhost:5000/custom/ourbox-substrate\tcustom-catalog' "substrate repo override should preserve the overridden repo and allow an explicit custom ref when no catalog-backed default exists"

  rm -rf "${tmp}"
}

test_substrate_interactive_channel_pick_prefers_catalog_row() {
  local tmp fake_oras_dir catalog_src captured beta_digest
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"
  catalog_src="${tmp}/catalog-src"
  beta_digest="bcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbcbc"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"

  mkdir -p "${catalog_src}"
  cat > "${catalog_src}/catalog.tsv" <<'EOF_CATALOG'
channel	tag	created	version	revision	arch	platform_profile	k3s_version	platform_images_lock_sha256	artifact_digest	pinned_ref
stable	stable-arm64	2026-03-08T01:00:00Z	v0.9.0	aaaa1111	arm64	demo-apps	v1.35.0+k3s1	aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa	sha256:1111111111111111111111111111111111111111111111111111111111111111	ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate@sha256:1111111111111111111111111111111111111111111111111111111111111111
EOF_CATALOG
  cat >> "${catalog_src}/catalog.tsv" <<EOF_CATALOG
beta	beta-arm64	2026-03-08T02:00:00Z	v0.9.1	bbbb2222	arm64	demo-apps	v1.35.0+k3s1	bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb	sha256:${beta_digest}	ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate@sha256:${beta_digest}
EOF_CATALOG
  export FAKE_ORAS_CATALOG_DIR="${catalog_src}"

  captured="$(
    printf 'c\n2\n' | bash -lc "
      set -euo pipefail
      PATH='${fake_oras_dir}':\"\$PATH\"
      export FAKE_ORAS_CATALOG_DIR='${catalog_src}'
      source '${RESOLVER}'
      OURBOX_SUBSTRATE_REPO='ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate'
      OURBOX_SUBSTRATE_ARCH='arm64'
      OURBOX_SUBSTRATE_CHANNEL='stable'
      OURBOX_SUBSTRATE_REF=''
      OURBOX_SUBSTRATE_CATALOG_ENABLED='1'
      OURBOX_SUBSTRATE_CATALOG_TAG='catalog-arm64'
      ourbox_substrate_selection_reset_state
      ourbox_substrate_selection_interactive_select_ref '${tmp}/catalog' >/dev/null
      printf '%s\t%s\t%s\n' \"\$OURBOX_SUBSTRATE_SELECTED_REF\" \"\$OURBOX_SUBSTRATE_INSTALL_SELECTION_SOURCE\" \"\${OURBOX_SUBSTRATE_RELEASE_CHANNEL:-}\"
    " 2>/dev/null
  )"

  assert_eq "${captured}" $'ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate@sha256:'"${beta_digest}"$'\tcatalog\tbeta' "interactive substrate channel choice should prefer the selected lane's catalog row"

  rm -rf "${tmp}"
}

test_substrate_finalize_registry_ref_resolves_digest() {
  local tmp fake_oras_dir digest
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"
  digest="sha256:abababababababababababababababababababababababababababababababab"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"
  export FAKE_ORAS_RESOLVE_REF="ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate:stable-arm64"
  export FAKE_ORAS_RESOLVE_DIGEST="${digest}"

  # shellcheck disable=SC1090
  source "${RESOLVER}"

  ourbox_substrate_selection_reset_state
  ourbox_substrate_selection_finalize_registry_ref "ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate:stable-arm64"

  assert_eq "${OURBOX_SUBSTRATE_ARTIFACT_REF}" "ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate:stable-arm64" "substrate artifact ref should preserve the operator-facing ref"
  assert_eq "${OURBOX_SUBSTRATE_ARTIFACT_DIGEST}" "${digest}" "substrate artifact digest should come from oras resolve"
  assert_eq "${OURBOX_SUBSTRATE_PULL_REF}" "ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate@${digest}" "substrate pull ref should be immutable"

  rm -rf "${tmp}"
}

test_substrate_finalize_registry_ref_dev_override_marks_unresolved() {
  local tmp fake_oras_dir
  tmp="$(mktemp -d)"
  fake_oras_dir="${tmp}/bin"

  make_fake_oras "${fake_oras_dir}"
  export PATH="${fake_oras_dir}:${PATH}"
  export FAKE_ORAS_RESOLVE_REF="ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate:nightly-amd64"
  export FAKE_ORAS_RESOLVE_DIGEST=""
  export OURBOX_ALLOW_UNRESOLVED_PULL="1"

  # shellcheck disable=SC1090
  source "${RESOLVER}"

  ourbox_substrate_selection_reset_state
  ourbox_substrate_selection_finalize_registry_ref "ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate:nightly-amd64"

  assert_eq "${OURBOX_SUBSTRATE_ARTIFACT_DIGEST}" "unresolved" "substrate dev override should mark unresolved digest explicitly"
  assert_eq "${OURBOX_SUBSTRATE_PULL_REF}" "ghcr.io/techofourown/sw-ourbox-os/ourbox-substrate:nightly-amd64" "substrate dev override should pull the original floating ref"

  unset OURBOX_ALLOW_UNRESOLVED_PULL
  rm -rf "${tmp}"
}


test_substrate_validate_extracted_bundle_exports_manifest_metadata() {
  local tmp bundle_dir
  tmp="$(mktemp -d)"
  bundle_dir="${tmp}/bundle"

  mkdir -p "${bundle_dir}/k3s" "${bundle_dir}/platform/images"
  touch "${bundle_dir}/k3s/k3s-images-arm64.tar" "${bundle_dir}/platform/images.lock.json" "${bundle_dir}/platform/profile.env" "${bundle_dir}/platform/images/platform.tar"
  cat > "${bundle_dir}/manifest.env" <<'EOF_MANIFEST'
OURBOX_SUBSTRATE_SOURCE=https://github.com/techofourown/sw-ourbox-os
OURBOX_SUBSTRATE_REVISION=6472fb5919d187daf832082eeaef6086b336a632
OURBOX_SUBSTRATE_VERSION=v0.15.1
OURBOX_SUBSTRATE_CREATED=2026-03-11T04:59:06Z
OURBOX_PLATFORM_CONTRACT_REF=ghcr.io/techofourown/sw-ourbox-os/platform-contract@sha256:abababababababababababababababababababababababababababababababab
OURBOX_SUBSTRATE_ARCH=arm64
K3S_VERSION=v1.35.0+k3s1
OURBOX_PLATFORM_PROFILE=demo-apps
OURBOX_PLATFORM_IMAGES_LOCK_PATH=platform/images.lock.json
OURBOX_PLATFORM_IMAGES_LOCK_SHA256=f6d6171f7065059b7d7008961d0fecc5b7d65075dd7c7c3514ee5d8418f48118
EOF_MANIFEST
  printf '#!/bin/sh\nexit 0\n' > "${bundle_dir}/k3s/k3s"
  chmod +x "${bundle_dir}/k3s/k3s"

  # shellcheck disable=SC1090
  source "${RESOLVER}"

  OURBOX_SUBSTRATE_SOURCE="stale-source"
  OURBOX_SUBSTRATE_REVISION="stale-revision"
  OURBOX_SUBSTRATE_VERSION="stale-version"
  OURBOX_SUBSTRATE_CREATED="stale-created"
  OURBOX_SUBSTRATE_ARCH="stale-arch"
  OURBOX_SUBSTRATE_PROFILE="stale-profile"
  OURBOX_SUBSTRATE_K3S_VERSION="stale-k3s"
  OURBOX_SUBSTRATE_IMAGES_LOCK_SHA256="stale-lock"

  ourbox_substrate_selection_validate_extracted_bundle "${bundle_dir}" "arm64"

  assert_eq "${OURBOX_SUBSTRATE_SOURCE}" "https://github.com/techofourown/sw-ourbox-os" "validated bundle should export substrate source"
  assert_eq "${OURBOX_SUBSTRATE_REVISION}" "6472fb5919d187daf832082eeaef6086b336a632" "validated bundle should export substrate revision"
  assert_eq "${OURBOX_SUBSTRATE_VERSION}" "v0.15.1" "validated bundle should export substrate version"
  assert_eq "${OURBOX_SUBSTRATE_CREATED}" "2026-03-11T04:59:06Z" "validated bundle should export substrate created timestamp"
  assert_eq "${OURBOX_SUBSTRATE_ARCH}" "arm64" "validated bundle should export substrate arch"
  assert_eq "${OURBOX_SUBSTRATE_PROFILE}" "demo-apps" "validated bundle should export platform profile"
  assert_eq "${OURBOX_SUBSTRATE_K3S_VERSION}" "v1.35.0+k3s1" "validated bundle should export k3s version"
  assert_eq "${OURBOX_SUBSTRATE_IMAGES_LOCK_SHA256}" "f6d6171f7065059b7d7008961d0fecc5b7d65075dd7c7c3514ee5d8418f48118" "validated bundle should export images lock sha"

  rm -rf "${tmp}"
}

test_substrate_validate_extracted_bundle_rejects_missing_k3s_images_tar() {
  local tmp bundle_dir
  tmp="$(mktemp -d)"
  bundle_dir="${tmp}/bundle"

  mkdir -p "${bundle_dir}/k3s" "${bundle_dir}/platform/images"
  touch "${bundle_dir}/platform/images.lock.json" "${bundle_dir}/platform/profile.env" "${bundle_dir}/platform/images/platform.tar"
  cat > "${bundle_dir}/manifest.env" <<'EOF_MANIFEST'
OURBOX_SUBSTRATE_SOURCE=https://github.com/techofourown/sw-ourbox-os
OURBOX_SUBSTRATE_REVISION=6472fb5919d187daf832082eeaef6086b336a632
OURBOX_SUBSTRATE_VERSION=v0.15.1
OURBOX_SUBSTRATE_CREATED=2026-03-11T04:59:06Z
OURBOX_PLATFORM_CONTRACT_REF=ghcr.io/techofourown/sw-ourbox-os/platform-contract@sha256:efefefefefefefefefefefefefefefefefefefefefefefefefefefefefefefef
OURBOX_SUBSTRATE_ARCH=arm64
K3S_VERSION=v1.35.0+k3s1
OURBOX_PLATFORM_PROFILE=demo-apps
OURBOX_PLATFORM_IMAGES_LOCK_PATH=platform/images.lock.json
OURBOX_PLATFORM_IMAGES_LOCK_SHA256=f6d6171f7065059b7d7008961d0fecc5b7d65075dd7c7c3514ee5d8418f48118
EOF_MANIFEST
  printf '#!/bin/sh\nexit 0\n' > "${bundle_dir}/k3s/k3s"
  chmod +x "${bundle_dir}/k3s/k3s"

  assert_fails "set -euo pipefail; source '${RESOLVER}'; ourbox_substrate_selection_validate_extracted_bundle '${bundle_dir}' 'arm64'" \
    "substrate bundle validation should reject a missing k3s images tar"

  rm -rf "${tmp}"
}

test_substrate_validate_extracted_bundle_rejects_missing_platform_image_tars() {
  local tmp bundle_dir
  tmp="$(mktemp -d)"
  bundle_dir="${tmp}/bundle"

  mkdir -p "${bundle_dir}/k3s" "${bundle_dir}/platform/images"
  touch "${bundle_dir}/k3s/k3s-images-arm64.tar" "${bundle_dir}/platform/images.lock.json" "${bundle_dir}/platform/profile.env"
  cat > "${bundle_dir}/manifest.env" <<'EOF_MANIFEST'
OURBOX_SUBSTRATE_SOURCE=https://github.com/techofourown/sw-ourbox-os
OURBOX_SUBSTRATE_REVISION=6472fb5919d187daf832082eeaef6086b336a632
OURBOX_SUBSTRATE_VERSION=v0.15.1
OURBOX_SUBSTRATE_CREATED=2026-03-11T04:59:06Z
OURBOX_PLATFORM_CONTRACT_REF=ghcr.io/techofourown/sw-ourbox-os/platform-contract@sha256:1212121212121212121212121212121212121212121212121212121212121212
OURBOX_SUBSTRATE_ARCH=arm64
K3S_VERSION=v1.35.0+k3s1
OURBOX_PLATFORM_PROFILE=demo-apps
OURBOX_PLATFORM_IMAGES_LOCK_PATH=platform/images.lock.json
OURBOX_PLATFORM_IMAGES_LOCK_SHA256=f6d6171f7065059b7d7008961d0fecc5b7d65075dd7c7c3514ee5d8418f48118
EOF_MANIFEST
  printf '#!/bin/sh\nexit 0\n' > "${bundle_dir}/k3s/k3s"
  chmod +x "${bundle_dir}/k3s/k3s"

  assert_fails "set -euo pipefail; source '${RESOLVER}'; ourbox_substrate_selection_validate_extracted_bundle '${bundle_dir}' 'arm64'" \
    "substrate bundle validation should reject missing platform image tar payloads"

  rm -rf "${tmp}"
}

main() {
  test_remote_defaults_bundle_shape
  test_precedence_prefers_os_ref_then_catalog
  test_catalog_resolution_uses_newest_valid_created_timestamp
  test_catalog_resolution_accepts_legacy_target_qualified_channel_rows
  test_catalog_disabled_leaves_no_default
  test_catalog_requires_valid_digest_row
  test_matchbox_style_command_substitution_keeps_stdout_clean_on_catalog_failure
  test_interactive_accepts_default_ref
  test_interactive_repo_override_rederives_catalog_default
  test_interactive_channel_pick_prefers_selected_catalog_row
  test_interactive_catalog_pick_returns_pinned_ref
  test_interactive_catalog_pick_normalizes_legacy_channel_name
  test_finalize_registry_ref_resolves_digest
  test_finalize_registry_ref_handles_registry_ports_without_tags
  test_finalize_registry_ref_dev_override_marks_unresolved
  test_finalize_registry_ref_fails_closed_without_dev_override
  test_substrate_default_precedence_prefers_exact_ref_then_catalog
  test_substrate_catalog_resolution_uses_newest_matching_created_timestamp
  test_substrate_channel_requires_catalog_when_no_exact_ref
  test_substrate_interactive_repo_override_supports_custom_ref_without_catalog_default
  test_substrate_interactive_channel_pick_prefers_catalog_row
  test_substrate_finalize_registry_ref_resolves_digest
  test_substrate_finalize_registry_ref_dev_override_marks_unresolved
  test_substrate_validate_extracted_bundle_exports_manifest_metadata
  test_substrate_validate_extracted_bundle_rejects_missing_k3s_images_tar
  test_substrate_validate_extracted_bundle_rejects_missing_platform_image_tars
  printf 'installer-selection resolver tests: PASS\n'
}

main "$@"
