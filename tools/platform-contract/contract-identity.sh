#!/usr/bin/env bash
set -euo pipefail

die() { echo "ERROR: $*" >&2; exit 1; }

CONTRACT_DIR=""
PROFILE=""
BOX_HOST=""
TLS_MODE=""
INGRESS_CLASS=""
STORAGE_CLASS=""
SELECTED_APPS_FILE=""

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
    --selected-apps-file)
      [[ $# -ge 2 ]] || die "--selected-apps-file requires a value"
      SELECTED_APPS_FILE="$2"
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
if [[ -z "${SELECTED_APPS_FILE}" ]]; then
  SELECTED_APPS_FILE="${CONTRACT_DIR}/selected-apps.json"
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
APPLICATION_CATALOG_ID=""
APPLICATION_SELECTION_MODE=""
SELECTED_APPLICATION_IDS=""
SELECTED_APPLICATIONS_SHA256=""

if [[ -f "${SELECTED_APPS_FILE}" ]]; then
  selected_dump="$(
    python3 - <<'PY' "${SELECTED_APPS_FILE}"
import hashlib
import json
import sys
from pathlib import Path

selected_path = Path(sys.argv[1])
data = json.loads(selected_path.read_text(encoding="utf-8"))
if data.get("schema") != 1:
    raise SystemExit("selected-apps file must declare schema=1")
if data.get("kind") != "ourbox-selected-applications":
    raise SystemExit("selected-apps file must declare kind=ourbox-selected-applications")

catalog_id = str(data.get("catalog_id", "")).strip()
selection_mode = str(data.get("selection_mode", "")).strip()
selected_ids = data.get("selected_app_ids")
if not catalog_id:
    raise SystemExit("selected-apps file must declare catalog_id")
if not selection_mode:
    raise SystemExit("selected-apps file must declare selection_mode")
if not isinstance(selected_ids, list) or not selected_ids:
    raise SystemExit("selected-apps file must declare a non-empty selected_app_ids list")

normalized_ids = []
seen_ids = set()
for raw_id in selected_ids:
    app_id = str(raw_id).strip()
    if not app_id:
        raise SystemExit("selected-apps file contains an empty app id")
    if app_id in seen_ids:
        raise SystemExit(f"selected-apps file contains duplicate app id {app_id}")
    normalized_ids.append(app_id)
    seen_ids.add(app_id)

sha256 = hashlib.sha256(selected_path.read_bytes()).hexdigest()
print(catalog_id)
print(selection_mode)
print(",".join(normalized_ids))
print(sha256)
PY
  )"
  mapfile -t selected_fields <<<"${selected_dump}"
  [[ "${#selected_fields[@]}" -eq 4 ]] || die "failed to parse selected-apps file: ${SELECTED_APPS_FILE}"
  APPLICATION_CATALOG_ID="${selected_fields[0]}"
  APPLICATION_SELECTION_MODE="${selected_fields[1]}"
  SELECTED_APPLICATION_IDS="${selected_fields[2]}"
  SELECTED_APPLICATIONS_SHA256="${selected_fields[3]}"
fi

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
OURBOX_APPLICATION_CATALOG_ID=${APPLICATION_CATALOG_ID}
OURBOX_APPLICATION_SELECTION_MODE=${APPLICATION_SELECTION_MODE}
OURBOX_SELECTED_APPLICATION_IDS=${SELECTED_APPLICATION_IDS}
OURBOX_SELECTED_APPLICATIONS_SHA256=${SELECTED_APPLICATIONS_SHA256}
EOF
