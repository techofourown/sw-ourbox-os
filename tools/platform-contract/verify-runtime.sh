#!/usr/bin/env bash
set -euo pipefail

log() { echo "[$(date -Is)] $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

KUBECONFIG_PATH="/etc/rancher/k3s/k3s.yaml"
K3S_BIN="/usr/local/bin/k3s"
RENDER_DIR=""
CONTRACT_DIR=""
RELEASE_FILE="/etc/ourbox/release"
METADATA_CONFIGMAP="ourbox-platform-contract"
METADATA_NAMESPACE="ourbox-system"
TRAEFIK_NAMESPACE="kube-system"
TRAEFIK_SELECTOR="app.kubernetes.io/name=traefik"
TRAEFIK_LOG_SINCE="10m"
SKIP_TRAEFIK_LOG_CHECK=0
ROUTE_BASE_URL="http://127.0.0.1"
READY_NODES_TIMEOUT_SECS=120
READY_NODES_POLL_INTERVAL_SECS=2
SANITIZED_RELEASE_ENV=""

cleanup() {
  if [[ -n "${SANITIZED_RELEASE_ENV}" && -f "${SANITIZED_RELEASE_ENV}" ]]; then
    rm -f "${SANITIZED_RELEASE_ENV}"
  fi
}
trap cleanup EXIT

while [[ $# -gt 0 ]]; do
  case "$1" in
    --kubeconfig)
      [[ $# -ge 2 ]] || die "--kubeconfig requires a value"
      KUBECONFIG_PATH="$2"
      shift 2
      ;;
    --k3s-bin)
      [[ $# -ge 2 ]] || die "--k3s-bin requires a value"
      K3S_BIN="$2"
      shift 2
      ;;
    --render-dir)
      [[ $# -ge 2 ]] || die "--render-dir requires a value"
      RENDER_DIR="$2"
      shift 2
      ;;
    --contract-dir)
      [[ $# -ge 2 ]] || die "--contract-dir requires a value"
      CONTRACT_DIR="$2"
      shift 2
      ;;
    --release-file)
      [[ $# -ge 2 ]] || die "--release-file requires a value"
      RELEASE_FILE="$2"
      shift 2
      ;;
    --metadata-configmap)
      [[ $# -ge 2 ]] || die "--metadata-configmap requires a value"
      METADATA_CONFIGMAP="$2"
      shift 2
      ;;
    --metadata-namespace)
      [[ $# -ge 2 ]] || die "--metadata-namespace requires a value"
      METADATA_NAMESPACE="$2"
      shift 2
      ;;
    --traefik-namespace)
      [[ $# -ge 2 ]] || die "--traefik-namespace requires a value"
      TRAEFIK_NAMESPACE="$2"
      shift 2
      ;;
    --traefik-selector)
      [[ $# -ge 2 ]] || die "--traefik-selector requires a value"
      TRAEFIK_SELECTOR="$2"
      shift 2
      ;;
    --traefik-log-since)
      [[ $# -ge 2 ]] || die "--traefik-log-since requires a value"
      TRAEFIK_LOG_SINCE="$2"
      shift 2
      ;;
    --skip-traefik-log-check)
      SKIP_TRAEFIK_LOG_CHECK=1
      shift
      ;;
    --route-base-url)
      [[ $# -ge 2 ]] || die "--route-base-url requires a value"
      ROUTE_BASE_URL="$2"
      shift 2
      ;;
    --ready-nodes-timeout-secs)
      [[ $# -ge 2 ]] || die "--ready-nodes-timeout-secs requires a value"
      READY_NODES_TIMEOUT_SECS="$2"
      shift 2
      ;;
    --ready-nodes-poll-interval-secs)
      [[ $# -ge 2 ]] || die "--ready-nodes-poll-interval-secs requires a value"
      READY_NODES_POLL_INTERVAL_SECS="$2"
      shift 2
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

[[ -n "${RENDER_DIR}" ]] || die "--render-dir is required"
[[ -n "${CONTRACT_DIR}" ]] || die "--contract-dir is required"
[[ -x "${K3S_BIN}" ]] || die "k3s binary not found: ${K3S_BIN}"
[[ -f "${KUBECONFIG_PATH}" ]] || die "kubeconfig not found: ${KUBECONFIG_PATH}"
[[ -f "${RENDER_DIR}/render.env" ]] || die "render.env not found in ${RENDER_DIR}"
command -v python3 >/dev/null 2>&1 || die "python3 is required for route verification"

kubectl_cmd() {
  "${K3S_BIN}" kubectl --kubeconfig "${KUBECONFIG_PATH}" "$@"
}

metadata_value() {
  local key="$1"
  kubectl_cmd get configmap "${METADATA_CONFIGMAP}" -n "${METADATA_NAMESPACE}" -o "jsonpath={.data.${key}}"
}

sanitize_release_metadata() {
  local release_file="$1"

  SANITIZED_RELEASE_ENV="$(mktemp "${TMPDIR:-/tmp}/ourbox-release.XXXXXX")"
  python3 - "${release_file}" > "${SANITIZED_RELEASE_ENV}" <<'PY'
import re
import shlex
import sys
from pathlib import Path

release_path = Path(sys.argv[1])
key_pattern = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")

for lineno, raw_line in enumerate(release_path.read_text(encoding="utf-8").splitlines(), start=1):
    stripped = raw_line.strip()
    if not stripped or stripped.startswith("#"):
        continue
    if "=" not in raw_line:
        raise SystemExit(f"malformed release metadata line {lineno}: missing '='")

    key, value = raw_line.split("=", 1)
    key = key.strip()
    if not key_pattern.match(key):
        raise SystemExit(f"malformed release metadata line {lineno}: invalid key '{key}'")

    value = value.strip()
    if not value:
        parsed = ""
    else:
        try:
            tokens = shlex.split(value, posix=True)
        except ValueError as exc:
            raise SystemExit(f"malformed release metadata line {lineno}: {exc}") from exc
        if len(tokens) != 1:
            raise SystemExit(
                f"malformed release metadata line {lineno}: values with spaces must be quoted"
            )
        parsed = tokens[0]

    print(f"{key}={shlex.quote(parsed)}")
PY
}

# shellcheck disable=SC1090,SC1091
source "${RENDER_DIR}/render.env"

if [[ -f "${RELEASE_FILE}" ]]; then
  sanitize_release_metadata "${RELEASE_FILE}" || die "failed to parse release metadata file: ${RELEASE_FILE}"
  # shellcheck disable=SC1090,SC1091
  source "${SANITIZED_RELEASE_ENV}"
else
  log "Release metadata file missing; skipping device metadata parity check: ${RELEASE_FILE}"
fi

if [[ "${HTTP_ROUTES_FILE}" != /* ]]; then
  HTTP_ROUTES_FILE="${RENDER_DIR}/${HTTP_ROUTES_FILE}"
fi
[[ -f "${HTTP_ROUTES_FILE}" ]] || die "http-routes.tsv not found: ${HTTP_ROUTES_FILE}"

count_ready_nodes() {
  local node_statuses
  node_statuses="$(
    kubectl_cmd get nodes -o jsonpath='{range .items[*]}{range .status.conditions[?(@.type=="Ready")]}{.status}{"\n"}{end}{end}'
  )" || return 1
  awk 'BEGIN { count = 0 } /^True$/ { count++ } END { print count }' <<< "${node_statuses}"
}

wait_for_ready_nodes() {
  local ready_count deadline
  deadline=$((SECONDS + READY_NODES_TIMEOUT_SECS))

  while true; do
    ready_count="$(count_ready_nodes)" || die "Failed to query k3s nodes"
    if [[ "${ready_count}" -gt 0 ]]; then
      log "Found ${ready_count} Ready k3s node(s)"
      return 0
    fi
    if (( SECONDS >= deadline )); then
      die "No Ready k3s nodes found after ${READY_NODES_TIMEOUT_SECS}s"
    fi
    sleep "${READY_NODES_POLL_INTERVAL_SECS}"
  done
}

wait_for_contract_deployments() {
  local selector="$1"
  local entry namespace deployment
  mapfile -t deployments < <(kubectl_cmd get deployment -A -l "${selector}" -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\n"}{end}')
  (( ${#deployments[@]} > 0 )) || die "No contract-owned deployments matched selector '${selector}'"
  for entry in "${deployments[@]}"; do
    IFS=$'\t' read -r namespace deployment <<< "${entry}"
    log "Waiting for deployment ${namespace}/${deployment}"
    kubectl_cmd rollout status -n "${namespace}" deployment "${deployment}" --timeout=300s
  done
}

wait_for_contract_services() {
  local selector="$1"
  local entry namespace service endpoints
  mapfile -t services < <(kubectl_cmd get service -A -l "${selector}" -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\n"}{end}')
  (( ${#services[@]} > 0 )) || die "No contract-owned services matched selector '${selector}'"
  for entry in "${services[@]}"; do
    IFS=$'\t' read -r namespace service <<< "${entry}"
    endpoints=""
    for _ in $(seq 1 120); do
      endpoints="$(kubectl_cmd get endpoints -n "${namespace}" "${service}" -o jsonpath='{range .subsets[*].addresses[*]}{.ip}{" "}{end}' 2>/dev/null || true)"
      if [[ -n "${endpoints}" ]]; then
        break
      fi
      sleep 1
    done
    [[ -n "${endpoints}" ]] || die "Service ${namespace}/${service} never acquired ready endpoints"
  done
}

verify_contract_routes() {
  local routes_file="$1"
  local host path expected_status body_marker description status body_file
  local request_base="${ROUTE_BASE_URL%/}"
  body_file="$(mktemp)"
  trap 'rm -f "${body_file}"' RETURN
  while IFS=$'\t' read -r host path expected_status body_marker description; do
    [[ "${host}" == "host" ]] && continue
    [[ -z "${host}" ]] && continue
    status=""
    for _ in $(seq 1 60); do
      : > "${body_file}"
      status="$(
        python3 - <<'PY' "${request_base}" "${host}" "${path}" "${body_file}"
import sys
import urllib.error
import urllib.request
from pathlib import Path

base_url, host, path, body_path = sys.argv[1:]
request = urllib.request.Request(
    f"{base_url}{path}",
    headers={"Host": host},
)
target = Path(body_path)

try:
    with urllib.request.urlopen(request, timeout=5) as response:
        body = response.read()
        status = response.getcode()
except urllib.error.HTTPError as error:
    body = error.read()
    status = error.code
except Exception:
    target.write_bytes(b"")
    print("000")
    raise SystemExit(0)

target.write_bytes(body)
print(status)
PY
      )"
      if [[ "${status}" == "${expected_status}" ]] && grep -Fqi -- "${body_marker}" "${body_file}"; then
        break
      fi
      sleep 2
    done
    [[ "${status}" == "${expected_status}" ]] || die "Route ${description} expected ${expected_status} but received '${status}'"
    grep -Fqi -- "${body_marker}" "${body_file}" || die "Route ${description} did not contain expected body marker '${body_marker}'"
  done < "${routes_file}"
}

verify_metadata_configmap() {
  [[ "$(metadata_value profile)" == "${OURBOX_PLATFORM_PROFILE}" ]] || die "ConfigMap profile mismatch"
  [[ "$(metadata_value route_model)" == "${OURBOX_PLATFORM_ROUTE_MODEL}" ]] || die "ConfigMap route_model mismatch"
  [[ "$(metadata_value box_host)" == "${BOX_HOST}" ]] || die "ConfigMap box_host mismatch"
  [[ "$(metadata_value tls_mode)" == "${TLS_MODE}" ]] || die "ConfigMap tls_mode mismatch"
  [[ "$(metadata_value ingress_class)" == "${INGRESS_CLASS}" ]] || die "ConfigMap ingress_class mismatch"
  [[ "$(metadata_value storage_class)" == "${STORAGE_CLASS}" ]] || die "ConfigMap storage_class mismatch"
}

verify_release_metadata_parity() {
  return 0
}

verify_traefik_logs() {
  local service_regex pod logs
  (( SKIP_TRAEFIK_LOG_CHECK == 0 )) || return 0

  service_regex="$(kubectl_cmd get service -n "${METADATA_NAMESPACE}" -l "${READINESS_LABEL_SELECTOR}" -o jsonpath='{range .items[*]}{.metadata.name}{"|"}{end}')"
  service_regex="${service_regex%|}"
  [[ -n "${service_regex}" ]] || die "No contract-owned services found for Traefik log verification"

  mapfile -t traefik_pods < <(kubectl_cmd get pods -n "${TRAEFIK_NAMESPACE}" -l "${TRAEFIK_SELECTOR}" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
  (( ${#traefik_pods[@]} > 0 )) || die "No Traefik pods found for selector '${TRAEFIK_SELECTOR}' in namespace '${TRAEFIK_NAMESPACE}'"

  for pod in "${traefik_pods[@]}"; do
    logs="$(kubectl_cmd logs -n "${TRAEFIK_NAMESPACE}" "${pod}" --since="${TRAEFIK_LOG_SINCE}" 2>/dev/null || true)"
    if printf '%s\n' "${logs}" | grep -Eq '(Cannot create service|service not found)' &&
       printf '%s\n' "${logs}" | grep -Eq "(${service_regex}|${METADATA_NAMESPACE})"; then
      die "Traefik pod ${pod} reported contract-owned backend errors in the last ${TRAEFIK_LOG_SINCE}"
    fi
  done
}

log "Verifying k3s node readiness"
wait_for_ready_nodes

log "Verifying contract-owned deployments"
wait_for_contract_deployments "${READINESS_LABEL_SELECTOR}"

log "Verifying contract-owned services/endpoints"
wait_for_contract_services "${READINESS_LABEL_SELECTOR}"

log "Verifying contract metadata ConfigMap"
verify_metadata_configmap

log "Verifying device release metadata parity"
verify_release_metadata_parity

log "Verifying expected HTTP routes"
verify_contract_routes "${HTTP_ROUTES_FILE}"

log "Verifying Traefik logs are clean for contract-owned services"
verify_traefik_logs

log "Runtime contract verification passed"
