#!/usr/bin/env bash
set -euo pipefail

# Shared installer-selection policy lives upstream in sw-ourbox-os.
# Consumers may vendor this file into target-specific installer images, but the
# contract and reference implementation are defined here.

ourbox_selection_log() {
  printf '[%s] %s\n' "$(date -Is)" "$*" >&2
}

ourbox_selection_die() {
  ourbox_selection_log "ERROR: $*"
  exit 1
}

ourbox_selection_need_cmd() {
  command -v "$1" >/dev/null 2>&1 || ourbox_selection_die "missing required command: $1"
}

ourbox_selection_reset_lane_state() {
  local selection_source_var="$1"
  local release_channel_var="$2"
  local catalog_ref_var="$3"
  local selected_ref_var="$4"
  local pull_ref_var="$5"
  local artifact_source_var="$6"
  local artifact_ref_var="$7"
  local artifact_digest_var="$8"

  printf -v "${selection_source_var}" '%s' ""
  printf -v "${release_channel_var}" '%s' ""
  printf -v "${catalog_ref_var}" '%s' ""
  printf -v "${selected_ref_var}" '%s' ""
  printf -v "${pull_ref_var}" '%s' ""
  printf -v "${artifact_source_var}" '%s' "registry"
  printf -v "${artifact_ref_var}" '%s' ""
  printf -v "${artifact_digest_var}" '%s' ""
}

ourbox_selection_reset_state() {
  OURBOX_INSTALL_DEFAULTS_SOURCE=""
  OURBOX_INSTALL_DEFAULTS_PROFILE=""
  ourbox_selection_reset_lane_state \
    OURBOX_INSTALL_SELECTION_SOURCE \
    OURBOX_RELEASE_CHANNEL \
    OURBOX_CATALOG_REF \
    OURBOX_SELECTED_REF \
    OURBOX_PULL_REF \
    OURBOX_OS_ARTIFACT_SOURCE \
    OURBOX_OS_ARTIFACT_REF \
    OURBOX_OS_ARTIFACT_DIGEST
}

ourbox_substrate_selection_reset_state() {
  ourbox_selection_reset_lane_state \
    OURBOX_SUBSTRATE_INSTALL_SELECTION_SOURCE \
    OURBOX_SUBSTRATE_RELEASE_CHANNEL \
    OURBOX_SUBSTRATE_CATALOG_REF \
    OURBOX_SUBSTRATE_SELECTED_REF \
    OURBOX_SUBSTRATE_PULL_REF \
    OURBOX_SUBSTRATE_ARTIFACT_SOURCE \
    OURBOX_SUBSTRATE_ARTIFACT_REF \
    OURBOX_SUBSTRATE_ARTIFACT_DIGEST
}

ourbox_selection_is_clean_single_line_ref() {
  local ref="${1:-}"
  [[ -n "${ref}" ]] || return 1
  [[ "${ref}" != *$'\n'* ]] || return 1
  [[ "${ref}" != *$'\r'* ]] || return 1
  [[ "${ref}" != *$'\t'* ]] || return 1
  [[ "${ref}" != *" "* ]] || return 1
  return 0
}

ourbox_selection_is_digest_pinned_ref() {
  local ref="${1:-}"
  ourbox_selection_is_clean_single_line_ref "${ref}" || return 1
  [[ "${ref}" =~ ^[^[:space:]]+@sha256:[0-9a-f]{64}$ ]] || return 1
  return 0
}

ourbox_selection_is_sha256_digest() {
  local digest="${1:-}"
  [[ "${digest}" =~ ^sha256:[0-9a-f]{64}$ ]] || return 1
  return 0
}

ourbox_selection_normalize_release_channel() {
  local channel="${1:-}"
  local target="${OS_TARGET:-}"

  case "${channel}" in
    stable|beta|nightly|exp-labs)
      printf '%s\n' "${channel}"
      return 0
      ;;
  esac

  if [[ -n "${target}" ]]; then
    case "${channel}" in
      "${target}-stable") printf 'stable\n'; return 0 ;;
      "${target}-beta") printf 'beta\n'; return 0 ;;
      "${target}-nightly") printf 'nightly\n'; return 0 ;;
      "${target}-exp-labs") printf 'exp-labs\n'; return 0 ;;
    esac
  fi

  printf '%s\n' "${channel}"
}

