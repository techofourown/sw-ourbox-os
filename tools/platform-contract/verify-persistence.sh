#!/usr/bin/env bash
set -euo pipefail

log() { echo "[$(date -Is)] $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

KUBECONFIG_PATH="/etc/rancher/k3s/k3s.yaml"
K3S_BIN="/usr/local/bin/k3s"
RENDER_DIR=""

cleanup_pods=()
cleanup() {
  local entry namespace pod
  for entry in "${cleanup_pods[@]:-}"; do
    IFS=$'\t' read -r namespace pod <<< "${entry}"
    "${K3S_BIN}" kubectl --kubeconfig "${KUBECONFIG_PATH}" delete pod -n "${namespace}" "${pod}" --ignore-not-found --wait=false >/dev/null 2>&1 || true
  done
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
    *)
      die "unknown argument: $1"
      ;;
  esac
done

[[ -x "${K3S_BIN}" ]] || die "k3s binary not found: ${K3S_BIN}"
[[ -f "${KUBECONFIG_PATH}" ]] || die "kubeconfig not found: ${KUBECONFIG_PATH}"
[[ -n "${RENDER_DIR}" ]] || die "--render-dir is required"
[[ -f "${RENDER_DIR}/render.env" ]] || die "render.env not found in ${RENDER_DIR}"
[[ -f "${RENDER_DIR}/images.lock.json" ]] || die "images.lock.json not found in ${RENDER_DIR}"

kubectl_cmd() {
  "${K3S_BIN}" kubectl --kubeconfig "${KUBECONFIG_PATH}" "$@"
}

pod_suffix() {
  local namespace="$1"
  local name="$2"
  printf '%s' "${namespace}-${name}" | sha1sum | awk '{print substr($1,1,10)}'
}

utility_image_from_lock() {
  python3 - <<'PY' "${RENDER_DIR}/images.lock.json"
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    lock = json.load(handle)
for item in lock["images"]:
    if item["name"] == "nginx":
        print(item["ref"])
        raise SystemExit(0)
raise SystemExit("nginx image not found in images.lock.json")
PY
}

create_helper_pod() {
  local namespace="$1"
  local pvc="$2"
  local pod_name="$3"
  local image="$4"
  local sentinel="$5"
  kubectl_cmd delete pod -n "${namespace}" "${pod_name}" --ignore-not-found --wait=false >/dev/null 2>&1 || true
  cat <<EOF | kubectl_cmd apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ${pod_name}
  namespace: ${namespace}
spec:
  restartPolicy: Never
  containers:
    - name: checker
      image: ${image}
      imagePullPolicy: IfNotPresent
      command:
        - /bin/sh
        - -lc
        - |
          printf '%s\n' '${sentinel}' > /data/.ourbox-persistence-check
          sleep 3600
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: ${pvc}
EOF
  cleanup_pods+=("${namespace}"$'\t'"${pod_name}")
  kubectl_cmd wait --for=condition=Ready -n "${namespace}" pod/"${pod_name}" --timeout=180s >/dev/null
  local written
  written="$(kubectl_cmd exec -n "${namespace}" "${pod_name}" -- cat /data/.ourbox-persistence-check)"
  [[ "${written}" == "${sentinel}" ]] || die "Failed to write persistence sentinel for PVC ${namespace}/${pvc}"
}

verify_sentinel_after_restart() {
  local namespace="$1"
  local pvc="$2"
  local pod_name="$3"
  local image="$4"
  local sentinel="$5"
  kubectl_cmd delete pod -n "${namespace}" "${pod_name}" --ignore-not-found --wait=false >/dev/null 2>&1 || true
  cat <<EOF | kubectl_cmd apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ${pod_name}
  namespace: ${namespace}
spec:
  restartPolicy: Never
  containers:
    - name: checker
      image: ${image}
      imagePullPolicy: IfNotPresent
      command:
        - /bin/sh
        - -lc
        - sleep 3600
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: ${pvc}
EOF
  cleanup_pods+=("${namespace}"$'\t'"${pod_name}")
  kubectl_cmd wait --for=condition=Ready -n "${namespace}" pod/"${pod_name}" --timeout=180s >/dev/null
  local written
  written="$(kubectl_cmd exec -n "${namespace}" "${pod_name}" -- cat /data/.ourbox-persistence-check)"
  [[ "${written}" == "${sentinel}" ]] || die "Persistence sentinel mismatch after restart for PVC ${namespace}/${pvc}"
}

# shellcheck disable=SC1090,SC1091
source "${RENDER_DIR}/render.env"

UTILITY_IMAGE="$(utility_image_from_lock)"
mapfile -t pvcs < <(kubectl_cmd get pvc -A -l "ourbox.techofourown.io/contract-profile=${OURBOX_PLATFORM_PROFILE},ourbox.techofourown.io/storage-required=true" -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\n"}{end}')
(( ${#pvcs[@]} > 0 )) || die "No PVC-backed contract workloads found"

mapfile -t storage_deployments < <(kubectl_cmd get deployment -A -l "ourbox.techofourown.io/contract-profile=${OURBOX_PLATFORM_PROFILE},ourbox.techofourown.io/storage-required=true" -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\n"}{end}')
(( ${#storage_deployments[@]} > 0 )) || die "No storage-required deployments found"

declare -A sentinels=()
declare -A helper_pods=()

for entry in "${pvcs[@]}"; do
  IFS=$'\t' read -r namespace pvc <<< "${entry}"
  suffix="$(pod_suffix "${namespace}" "${pvc}")"
  helper_pod="ourbox-persist-write-${suffix}"
  sentinel="ourbox-persistence-${pvc}-${suffix}"
  log "Writing persistence sentinel for PVC ${namespace}/${pvc}"
  create_helper_pod "${namespace}" "${pvc}" "${helper_pod}" "${UTILITY_IMAGE}" "${sentinel}"
  sentinels["${namespace}/${pvc}"]="${sentinel}"
  helper_pods["${namespace}/${pvc}"]="${helper_pod}"
done

for entry in "${storage_deployments[@]}"; do
  IFS=$'\t' read -r namespace deployment <<< "${entry}"
  log "Restarting storage-backed deployment ${namespace}/${deployment}"
  kubectl_cmd rollout restart -n "${namespace}" deployment "${deployment}"
  kubectl_cmd rollout status -n "${namespace}" deployment "${deployment}" --timeout=300s
done

for entry in "${pvcs[@]}"; do
  IFS=$'\t' read -r namespace pvc <<< "${entry}"
  suffix="$(pod_suffix "${namespace}" "${pvc}")"
  kubectl_cmd delete pod -n "${namespace}" "${helper_pods["${namespace}/${pvc}"]}" --ignore-not-found --wait=true >/dev/null 2>&1 || true
  verify_pod="ourbox-persist-read-${suffix}"
  log "Verifying persistence sentinel for PVC ${namespace}/${pvc}"
  verify_sentinel_after_restart "${namespace}" "${pvc}" "${verify_pod}" "${UTILITY_IMAGE}" "${sentinels["${namespace}/${pvc}"]}"
done

log "PVC persistence verification passed"
