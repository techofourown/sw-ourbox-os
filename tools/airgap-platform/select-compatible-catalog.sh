#!/usr/bin/env bash
set -euo pipefail

log() { printf '[%s] %s\n' "$(date -Is)" "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

need_cmd curl
need_cmd oras
need_cmd tar

: "${EXPECTED_CONTRACT_DIGEST:?EXPECTED_CONTRACT_DIGEST is required}"
: "${DEFAULT_CATALOG_REPO:?DEFAULT_CATALOG_REPO is required}"

[[ "${EXPECTED_CONTRACT_DIGEST}" =~ ^sha256:[0-9a-f]{64}$ ]] \
  || die "EXPECTED_CONTRACT_DIGEST must be a sha256 digest"

CATALOG_REFRESH_EVENT_TYPE="${CATALOG_REFRESH_EVENT_TYPE:-refresh-from-upstream-image-publish}"
CATALOG_REFRESH_TIMEOUT_SECONDS="${CATALOG_REFRESH_TIMEOUT_SECONDS:-600}"
CATALOG_REFRESH_POLL_SECONDS="${CATALOG_REFRESH_POLL_SECONDS:-10}"

emit_pinned_ref() {
  local ref="$1"
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    printf 'pinned_ref=%s\n' "${ref}" >> "${GITHUB_OUTPUT}"
  else
    printf '%s\n' "${ref}"
  fi
}

resolve_bound_contract_digest() {
  local ref="$1" tmp pull_dir extract_dir bundle_tar manifest_file manifest_digest
  tmp="$(mktemp -d)"
  pull_dir="${tmp}/pull"
  extract_dir="${tmp}/extract"
  mkdir -p "${pull_dir}" "${extract_dir}"

  oras pull "${ref}" -o "${pull_dir}" >/dev/null
  bundle_tar="$(find "${pull_dir}" -maxdepth 4 -type f -name 'application-catalog-bundle.tar.gz' | head -n1 || true)"
  [[ -f "${bundle_tar}" ]] || {
    rm -rf "${tmp}"
    die "application catalog ref did not contain application-catalog-bundle.tar.gz: ${ref}"
  }

  tar -xzf "${bundle_tar}" -C "${extract_dir}"
  manifest_file="${extract_dir}/manifest.env"
  [[ -f "${manifest_file}" ]] || {
    rm -rf "${tmp}"
    die "application catalog bundle missing manifest.env: ${ref}"
  }

  manifest_digest="$(awk -F= '/^OURBOX_PLATFORM_CONTRACT_DIGEST=/{print $2; exit}' "${manifest_file}")"
  rm -rf "${tmp}"

  [[ "${manifest_digest}" =~ ^sha256:[0-9a-f]{64}$ ]] \
    || die "application catalog ref did not declare a valid OURBOX_PLATFORM_CONTRACT_DIGEST: ${ref}"
  printf '%s\n' "${manifest_digest}"
}

select_catalog_ref() {
  local candidate_ref="$1" manifest_digest
  manifest_digest="$(resolve_bound_contract_digest "${candidate_ref}")"
  if [[ "${manifest_digest}" == "${EXPECTED_CONTRACT_DIGEST}" ]]; then
    log "Using application catalog bundle ${candidate_ref} (bound=${manifest_digest})"
    emit_pinned_ref "${candidate_ref}"
    return 0
  fi
  log "Skipping application catalog bundle ${candidate_ref}: bound=${manifest_digest}, expected=${EXPECTED_CONTRACT_DIGEST}"
  return 1
}

resolve_catalog_repo() {
  local candidate="${ORIGINAL_CATALOG_PINNED_REF:-}"
  if [[ -n "${candidate}" && "${candidate}" == *"@sha256:"* ]]; then
    printf '%s\n' "${candidate%@*}"
    return 0
  fi
  printf '%s\n' "${DEFAULT_CATALOG_REPO}"
}

resolve_latest_ref() {
  local catalog_repo="$1" digest
  digest="$(oras resolve "${catalog_repo}:latest")"
  [[ "${digest}" =~ ^sha256:[0-9a-f]{64}$ ]] \
    || die "catalog latest tag did not resolve to a valid digest: ${catalog_repo}:latest -> ${digest}"
  printf '%s@%s\n' "${catalog_repo}" "${digest}"
}

github_repo_from_oci_repo() {
  local oci_repo="$1" repo_path owner repo

  repo_path="${oci_repo}"
  if [[ "${oci_repo}" == */*/* ]]; then
    repo_path="${oci_repo#*/}"
  fi
  IFS='/' read -r owner repo _ <<< "${repo_path}"
  [[ -n "${owner}" && -n "${repo}" ]] || die "unable to derive GitHub repo from OCI repo: ${oci_repo}"
  printf '%s/%s\n' "${owner}" "${repo}"
}

dispatch_catalog_refresh() {
  local catalog_repo="$1" github_repo response_file status payload

  [[ -n "${CATALOG_REPO_DISPATCH_TOKEN:-}" ]] \
    || die "CATALOG_REPO_DISPATCH_TOKEN is required to refresh a stale application catalog bundle"

  github_repo="$(github_repo_from_oci_repo "${catalog_repo}")"
  response_file="$(mktemp)"
  payload="$(printf '{"event_type":"%s","client_payload":{"platform_contract_digest":"%s","source_repo":"%s","source_sha":"%s"}}' \
    "${CATALOG_REFRESH_EVENT_TYPE}" \
    "${EXPECTED_CONTRACT_DIGEST}" \
    "${GITHUB_REPOSITORY:-unknown}" \
    "${GITHUB_SHA:-unknown}")"

  log "Requesting catalog refresh in ${github_repo} for contract ${EXPECTED_CONTRACT_DIGEST}"
  status="$(
    curl -sS \
      -o "${response_file}" \
      -w '%{http_code}' \
      -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${CATALOG_REPO_DISPATCH_TOKEN}" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "https://api.github.com/repos/${github_repo}/dispatches" \
      -d "${payload}"
  )"

  if [[ "${status}" != "204" ]]; then
    cat "${response_file}" >&2 || true
    rm -f "${response_file}"
    die "catalog refresh dispatch failed for ${github_repo} (HTTP ${status})"
  fi

  rm -f "${response_file}"
}

wait_for_matching_catalog() {
  local catalog_repo="$1" deadline latest_ref last_seen_ref=""
  deadline=$((SECONDS + CATALOG_REFRESH_TIMEOUT_SECONDS))

  while true; do
    latest_ref="$(resolve_latest_ref "${catalog_repo}")"
    if [[ "${latest_ref}" != "${last_seen_ref}" ]]; then
      log "Observed ${catalog_repo}:latest as ${latest_ref}"
      last_seen_ref="${latest_ref}"
    fi

    if select_catalog_ref "${latest_ref}"; then
      return 0
    fi

    if (( SECONDS >= deadline )); then
      break
    fi

    sleep "${CATALOG_REFRESH_POLL_SECONDS}"
  done

  die "No compatible application catalog bundle found for contract ${EXPECTED_CONTRACT_DIGEST} in ${catalog_repo} within ${CATALOG_REFRESH_TIMEOUT_SECONDS}s"
}

main() {
  local catalog_repo latest_ref

  if [[ -n "${ORIGINAL_CATALOG_PINNED_REF:-}" ]] && select_catalog_ref "${ORIGINAL_CATALOG_PINNED_REF}"; then
    return 0
  fi

  catalog_repo="$(resolve_catalog_repo)"
  latest_ref="$(resolve_latest_ref "${catalog_repo}")"
  if select_catalog_ref "${latest_ref}"; then
    return 0
  fi

  dispatch_catalog_refresh "${catalog_repo}"
  wait_for_matching_catalog "${catalog_repo}"
}

main "$@"