ourbox_selection_load_remote_install_defaults() {
  local pull_dir="$1"
  local extract_dir="$2"
  local override_env="${3:-}"
  local expected_installer_id="${INSTALLER_ID:-}"

  OURBOX_INSTALL_DEFAULTS_SOURCE=""
  OURBOX_INSTALL_DEFAULTS_PROFILE=""

  [[ -n "${INSTALL_DEFAULTS_REF:-}" ]] || ourbox_selection_die "INSTALL_DEFAULTS_REF is required"
  [[ -n "${expected_installer_id}" ]] || ourbox_selection_die "INSTALLER_ID is required"

  ourbox_selection_need_cmd oras
  rm -rf "${pull_dir}" "${extract_dir}"
  mkdir -p "${pull_dir}" "${extract_dir}"

  ourbox_selection_log "Pulling installer defaults: ${INSTALL_DEFAULTS_REF}"
  if ! oras pull "${INSTALL_DEFAULTS_REF}" -o "${pull_dir}" >/dev/null 2>&1; then
    ourbox_selection_die "Install defaults pull failed: ${INSTALL_DEFAULTS_REF}"
  fi

  local tarball=""
  if [[ -f "${pull_dir}/dist/install-defaults.tar.gz" ]]; then
    tarball="${pull_dir}/dist/install-defaults.tar.gz"
  else
    tarball="$(find "${pull_dir}" -maxdepth 4 -type f -name 'install-defaults.tar.gz' | head -n 1 || true)"
  fi
  [[ -n "${tarball}" && -f "${tarball}" ]] || {
    ourbox_selection_die "Install defaults artifact missing tarball: ${INSTALL_DEFAULTS_REF}"
  }

  if ! tar -xzf "${tarball}" -C "${extract_dir}" >/dev/null 2>&1; then
    ourbox_selection_die "Install defaults tar extraction failed: ${tarball}"
  fi

  [[ -f "${extract_dir}/install-defaults/schema.env" ]] || {
    ourbox_selection_die "Install defaults artifact missing schema.env: ${INSTALL_DEFAULTS_REF}"
  }
  [[ -f "${extract_dir}/install-defaults/manifest.env" ]] || {
    ourbox_selection_die "Install defaults artifact missing manifest.env: ${INSTALL_DEFAULTS_REF}"
  }

  local profile="${extract_dir}/install-defaults/defaults/${expected_installer_id}.env"
  if [[ ! -f "${profile}" ]]; then
    ourbox_selection_die "No install-defaults profile for installer '${expected_installer_id}' in ${INSTALL_DEFAULTS_REF}"
  fi

  # shellcheck disable=SC1090
  source "${profile}"
  if [[ -n "${override_env}" && -f "${override_env}" ]]; then
    # Re-apply local overrides so operators keep final control.
    # shellcheck disable=SC1090
    source "${override_env}"
  fi

  if declare -F normalize_payload_config >/dev/null 2>&1; then
    normalize_payload_config
  fi

  # shellcheck disable=SC2034  # output state consumed by the sourcing installer
  OURBOX_INSTALL_DEFAULTS_SOURCE="remote"
  # shellcheck disable=SC2034  # output state consumed by the sourcing installer
  OURBOX_INSTALL_DEFAULTS_PROFILE="${profile}"
  ourbox_selection_log "Applied install-defaults profile for '${expected_installer_id}'."
}

ourbox_selection_pull_catalog() {
  local dst="$1"
  local ref="${OS_REPO}:${OS_CATALOG_TAG}"

  if [[ "${OS_CATALOG_ENABLED:-1}" != "1" ]]; then
    return 1
  fi

  ourbox_selection_need_cmd oras
  rm -rf "${dst}"
  mkdir -p "${dst}"

  ourbox_selection_log "Pulling catalog: ${ref}"
  if ! oras pull "${ref}" -o "${dst}" >/dev/null 2>&1; then
    return 1
  fi
  [[ -f "${dst}/catalog.tsv" ]] || return 1

  OURBOX_CATALOG_REF="${ref}"
  return 0
}

ourbox_selection_catalog_entries() {
  local catalog_tsv="$1"
  [[ -f "${catalog_tsv}" ]] || return 1

  awk -F'\t' '
    NR == 1 {
      for (i = 1; i <= NF; i++) {
        idx[$i] = i
      }
      if (!idx["channel"] || !idx["tag"] || !idx["created"] || !idx["version"] || !idx["pinned_ref"]) {
        exit 0
      }
      next
    }
    {
      pinned = $(idx["pinned_ref"])
      created = $(idx["created"])
      if (created == "") {
        next
      }
      if (pinned !~ /^[^[:space:]]+@sha256:[0-9a-f]{64}$/) {
        next
      }
      print $(idx["channel"]) "\t" $(idx["tag"]) "\t" created "\t" $(idx["version"]) "\t" pinned
    }
  ' "${catalog_tsv}" | sort -t $'\t' -k3,3r -k2,2r
}

ourbox_selection_catalog_newest_ref() {
  local catalog_tsv="$1"
  local channel="$2"
  local row=""

  row="$(ourbox_selection_catalog_entries "${catalog_tsv}" | awk -F'\t' -v ch="${channel}" -v target="${OS_TARGET:-}" '
    $1 == ch || (target != "" && ch ~ /^(stable|beta|nightly|exp-labs)$/ && $1 == target "-" ch) { print; exit }
  ' || true)"
  [[ -n "${row}" ]] || return 1
  printf '%s\n' "${row##*$'\t'}"
}

ourbox_selection_resolve_channel_ref() {
  local catalog_dir="$1"
  local channel="$2"
  local catalog_tsv=""
  local catalog_ref=""

  OURBOX_INSTALL_SELECTION_SOURCE=""
  OURBOX_RELEASE_CHANNEL=""
  OURBOX_SELECTED_REF=""
  # shellcheck disable=SC2034  # output state consumed by the sourcing installer
  OURBOX_CATALOG_REF=""

  if [[ "${OS_CATALOG_ENABLED:-1}" != "1" ]]; then
    ourbox_selection_log "OS catalog browsing is disabled; no catalog-backed default is available."
    return 1
  fi

  if ! ourbox_selection_pull_catalog "${catalog_dir}"; then
    ourbox_selection_log "Catalog unavailable for ${OS_REPO}:${OS_CATALOG_TAG}."
    return 1
  fi

  catalog_tsv="${catalog_dir}/catalog.tsv"
  catalog_ref="$(ourbox_selection_catalog_newest_ref "${catalog_tsv}" "${channel}" || true)"
  if ! ourbox_selection_is_digest_pinned_ref "${catalog_ref}"; then
    ourbox_selection_log "Catalog has no valid digest-pinned entry for channel '${channel}'."
    return 1
  fi

  OURBOX_INSTALL_SELECTION_SOURCE="catalog"
  OURBOX_RELEASE_CHANNEL="${channel}"
  OURBOX_SELECTED_REF="${catalog_ref}"
  return 0
}

ourbox_selection_determine_default_ref() {
  local catalog_dir="$1"

  OURBOX_INSTALL_SELECTION_SOURCE=""
  OURBOX_RELEASE_CHANNEL=""
  OURBOX_SELECTED_REF=""
  # shellcheck disable=SC2034  # output state consumed by the sourcing installer
  OURBOX_CATALOG_REF=""

  if [[ -n "${OS_REF:-}" ]]; then
    OURBOX_INSTALL_SELECTION_SOURCE="os-ref"
    OURBOX_SELECTED_REF="${OS_REF}"
    return 0
  fi

  ourbox_selection_resolve_channel_ref "${catalog_dir}" "${OS_CHANNEL}"
}

