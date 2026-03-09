#!/usr/bin/env bash
set -euo pipefail

die() { echo "ERROR: $*" >&2; exit 1; }

CONTRACT_DIR=""
PROFILE=""
BOX_HOST=""
TLS_MODE=""
INGRESS_CLASS=""
STORAGE_CLASS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --contract-dir)
      [[ $# -ge 2 ]] || die "--contract-dir requires a value"
      CONTRACT_DIR="$2"
      shift 2
      ;;
    --profile)
      [[ $# -ge 2 ]] || die "--profile requires a value"
      PROFILE="$2"
      shift 2
      ;;
    --box-host)
      [[ $# -ge 2 ]] || die "--box-host requires a value"
      BOX_HOST="$2"
      shift 2
      ;;
    --tls-mode)
      [[ $# -ge 2 ]] || die "--tls-mode requires a value"
      TLS_MODE="$2"
      shift 2
      ;;
    --ingress-class)
      [[ $# -ge 2 ]] || die "--ingress-class requires a value"
      INGRESS_CLASS="$2"
      shift 2
      ;;
    --storage-class)
      [[ $# -ge 2 ]] || die "--storage-class requires a value"
      STORAGE_CLASS="$2"
      shift 2
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

[[ -n "${CONTRACT_DIR}" ]] || die "--contract-dir is required"
[[ -n "${PROFILE}" ]] || die "--profile is required"
[[ -n "${BOX_HOST}" ]] || die "--box-host is required"
[[ -f "${CONTRACT_DIR}/contract.env" ]] || die "contract.env not found in ${CONTRACT_DIR}"

profile_env="${CONTRACT_DIR}/profiles/${PROFILE}/profile.env"
[[ -f "${profile_env}" ]] || die "profile.env not found for profile ${PROFILE}"

env_value() {
  local file="$1"
  local wanted_key="$2"
  local key value
  while IFS='=' read -r key value; do
    [[ -n "${key}" ]] || continue
    [[ "${key}" == "${wanted_key}" ]] || continue
    printf '%s\n' "${value}"
    return 0
  done < "${file}"
  return 1
}

contract_value() {
  local key="$1"
  local default_value="$2"
  local value
  value="$(env_value "${CONTRACT_DIR}/contract.env" "${key}" || true)"
  if [[ -n "${value}" ]]; then
    printf '%s\n' "${value}"
  else
    printf '%s\n' "${default_value}"
  fi
}

profile_value() {
  local key="$1"
  local default_value="$2"
  local value
  value="$(env_value "${profile_env}" "${key}" || true)"
  if [[ -n "${value}" ]]; then
    printf '%s\n' "${value}"
  else
    printf '%s\n' "${default_value}"
  fi
}

if [[ -z "${TLS_MODE}" ]]; then
  TLS_MODE="$(profile_value "OURBOX_PLATFORM_DEFAULT_TLS_MODE" "")"
fi
if [[ -z "${INGRESS_CLASS}" ]]; then
  INGRESS_CLASS="$(profile_value "OURBOX_PLATFORM_DEFAULT_INGRESS_CLASS" "")"
fi
if [[ -z "${STORAGE_CLASS}" ]]; then
  STORAGE_CLASS="$(profile_value "OURBOX_PLATFORM_DEFAULT_STORAGE_CLASS" "")"
fi

CONTRACT_SOURCE="$(contract_value "OURBOX_PLATFORM_CONTRACT_SOURCE" "https://github.com/techofourown/sw-ourbox-os")"
CONTRACT_REVISION="$(contract_value "OURBOX_PLATFORM_CONTRACT_REVISION" "unknown")"
CONTRACT_VERSION="$(contract_value "OURBOX_PLATFORM_CONTRACT_VERSION" "dev")"
CONTRACT_DIGEST="unknown"
if [[ -f "${CONTRACT_DIR}/contract.digest" ]]; then
  CONTRACT_DIGEST="$(tr -d '\n' < "${CONTRACT_DIR}/contract.digest")"
fi

PROFILE_KIND="$(profile_value "OURBOX_PLATFORM_PROFILE_KIND" "${PROFILE}")"
ROUTE_MODEL="$(profile_value "OURBOX_PLATFORM_ROUTE_MODEL" "unknown")"

cat <<EOF
OURBOX_PLATFORM_CONTRACT_SOURCE=${CONTRACT_SOURCE}
OURBOX_PLATFORM_CONTRACT_REVISION=${CONTRACT_REVISION}
OURBOX_PLATFORM_CONTRACT_VERSION=${CONTRACT_VERSION}
OURBOX_PLATFORM_CONTRACT_DIGEST=${CONTRACT_DIGEST}
OURBOX_PLATFORM_PROFILE=${PROFILE}
OURBOX_PLATFORM_PROFILE_KIND=${PROFILE_KIND}
OURBOX_PLATFORM_ROUTE_MODEL=${ROUTE_MODEL}
BOX_HOST=${BOX_HOST}
TLS_MODE=${TLS_MODE}
INGRESS_CLASS=${INGRESS_CLASS}
STORAGE_CLASS=${STORAGE_CLASS}
EOF
