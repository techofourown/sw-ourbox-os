#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

log() { echo "[$(date -Is)] $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

validate_file() {
  local file="$1"
  local line_no=0
  local bad=0
  local line=""
  local key=""
  local pattern='^[A-Z][A-Z0-9_]*=[A-Za-z0-9_./:@%+,=-]*$'

  [[ -f "${file}" ]] || die "Missing install-defaults file: ${file}"

  while IFS= read -r line || [[ -n "${line}" ]]; do
    line_no=$((line_no + 1))
    if [[ "${line}" =~ ^[[:space:]]*$ ]] || [[ "${line}" =~ ^[[:space:]]*# ]]; then
      continue
    fi
    key="${line%%=*}"
    if [[ "${key}" == OURBOX_INSTALLER_SSH_* ]]; then
      printf '%s:%d: installer SSH keys are out of scope for install-defaults: %s\n' \
        "${file}" "${line_no}" "${line}" >&2
      bad=1
      continue
    fi
    if [[ "${line}" =~ ${pattern} ]]; then
      continue
    fi
    printf '%s:%d: invalid install-defaults line (must be assignment-only KEY=VALUE data): %s\n' \
      "${file}" "${line_no}" "${line}" >&2
    bad=1
  done < "${file}"

  return "${bad}"
}

main() {
  local target=""
  local failed=0
  local -a targets=()

  if [[ "$#" -gt 0 ]]; then
    targets=("$@")
  else
    targets=(
      "${ROOT}/install-defaults/schema.env"
      "${ROOT}/install-defaults/defaults/"*.env
    )
  fi

  for target in "${targets[@]}"; do
    if ! validate_file "${target}"; then
      failed=1
    fi
  done

  (( failed == 0 )) || exit 1
  log "install-defaults assignment-only validation passed"
}

main "$@"