ourbox_selection_show_default_choice() {
  local ref="$1"
  local default_available="${2:-1}"

  echo
  if [[ "${OURBOX_INSTALL_DEFAULTS_SOURCE:-}" == "remote" ]]; then
    echo "Install defaults: remote (${INSTALL_DEFAULTS_REF:-})"
    echo "Profile        : ${OURBOX_INSTALL_DEFAULTS_PROFILE:-}"
  elif [[ -n "${INSTALL_DEFAULTS_REF:-}" ]]; then
    echo "Install defaults: not loaded (${INSTALL_DEFAULTS_REF})"
  else
    echo "Install defaults: caller-supplied local config"
  fi
  echo "Default source : ${OURBOX_INSTALL_SELECTION_SOURCE:-unavailable}"
  if [[ "${default_available}" == "1" ]]; then
    echo "Default: install '${ref}'"
  else
    echo "Default: unavailable without a matching catalog row or explicit ref"
  fi
  echo "Options:"
  if [[ "${default_available}" == "1" ]]; then
    echo "  [ENTER] Use default"
  fi
  echo "  c       Choose channel (requires a matching catalog row for that lane)"
  echo "  l       List from catalog (if available)"
  echo "  r       Enter custom OCI ref (tag or digest)"
  echo "  o       Override OS repo (custom registry/fork)"
  echo "  q       Quit"
  echo
}

ourbox_selection_override_repo_interactive() {
  local next_repo=""
  local next_catalog="${OS_TARGET}-catalog"
  local user_catalog=""

  read -r -p "Enter OCI repo (e.g., ghcr.io/org/ourbox-os): " next_repo
  [[ -n "${next_repo}" ]] || {
    ourbox_selection_log "Repository cannot be empty."
    return 1
  }

  OS_REPO="${next_repo}"

  OS_REF=""

  read -r -p "Catalog tag [${next_catalog}]: " user_catalog
  if [[ -n "${user_catalog}" ]]; then
    OS_CATALOG_TAG="${user_catalog}"
  else
    OS_CATALOG_TAG="${next_catalog}"
  fi

  ourbox_selection_log "OS repo override set to ${OS_REPO}"
}

ourbox_selection_choose_channel_interactive() {
  local catalog_dir="$1"
  local pick=""

  echo "Channels:"
  echo "  1) stable (recommended)"
  echo "  2) beta"
  echo "  3) nightly"
  echo "  4) exp-labs"

  read -r -p "Select channel [1-4]: " pick
  case "${pick}" in
    1|"")
      ourbox_selection_resolve_channel_ref "${catalog_dir}" "stable"
      ;;
    2)
      ourbox_selection_resolve_channel_ref "${catalog_dir}" "beta"
      ;;
    3)
      ourbox_selection_resolve_channel_ref "${catalog_dir}" "nightly"
      ;;
    4)
      ourbox_selection_resolve_channel_ref "${catalog_dir}" "exp-labs"
      ;;
    *)
      ourbox_selection_log "Invalid choice."
      return 1
      ;;
  esac
}

ourbox_selection_select_from_catalog_interactive() {
  local catalog_dir="$1"
  local catalog_tsv=""
  local pick=""
  local chosen=""
  local normalized_channel=""
  local channel=""
  local tag=""
  local created=""
  local version=""
  local pinned_ref=""
  local i=1
  local -a entries=()

  OURBOX_CATALOG_REF=""
  ourbox_selection_pull_catalog "${catalog_dir}" || {
    ourbox_selection_log "Catalog unavailable; skipping list."
    return 1
  }

  catalog_tsv="${catalog_dir}/catalog.tsv"
  mapfile -t entries < <(ourbox_selection_catalog_entries "${catalog_tsv}")
  if [[ "${#entries[@]}" -eq 0 ]]; then
    ourbox_selection_log "Catalog pulled (${OURBOX_CATALOG_REF}) but contained no entries."
    return 1
  fi

  echo
  echo "Catalog entries (${OURBOX_CATALOG_REF}):"
  for chosen in "${entries[@]}"; do
    IFS=$'\t' read -r channel tag created version pinned_ref <<<"${chosen}"
    printf "  %d) %-12s %-30s %s %s\n" "${i}" "${channel}" "${tag}" "${version}" "${created}"
    i=$((i + 1))
  done

  read -r -p "Choose entry [1-${#entries[@]}] (or ENTER to cancel): " pick
  [[ -n "${pick}" ]] || return 1
  [[ "${pick}" =~ ^[0-9]+$ ]] || {
    ourbox_selection_log "Invalid selection."
    return 1
  }
  if (( pick < 1 || pick > ${#entries[@]} )); then
    ourbox_selection_log "Selection out of range."
    return 1
  fi

  chosen="${entries[$((pick - 1))]}"
  IFS=$'\t' read -r channel tag created version pinned_ref <<<"${chosen}"
  normalized_channel="$(ourbox_selection_normalize_release_channel "${channel}")"
  OURBOX_SELECTED_REF="${pinned_ref}"
  OURBOX_INSTALL_SELECTION_SOURCE="catalog"
  OURBOX_RELEASE_CHANNEL="${normalized_channel}"
  ourbox_selection_log "Selected ${OURBOX_SELECTED_REF} (channel=${normalized_channel}, version=${version})"
}

ourbox_selection_prompt_custom_ref_interactive() {
  local ref=""

  read -r -p "Enter full OCI ref (e.g., repo:tag or repo@sha256:...): " ref
  ourbox_selection_is_clean_single_line_ref "${ref}" || {
    ourbox_selection_log "Ref must be a single-line OCI ref without whitespace."
    return 1
  }

  OURBOX_SELECTED_REF="${ref}"
  OURBOX_INSTALL_SELECTION_SOURCE="operator-override"
  OURBOX_RELEASE_CHANNEL=""
}

ourbox_selection_interactive_select_ref() {
  local catalog_root="$1"
  local default_catalog_dir="${catalog_root}/default"
  local channel_catalog_dir="${catalog_root}/channel"
  local list_catalog_dir="${catalog_root}/list"
  local choice=""
  local default_ref=""
  local default_source=""
  local default_channel=""
  local default_available="0"

  OURBOX_SELECTED_REF=""
  OURBOX_INSTALL_SELECTION_SOURCE=""
  OURBOX_RELEASE_CHANNEL=""

  while [[ -z "${OURBOX_SELECTED_REF}" ]]; do
    if ourbox_selection_determine_default_ref "${default_catalog_dir}"; then
      default_ref="${OURBOX_SELECTED_REF}"
      default_source="${OURBOX_INSTALL_SELECTION_SOURCE}"
      default_channel="${OURBOX_RELEASE_CHANNEL}"
      default_available="1"
    else
      default_ref=""
      default_source=""
      default_channel=""
      default_available="0"
    fi
    OURBOX_SELECTED_REF=""

    ourbox_selection_show_default_choice "${default_ref}" "${default_available}"
    read -r -p "Choice: " choice

    case "${choice}" in
      "")
        if [[ "${default_available}" == "1" ]]; then
          OURBOX_SELECTED_REF="${default_ref}"
          OURBOX_INSTALL_SELECTION_SOURCE="${default_source}"
          OURBOX_RELEASE_CHANNEL="${default_channel}"
        else
          ourbox_selection_log "No catalog-backed default is available. Choose c, l, r, o, or q."
        fi
        ;;
      c)
        ourbox_selection_choose_channel_interactive "${channel_catalog_dir}" || true
        ;;
      l)
        ourbox_selection_select_from_catalog_interactive "${list_catalog_dir}" || true
        ;;
      r)
        ourbox_selection_prompt_custom_ref_interactive || true
        ;;
      o)
        ourbox_selection_override_repo_interactive || true
        ;;
      q|Q)
        ourbox_selection_die "Install aborted by user"
        ;;
      *)
        ourbox_selection_log "Unknown option."
        ;;
    esac
  done
}

ourbox_selection_ref_repo_base() {
  local ref="$1"
  local tail="${ref##*/}"

  if [[ "${ref}" == *@* ]]; then
    printf '%s\n' "${ref%%@*}"
    return 0
  fi

  # Registry ports live before the last slash and must be preserved. Only the
  # tag separator in the final path segment should be removed here.
  if [[ "${tail}" == *:* ]]; then
    printf '%s\n' "${ref%:*}"
  else
    printf '%s\n' "${ref}"
  fi
}

ourbox_selection_finalize_registry_ref_common() {
  local selected_ref="$1"
  local selected_ref_var="$2"
  local pull_ref_var="$3"
  local artifact_source_var="$4"
  local artifact_ref_var="$5"
  local artifact_digest_var="$6"
  local label="${7:-artifact}"
  local selected_ref_q=""
  local resolved_digest=""
  local repo_base=""

  if ! ourbox_selection_is_clean_single_line_ref "${selected_ref}"; then
    printf -v selected_ref_q '%q' "${selected_ref}"
    ourbox_selection_die "invalid selected ${label} ref (must be non-empty, single-line, no whitespace): ${selected_ref_q}"
  fi

  ourbox_selection_need_cmd oras

  printf -v "${selected_ref_var}" '%s' "${selected_ref}"
  printf -v "${pull_ref_var}" '%s' "${selected_ref}"
  printf -v "${artifact_source_var}" '%s' "registry"
  printf -v "${artifact_ref_var}" '%s' "${selected_ref}"
  printf -v "${artifact_digest_var}" '%s' ""

  if ourbox_selection_is_digest_pinned_ref "${selected_ref}"; then
    printf -v "${artifact_digest_var}" '%s' "${selected_ref##*@}"
    return 0
  fi

  ourbox_selection_log "Resolving to immutable digest: ${selected_ref}"
  if resolved_digest="$(oras resolve "${selected_ref}" 2>/dev/null)" \
    && [[ "${resolved_digest}" =~ ^sha256:[0-9a-f]{64}$ ]]; then
    printf -v "${artifact_digest_var}" '%s' "${resolved_digest}"
    repo_base="$(ourbox_selection_ref_repo_base "${selected_ref}")"
    printf -v "${pull_ref_var}" '%s' "${repo_base}@${resolved_digest}"
    ourbox_selection_log "Resolved: ${resolved_digest}"
    return 0
  fi

  if [[ "${OURBOX_ALLOW_UNRESOLVED_PULL:-0}" == "1" ]]; then
    ourbox_selection_log "WARNING: oras resolve failed; pulling by tag (OURBOX_ALLOW_UNRESOLVED_PULL=1)"
    ourbox_selection_log "WARNING: artifact identity will not be captured in provenance"
    printf -v "${artifact_digest_var}" '%s' "unresolved"
    printf -v "${pull_ref_var}" '%s' "${selected_ref}"
    return 0
  fi

  ourbox_selection_die "Cannot establish ${label} identity: oras resolve failed for ${selected_ref}
  The installer requires a digest-pinned artifact ref to ensure provenance.
  Options:
    1. Use a digest-pinned ref (catalog or explicit pinned ref usually provides this)
    2. Check registry connectivity and retry
    3. Set OURBOX_ALLOW_UNRESOLVED_PULL=1 to skip this check (dev/testing only)"
}

ourbox_selection_finalize_registry_ref() {
  local selected_ref="$1"
  ourbox_selection_finalize_registry_ref_common \
    "${selected_ref}" \
    OURBOX_SELECTED_REF \
    OURBOX_PULL_REF \
    OURBOX_OS_ARTIFACT_SOURCE \
    OURBOX_OS_ARTIFACT_REF \
    OURBOX_OS_ARTIFACT_DIGEST \
    "OS artifact"
}

ourbox_substrate_selection_require_context() {
  [[ -n "${OURBOX_SUBSTRATE_REPO:-}" ]] || ourbox_selection_die "OURBOX_SUBSTRATE_REPO is required for ourbox-substrate selection"
  [[ "${OURBOX_SUBSTRATE_ARCH:-}" =~ ^(arm64|amd64)$ ]] || ourbox_selection_die "OURBOX_SUBSTRATE_ARCH must be arm64 or amd64 for ourbox-substrate selection"
  [[ -n "${OURBOX_SUBSTRATE_CHANNEL:-}" ]] || ourbox_selection_die "OURBOX_SUBSTRATE_CHANNEL is required for ourbox-substrate selection"
}

ourbox_substrate_selection_pull_catalog() {
  local dst="$1"
  local ref="${OURBOX_SUBSTRATE_REPO}:${OURBOX_SUBSTRATE_CATALOG_TAG}"

  if [[ "${OURBOX_SUBSTRATE_CATALOG_ENABLED:-1}" != "1" ]]; then
    return 1
  fi

  ourbox_selection_need_cmd oras
  rm -rf "${dst}"
  mkdir -p "${dst}"

  ourbox_selection_log "Pulling substrate catalog: ${ref}"
  if ! oras pull "${ref}" -o "${dst}" >/dev/null 2>&1; then
    return 1
  fi
  [[ -f "${dst}/catalog.tsv" ]] || return 1

  OURBOX_SUBSTRATE_CATALOG_REF="${ref}"
  return 0
}

ourbox_substrate_catalog_entries() {
  local catalog_tsv="$1"
  [[ -f "${catalog_tsv}" ]] || return 1

  awk -F'\t' '
    NR == 1 {
      for (i = 1; i <= NF; i++) {
        idx[$i] = i
      }
      if (!idx["channel"] || !idx["tag"] || !idx["created"] || !idx["version"] || !idx["revision"] || !idx["arch"] || !idx["platform_profile"] || !idx["k3s_version"] || !idx["platform_images_lock_sha256"] || !idx["artifact_digest"] || !idx["pinned_ref"]) {
        exit 0
      }
      next
    }
    {
      created = $(idx["created"])
      arch = $(idx["arch"])
      lock_sha = $(idx["platform_images_lock_sha256"])
      digest = $(idx["artifact_digest"])
      pinned = $(idx["pinned_ref"])
      if (created == "" || arch == "") {
        next
      }
      if (arch !~ /^(arm64|amd64)$/) {
        next
      }
      if (lock_sha !~ /^[0-9a-f]{64}$/) {
        next
      }
      if (digest !~ /^sha256:[0-9a-f]{64}$/) {
        next
      }
      if (pinned !~ /^[^[:space:]]+@sha256:[0-9a-f]{64}$/) {
        next
      }
      print $(idx["channel"]) "\t" $(idx["tag"]) "\t" created "\t" $(idx["version"]) "\t" $(idx["revision"]) "\t" arch "\t" $(idx["platform_profile"]) "\t" $(idx["k3s_version"]) "\t" $(idx["platform_images_lock_sha256"]) "\t" digest "\t" pinned
    }
  ' "${catalog_tsv}" | sort -t $'\t' -k3,3r -k2,2r
}

ourbox_substrate_catalog_newest_ref() {
  local catalog_tsv="$1"
  local channel="$2"
  local required_arch="$3"
  local row=""

  row="$(ourbox_substrate_catalog_entries "${catalog_tsv}" | awk -F'\t' -v ch="${channel}" -v arch="${required_arch}" '
    $1 == ch && $6 == arch { print; exit }
  ' || true)"
  [[ -n "${row}" ]] || return 1
  printf '%s\n' "${row##*$'\t'}"
}

ourbox_substrate_determine_channel_ref() {
  local catalog_dir="$1"
  local channel="${2:-${OURBOX_SUBSTRATE_CHANNEL}}"
  local catalog_tsv=""
  local catalog_ref=""

  ourbox_substrate_selection_require_context

  OURBOX_SUBSTRATE_INSTALL_SELECTION_SOURCE=""
  OURBOX_SUBSTRATE_RELEASE_CHANNEL=""
  OURBOX_SUBSTRATE_SELECTED_REF=""
  OURBOX_SUBSTRATE_CATALOG_REF=""

  if [[ "${OURBOX_SUBSTRATE_CATALOG_ENABLED:-1}" != "1" ]]; then
    ourbox_selection_log "Substrate catalog browsing is disabled; no catalog-backed substrate default is available."
    return 1
  fi

  if ! ourbox_substrate_selection_pull_catalog "${catalog_dir}"; then
    ourbox_selection_log "Substrate catalog unavailable for ${OURBOX_SUBSTRATE_REPO}:${OURBOX_SUBSTRATE_CATALOG_TAG}."
    return 1
  fi

  catalog_tsv="${catalog_dir}/catalog.tsv"
  catalog_ref="$(ourbox_substrate_catalog_newest_ref "${catalog_tsv}" "${channel}" "${OURBOX_SUBSTRATE_ARCH:-}" || true)"
  if ! ourbox_selection_is_digest_pinned_ref "${catalog_ref}"; then
    ourbox_selection_log "Substrate catalog has no valid digest-pinned entry for channel '${channel}'."
    return 1
  fi

  OURBOX_SUBSTRATE_INSTALL_SELECTION_SOURCE="catalog"
  OURBOX_SUBSTRATE_RELEASE_CHANNEL="${channel}"
  OURBOX_SUBSTRATE_SELECTED_REF="${catalog_ref}"
  return 0
}

ourbox_substrate_determine_default_ref() {
  local catalog_dir="$1"

  ourbox_substrate_selection_require_context

  OURBOX_SUBSTRATE_INSTALL_SELECTION_SOURCE=""
  OURBOX_SUBSTRATE_RELEASE_CHANNEL=""
  OURBOX_SUBSTRATE_SELECTED_REF=""
  OURBOX_SUBSTRATE_CATALOG_REF=""

  if [[ -n "${OURBOX_SUBSTRATE_REF:-}" ]]; then
    OURBOX_SUBSTRATE_INSTALL_SELECTION_SOURCE="ourbox-substrate-ref"
    OURBOX_SUBSTRATE_SELECTED_REF="${OURBOX_SUBSTRATE_REF}"
    return 0
  fi

  ourbox_substrate_determine_channel_ref "${catalog_dir}" "${OURBOX_SUBSTRATE_CHANNEL}"
}

ourbox_substrate_selection_show_default_choice() {
  local ref="$1"
  local default_available="${2:-1}"

  echo
  if [[ "${OURBOX_INSTALL_DEFAULTS_SOURCE:-}" == "remote" ]]; then
    echo "Install defaults: remote (${INSTALL_DEFAULTS_REF:-})"
    echo "Profile        : ${OURBOX_INSTALL_DEFAULTS_PROFILE:-}"
  elif [[ -n "${INSTALL_DEFAULTS_REF:-}" ]]; then
    echo "Install defaults: not loaded (${INSTALL_DEFAULTS_REF})"
  else
    echo "Install defaults: caller-supplied local config"
  fi
  echo "Default source : ${OURBOX_SUBSTRATE_INSTALL_SELECTION_SOURCE:-unavailable}"
  if [[ "${default_available}" == "1" ]]; then
    echo "Default: use substrate bundle '${ref}'"
  else
    echo "Default: unavailable without a matching catalog row or explicit ref"
  fi
  echo "Options:"
  if [[ "${default_available}" == "1" ]]; then
    echo "  [ENTER] Use default"
  fi
  echo "  c       Choose channel (prefers newest catalog row for that lane)"
  echo "  l       List from catalog (if available)"
  echo "  r       Enter custom OCI ref (tag or digest)"
  echo "  o       Override substrate repo (custom registry/fork)"
  echo "  q       Quit"
  echo
}

ourbox_substrate_selection_override_repo_interactive() {
  local next_repo=""
  local next_catalog="catalog-${OURBOX_SUBSTRATE_ARCH}"
  local user_catalog=""

  read -r -p "Enter OCI repo (e.g., ghcr.io/org/ourbox-substrate): " next_repo
  [[ -n "${next_repo}" ]] || {
    ourbox_selection_log "Repository cannot be empty."
    return 1
  }

  OURBOX_SUBSTRATE_REPO="${next_repo}"
  OURBOX_SUBSTRATE_REF=""

  read -r -p "Catalog tag [${next_catalog}]: " user_catalog
  if [[ -n "${user_catalog}" ]]; then
    OURBOX_SUBSTRATE_CATALOG_TAG="${user_catalog}"
  else
    OURBOX_SUBSTRATE_CATALOG_TAG="${next_catalog}"
  fi

  ourbox_selection_log "Substrate repo override set to ${OURBOX_SUBSTRATE_REPO}"
}

ourbox_substrate_selection_choose_channel_interactive() {
  local catalog_dir="$1"
  local pick=""

  echo "Channels:"
  echo "  1) stable (recommended)"
  echo "  2) beta"
  echo "  3) nightly"
  echo "  4) exp-labs"

  read -r -p "Select channel [1-4]: " pick
  case "${pick}" in
    1|"") OURBOX_SUBSTRATE_CHANNEL="stable" ;;
    2) OURBOX_SUBSTRATE_CHANNEL="beta" ;;
    3) OURBOX_SUBSTRATE_CHANNEL="nightly" ;;
    4) OURBOX_SUBSTRATE_CHANNEL="exp-labs" ;;
    *)
      ourbox_selection_log "Invalid choice."
      return 1
      ;;
  esac

  ourbox_substrate_determine_channel_ref "${catalog_dir}" "${OURBOX_SUBSTRATE_CHANNEL}"
}

ourbox_substrate_selection_select_from_catalog_interactive() {
  local catalog_dir="$1"
  local catalog_tsv=""
  local pick=""
  local chosen=""
  local channel=""
  local tag=""
  local created=""
  local version=""
  local _revision=""
  local _arch=""
  local profile=""
  local _k3s_version=""
  local _lock_sha=""
  local _artifact_digest=""
  local pinned_ref=""
  local i=1
  local -a entries=()

  OURBOX_SUBSTRATE_CATALOG_REF=""
  ourbox_substrate_selection_pull_catalog "${catalog_dir}" || {
    ourbox_selection_log "Substrate catalog unavailable; skipping list."
    return 1
  }

  catalog_tsv="${catalog_dir}/catalog.tsv"
  mapfile -t entries < <(ourbox_substrate_catalog_entries "${catalog_tsv}" | awk -F'\t' -v arch="${OURBOX_SUBSTRATE_ARCH:-}" '
    $6 == arch { print }
  ')
  if [[ "${#entries[@]}" -eq 0 ]]; then
    ourbox_selection_log "Substrate catalog pulled (${OURBOX_SUBSTRATE_CATALOG_REF}) but contained no matching rows for arch=${OURBOX_SUBSTRATE_ARCH:-unknown}."
    return 1
  fi

  echo
  echo "Substrate catalog entries (${OURBOX_SUBSTRATE_CATALOG_REF}):"
  for chosen in "${entries[@]}"; do
    IFS=$'\t' read -r channel tag created version _revision _arch profile _k3s_version _lock_sha _artifact_digest pinned_ref <<<"${chosen}"
    printf "  %d) %-10s %-24s %s %s\n" "${i}" "${channel}" "${tag}" "${version}" "${created}"
    i=$((i + 1))
  done

  read -r -p "Choose entry [1-${#entries[@]}] (or ENTER to cancel): " pick
  [[ -n "${pick}" ]] || return 1
  [[ "${pick}" =~ ^[0-9]+$ ]] || {
    ourbox_selection_log "Invalid selection."
    return 1
  }
  if (( pick < 1 || pick > ${#entries[@]} )); then
    ourbox_selection_log "Selection out of range."
    return 1
  fi

  chosen="${entries[$((pick - 1))]}"
  IFS=$'\t' read -r channel tag created version _revision _arch profile _k3s_version _lock_sha _artifact_digest pinned_ref <<<"${chosen}"
  OURBOX_SUBSTRATE_SELECTED_REF="${pinned_ref}"
  OURBOX_SUBSTRATE_INSTALL_SELECTION_SOURCE="catalog"
  OURBOX_SUBSTRATE_RELEASE_CHANNEL="${channel}"
  ourbox_selection_log "Selected ${OURBOX_SUBSTRATE_SELECTED_REF} (channel=${channel}, version=${version})"
}

ourbox_substrate_selection_prompt_custom_ref_interactive() {
  local ref=""

  read -r -p "Enter full OCI ref (e.g., repo:tag or repo@sha256:...): " ref
  ourbox_selection_is_clean_single_line_ref "${ref}" || {
    ourbox_selection_log "Ref must be a single-line OCI ref without whitespace."
    return 1
  }

  OURBOX_SUBSTRATE_SELECTED_REF="${ref}"
  OURBOX_SUBSTRATE_INSTALL_SELECTION_SOURCE="operator-override"
  OURBOX_SUBSTRATE_RELEASE_CHANNEL=""
}

ourbox_substrate_selection_interactive_select_ref() {
  local catalog_root="$1"
  local default_catalog_dir="${catalog_root}/default"
  local channel_catalog_dir="${catalog_root}/channel"
  local list_catalog_dir="${catalog_root}/list"
  local choice=""
  local default_ref=""
  local default_source=""
  local default_channel=""
  local default_available="0"

  OURBOX_SUBSTRATE_SELECTED_REF=""
  OURBOX_SUBSTRATE_INSTALL_SELECTION_SOURCE=""
  OURBOX_SUBSTRATE_RELEASE_CHANNEL=""

  while [[ -z "${OURBOX_SUBSTRATE_SELECTED_REF}" ]]; do
    if ourbox_substrate_determine_default_ref "${default_catalog_dir}"; then
      default_ref="${OURBOX_SUBSTRATE_SELECTED_REF}"
      default_source="${OURBOX_SUBSTRATE_INSTALL_SELECTION_SOURCE}"
      default_channel="${OURBOX_SUBSTRATE_RELEASE_CHANNEL}"
      default_available="1"
    else
      default_ref=""
      default_source=""
      default_channel=""
      default_available="0"
    fi
    OURBOX_SUBSTRATE_SELECTED_REF=""

    ourbox_substrate_selection_show_default_choice "${default_ref}" "${default_available}"
    read -r -p "Choice: " choice

    case "${choice}" in
      "")
        if [[ "${default_available}" == "1" ]]; then
          OURBOX_SUBSTRATE_SELECTED_REF="${default_ref}"
          OURBOX_SUBSTRATE_INSTALL_SELECTION_SOURCE="${default_source}"
          OURBOX_SUBSTRATE_RELEASE_CHANNEL="${default_channel}"
        else
          ourbox_selection_log "No catalog-backed default is available. Choose c, l, r, o, or q."
        fi
        ;;
      c)
        ourbox_substrate_selection_choose_channel_interactive "${channel_catalog_dir}" || true
        ;;
      l)
        ourbox_substrate_selection_select_from_catalog_interactive "${list_catalog_dir}" || true
        ;;
      r)
        ourbox_substrate_selection_prompt_custom_ref_interactive || true
        ;;
      o)
        ourbox_substrate_selection_override_repo_interactive || true
        ;;
      q|Q)
        ourbox_selection_die "Install aborted by user"
        ;;
      *)
        ourbox_selection_log "Unknown option."
        ;;
    esac
  done
}

ourbox_substrate_selection_finalize_registry_ref() {
  local selected_ref="$1"
  ourbox_selection_finalize_registry_ref_common \
    "${selected_ref}" \
    OURBOX_SUBSTRATE_SELECTED_REF \
    OURBOX_SUBSTRATE_PULL_REF \
    OURBOX_SUBSTRATE_ARTIFACT_SOURCE \
    OURBOX_SUBSTRATE_ARTIFACT_REF \
    OURBOX_SUBSTRATE_ARTIFACT_DIGEST \
    "ourbox-substrate artifact"
}

ourbox_substrate_selection_validate_extracted_bundle() {
  local bundle_dir="$1"
  local expected_arch="$2"
  local manifest="${bundle_dir}/manifest.env"
  local k3s_images_tar="${bundle_dir}/k3s/k3s-airgap-images-${expected_arch}.tar"
  local manifest_substrate_source=""
  local manifest_substrate_revision=""
  local manifest_substrate_version=""
  local manifest_substrate_created=""
  local manifest_substrate_arch=""
  local manifest_k3s_version=""
  local manifest_platform_profile=""
  local manifest_platform_images_lock_path=""
  local manifest_platform_images_lock_sha256=""
  local manifest_dump=""
  local -a manifest_fields=()

  [[ -f "${manifest}" ]] || ourbox_selection_die "ourbox-substrate bundle missing manifest.env: ${manifest}"
  [[ -x "${bundle_dir}/k3s/k3s" ]] || ourbox_selection_die "ourbox-substrate bundle missing k3s binary: ${bundle_dir}/k3s/k3s"
  [[ -f "${k3s_images_tar}" ]] || ourbox_selection_die "ourbox-substrate bundle missing k3s airgap images tar: ${k3s_images_tar}"
  [[ -f "${bundle_dir}/platform/images.lock.json" ]] || ourbox_selection_die "ourbox-substrate bundle missing platform/images.lock.json"
  [[ -f "${bundle_dir}/platform/profile.env" ]] || ourbox_selection_die "ourbox-substrate bundle missing platform/profile.env"
  [[ -d "${bundle_dir}/platform/images" ]] || ourbox_selection_die "ourbox-substrate bundle missing platform/images directory"
  find "${bundle_dir}/platform/images" -maxdepth 1 -type f -name '*.tar' -print -quit | grep -q . \
    || ourbox_selection_die "ourbox-substrate bundle missing platform image tar payloads: ${bundle_dir}/platform/images"

  manifest_dump="$(
    (
      unset OURBOX_SUBSTRATE_SOURCE OURBOX_SUBSTRATE_REVISION OURBOX_SUBSTRATE_VERSION
      unset OURBOX_SUBSTRATE_CREATED OURBOX_SUBSTRATE_ARCH
      unset K3S_VERSION OURBOX_PLATFORM_PROFILE OURBOX_PLATFORM_IMAGES_LOCK_PATH OURBOX_PLATFORM_IMAGES_LOCK_SHA256
      # shellcheck disable=SC1090
      source "${manifest}"
      printf '%s\n' \
        "${OURBOX_SUBSTRATE_SOURCE-}" \
        "${OURBOX_SUBSTRATE_REVISION-}" \
        "${OURBOX_SUBSTRATE_VERSION-}" \
        "${OURBOX_SUBSTRATE_CREATED-}" \
        "${OURBOX_SUBSTRATE_ARCH-}" \
        "${K3S_VERSION-}" \
        "${OURBOX_PLATFORM_PROFILE-}" \
        "${OURBOX_PLATFORM_IMAGES_LOCK_PATH-}" \
        "${OURBOX_PLATFORM_IMAGES_LOCK_SHA256-}" \
        "__OURBOX_SUBSTRATE_MANIFEST_END__"
    )
  )" || ourbox_selection_die "failed to parse ourbox-substrate manifest: ${manifest}"
  mapfile -t manifest_fields <<<"${manifest_dump}"
  [[ "${#manifest_fields[@]}" -eq 10 && "${manifest_fields[9]}" == "__OURBOX_SUBSTRATE_MANIFEST_END__" ]] \
    || ourbox_selection_die "ourbox-substrate manifest parse produced an unexpected field set: ${manifest}"
  manifest_substrate_source="${manifest_fields[0]}"
  manifest_substrate_revision="${manifest_fields[1]}"
  manifest_substrate_version="${manifest_fields[2]}"
  manifest_substrate_created="${manifest_fields[3]}"
  manifest_substrate_arch="${manifest_fields[4]}"
  manifest_k3s_version="${manifest_fields[5]}"
  manifest_platform_profile="${manifest_fields[6]}"
  manifest_platform_images_lock_path="${manifest_fields[7]}"
  manifest_platform_images_lock_sha256="${manifest_fields[8]}"

  [[ -n "${manifest_substrate_source}" ]] || ourbox_selection_die "ourbox-substrate manifest missing OURBOX_SUBSTRATE_SOURCE"
  [[ -n "${manifest_substrate_revision}" ]] || ourbox_selection_die "ourbox-substrate manifest missing OURBOX_SUBSTRATE_REVISION"
  [[ -n "${manifest_substrate_version}" ]] || ourbox_selection_die "ourbox-substrate manifest missing OURBOX_SUBSTRATE_VERSION"
  [[ -n "${manifest_substrate_created}" ]] || ourbox_selection_die "ourbox-substrate manifest missing OURBOX_SUBSTRATE_CREATED"
  [[ "${manifest_substrate_arch}" == "${expected_arch}" ]] || ourbox_selection_die "ourbox-substrate bundle arch mismatch: expected ${expected_arch}, got ${manifest_substrate_arch:-unknown}"
  [[ -n "${manifest_k3s_version}" ]] || ourbox_selection_die "ourbox-substrate manifest missing K3S_VERSION"
  [[ -n "${manifest_platform_profile}" ]] || ourbox_selection_die "ourbox-substrate manifest missing OURBOX_PLATFORM_PROFILE"
  [[ -n "${manifest_platform_images_lock_path}" ]] || ourbox_selection_die "ourbox-substrate manifest missing OURBOX_PLATFORM_IMAGES_LOCK_PATH"
  [[ "${manifest_platform_images_lock_sha256}" =~ ^[0-9a-f]{64}$ ]] || ourbox_selection_die "ourbox-substrate manifest carries invalid OURBOX_PLATFORM_IMAGES_LOCK_SHA256"

  export OURBOX_SUBSTRATE_SOURCE="${manifest_substrate_source}"
  export OURBOX_SUBSTRATE_REVISION="${manifest_substrate_revision}"
  export OURBOX_SUBSTRATE_VERSION="${manifest_substrate_version}"
  export OURBOX_SUBSTRATE_CREATED="${manifest_substrate_created}"
  export OURBOX_SUBSTRATE_ARCH="${manifest_substrate_arch}"
  export OURBOX_SUBSTRATE_PROFILE="${manifest_platform_profile}"
  export OURBOX_SUBSTRATE_K3S_VERSION="${manifest_k3s_version}"
  export OURBOX_SUBSTRATE_IMAGES_LOCK_SHA256="${manifest_platform_images_lock_sha256}"
}
