#!/usr/bin/env bash
set -euo pipefail

log() { echo "[$(date -Is)] $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIST_DIR="${ROOT}/dist"
VERSIONS_FILE="${ROOT}/tools/airgap-platform/versions.env"
RENDER_SCRIPT="${ROOT}/tools/platform-contract/render-contract.py"
LINT_SCRIPT="${ROOT}/tools/platform-contract/lint-rendered-contract.py"
FIXTURE_APPLICATION_CATALOG_FILE="${ROOT}/platform-contract/profiles/demo-apps/catalog.json"
FIXTURE_APPLICATION_IMAGES_LOCK_FILE="${ROOT}/platform-contract/profiles/demo-apps/images.lock.json"

command -v curl >/dev/null 2>&1 || die "curl is required"
command -v git >/dev/null 2>&1 || die "git is required (to stamp revision)"
command -v tar >/dev/null 2>&1 || die "tar is required"

mkdir -p "${DIST_DIR}"

ARCH="${ARCH:-${1:-}}"
[[ -n "${ARCH}" ]] || die "ARCH is required (arm64|amd64)"
case "${ARCH}" in
  arm64|amd64) : ;;
  *) die "Unsupported ARCH: ${ARCH} (expected arm64 or amd64)" ;;
esac

# Load pins
[[ -f "${VERSIONS_FILE}" ]] || die "Missing ${VERSIONS_FILE}"
# shellcheck disable=SC1090
source "${VERSIONS_FILE}"

: "${K3S_VERSION:?K3S_VERSION not set in versions.env}"
: "${OURBOX_PLATFORM_CONTRACT_REF:?OURBOX_PLATFORM_CONTRACT_REF is required}"
: "${OURBOX_PLATFORM_CONTRACT_DIGEST:?OURBOX_PLATFORM_CONTRACT_DIGEST is required}"
[[ "${OURBOX_PLATFORM_CONTRACT_DIGEST}" =~ ^sha256:[0-9a-f]{64}$ ]] \
  || die "OURBOX_PLATFORM_CONTRACT_DIGEST must be a sha256 digest"

# Select container CLI
pick_cli() {
  for c in docker nerdctl podman; do
    if command -v "$c" >/dev/null 2>&1; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

cli_base() {
  basename "${1%% *}"
}

CRANE_BIN="$(command -v crane || true)"
if [[ -n "${CRANE_BIN}" ]]; then
  log "Using crane for image archive pulls: ${CRANE_BIN}"
  CLI=""
else
  CLI="${CONTAINER_CLI:-$(pick_cli || true)}"
  [[ -n "${CLI}" ]] || die "No container CLI found (install crane/docker/nerdctl/podman)"
  log "Using container CLI: ${CLI}"
fi

podman_graphroot=""
podman_runroot=""
build_dir="$(mktemp -d)"

best_effort_remove() {
  local path="$1"
  [[ -n "${path}" && -e "${path}" ]] || return 0

  if [[ -n "${CLI}" && "$(cli_base "${CLI}")" == "podman" ]] && command -v podman >/dev/null 2>&1; then
    podman unshare rm -rf "${path}" >/dev/null 2>&1 || true
  fi
  rm -rf "${path}" >/dev/null 2>&1 || true
}

cleanup() {
  best_effort_remove "${build_dir:-}"
  best_effort_remove "${podman_graphroot:-}"
  best_effort_remove "${podman_runroot:-}"
}
trap cleanup EXIT

if [[ "$(cli_base "${CLI}")" == "podman" ]]; then
  # The shared rootless overlay store on the airgap builder can produce
  # intermittent "reading blob ... no such file or directory" failures when
  # saving some multi-layer archives. Use an isolated transient store with vfs
  # so each bundle build operates on clean storage.
  podman_graphroot="$(mktemp -d)"
  podman_runroot="$(mktemp -d)"
fi

mkdir -p "${build_dir}/k3s" "${build_dir}/platform/images"

ALLOW_FIXTURE_APPLICATION_CATALOG="${OURBOX_ALLOW_FIXTURE_APPLICATION_CATALOG:-0}"
APPLICATION_CATALOG_FILE="${FIXTURE_APPLICATION_CATALOG_FILE}"
APPLICATION_IMAGES_LOCK_FILE="${FIXTURE_APPLICATION_IMAGES_LOCK_FILE}"
APPLICATION_CATALOG_SOURCE_KIND="fixture-profile"
APPLICATION_CATALOG_MANIFEST_FILE=""

prepare_application_catalog_inputs() {
  local pull_dir=""
  local extract_dir=""
  local bundle_tarball=""
  local manifest_digest=""

  if [[ -z "${OURBOX_APPLICATION_CATALOG_REF:-}" ]]; then
    if [[ "${ALLOW_FIXTURE_APPLICATION_CATALOG}" == "1" ]]; then
      log "Using explicitly requested in-repo demo-apps catalog fixtures for airgap-platform build."
      return 0
    fi
    die "OURBOX_APPLICATION_CATALOG_REF is required for airgap-platform build. Set OURBOX_ALLOW_FIXTURE_APPLICATION_CATALOG=1 only for explicit local fixture validation."
  fi

  command -v oras >/dev/null 2>&1 || die "oras is required when OURBOX_APPLICATION_CATALOG_REF is set"

  pull_dir="${build_dir}/application-catalog-pull"
  extract_dir="${build_dir}/application-catalog"
  rm -rf "${pull_dir}" "${extract_dir}"
  mkdir -p "${pull_dir}" "${extract_dir}"

  log "Pulling application catalog bundle: ${OURBOX_APPLICATION_CATALOG_REF}"
  oras pull "${OURBOX_APPLICATION_CATALOG_REF}" -o "${pull_dir}" >/dev/null
  bundle_tarball="$(find "${pull_dir}" -maxdepth 4 -type f -name 'application-catalog-bundle.tar.gz' | head -n 1 || true)"
  [[ -f "${bundle_tarball}" ]] || die "application catalog pull did not produce application-catalog-bundle.tar.gz"

  tar -xzf "${bundle_tarball}" -C "${extract_dir}"
  [[ -f "${extract_dir}/catalog.json" ]] || die "application catalog bundle missing catalog.json"
  [[ -f "${extract_dir}/images.lock.json" ]] || die "application catalog bundle missing images.lock.json"
  [[ -f "${extract_dir}/manifest.env" ]] || die "application catalog bundle missing manifest.env"

  manifest_digest="$(awk -F= '/^OURBOX_PLATFORM_CONTRACT_DIGEST=/{print $2; exit}' "${extract_dir}/manifest.env")"
  [[ "${manifest_digest}" =~ ^sha256:[0-9a-f]{64}$ ]] \
    || die "application catalog bundle manifest must declare a valid OURBOX_PLATFORM_CONTRACT_DIGEST"
  [[ "${manifest_digest}" == "${OURBOX_PLATFORM_CONTRACT_DIGEST}" ]] \
    || die "application catalog bundle contract digest mismatch: expected ${OURBOX_PLATFORM_CONTRACT_DIGEST}, got ${manifest_digest}"

  APPLICATION_CATALOG_FILE="${extract_dir}/catalog.json"
  APPLICATION_IMAGES_LOCK_FILE="${extract_dir}/images.lock.json"
  APPLICATION_CATALOG_MANIFEST_FILE="${extract_dir}/manifest.env"
  APPLICATION_CATALOG_SOURCE_KIND="published-catalog-bundle"
  log "Using published application catalog bundle inputs for airgap-platform build."
}

prepare_application_catalog_inputs

REVISION="$(git -C "${ROOT}" rev-parse HEAD)"
CREATED="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
VERSION="dev"
if git -C "${ROOT}" describe --tags --exact-match >/dev/null 2>&1; then
  VERSION="$(git -C "${ROOT}" describe --tags --exact-match)"
fi

render_dir="${build_dir}/rendered-platform-contract"
OURBOX_PLATFORM_CONTRACT_SCHEMA=1 \
OURBOX_PLATFORM_CONTRACT_KIND=platform-contract \
OURBOX_PLATFORM_CONTRACT_SOURCE=https://github.com/techofourown/sw-ourbox-os \
OURBOX_PLATFORM_CONTRACT_REVISION="${REVISION}" \
OURBOX_PLATFORM_CONTRACT_VERSION="${VERSION}" \
OURBOX_PLATFORM_CONTRACT_CREATED="${CREATED}" \
python3 "${RENDER_SCRIPT}" \
  --contract-root "${ROOT}/platform-contract" \
  --output-dir "${render_dir}" \
  --profile demo-apps \
  --application-catalog "${APPLICATION_CATALOG_FILE}" \
  --images-lock-file "${APPLICATION_IMAGES_LOCK_FILE}" \
  --box-host "airgap.ourbox.local" \
  --tls-mode "lan-http" \
  --ingress-class "traefik" \
  --storage-class "local-path"

python3 "${LINT_SCRIPT}" \
  --contract-root "${ROOT}/platform-contract" \
  --render-dir "${render_dir}"

mapfile -t IMAGES < <(python3 - <<'PY' "${render_dir}/images.lock.json"
import json
import sys
with open(sys.argv[1], "r", encoding="utf-8") as handle:
    data = json.load(handle)
for entry in data["images"]:
    print(entry["ref"])
PY
)
IMAGES_LOCK_SHA256="$(sha256sum "${render_dir}/images.lock.json" | awk '{print $1}')"

# k3s binaries + airgap images
BIN_URL="https://github.com/k3s-io/k3s/releases/download/${K3S_VERSION}/k3s"
if [[ "${ARCH}" == "arm64" ]]; then
  BIN_URL="https://github.com/k3s-io/k3s/releases/download/${K3S_VERSION}/k3s-arm64"
fi

airgap_tar="k3s-airgap-images-${ARCH}.tar"
airgap_url="https://github.com/k3s-io/k3s/releases/download/${K3S_VERSION}/${airgap_tar}"

log "Fetch k3s binary (${ARCH}) @ ${K3S_VERSION}"
curl -fsSL -o "${build_dir}/k3s/k3s" "${BIN_URL}"
chmod +x "${build_dir}/k3s/k3s"

log "Fetch k3s airgap images (${ARCH}) @ ${K3S_VERSION}"
curl -fsSL -o "${build_dir}/k3s/${airgap_tar}" "${airgap_url}"

# Helper to name tars exactly like Matchbox expects
image_tar_name() {
  local base
  base="$(echo "$1" | sed 's|/|_|g; s|:|_|g')"
  echo "${base}.tar"
}

pull_and_save_image() {
  local image="$1"
  local tar_path="$2"
  local base

  if [[ -n "${CRANE_BIN}" ]]; then
    "${CRANE_BIN}" --platform "linux/${ARCH}" pull "${image}" "${tar_path}"
    return 0
  fi

  base="$(cli_base "${CLI}")"

  case "${base}" in
    docker|nerdctl)
      ${CLI} pull --platform="linux/${ARCH}" "${image}"
      if [[ "${base}" == "nerdctl" ]]; then
        ${CLI} save --platform="linux/${ARCH}" -o "${tar_path}" "${image}"
      else
        ${CLI} save -o "${tar_path}" "${image}"
      fi
      ;;
    podman)
      ${CLI} \
        --root "${podman_graphroot}" \
        --runroot "${podman_runroot}" \
        --storage-driver=vfs \
        pull --arch="${ARCH}" --os=linux "${image}"
      ${CLI} \
        --root "${podman_graphroot}" \
        --runroot "${podman_runroot}" \
        --storage-driver=vfs \
        save --format docker-archive -o "${tar_path}" "${image}"
      ;;
    *)
      die "Unsupported container CLI: ${CLI}"
      ;;
  esac
}

for img in "${IMAGES[@]}"; do
  tar_name="$(image_tar_name "${img}")"
  out_path="${build_dir}/platform/images/${tar_name}"
  log "Pull + save (${ARCH}) ${img} -> ${tar_name}"
  pull_and_save_image "${img}" "${out_path}"
  if [[ ! -s "${out_path}" ]]; then
    die "Image save failed for ${img} (${out_path} missing)"
  fi
done

cat > "${build_dir}/manifest.env" <<EOF_MANIFEST
OURBOX_AIRGAP_PLATFORM_SCHEMA=1
OURBOX_AIRGAP_PLATFORM_KIND=airgap-platform
OURBOX_AIRGAP_PLATFORM_SOURCE=https://github.com/techofourown/sw-ourbox-os
OURBOX_AIRGAP_PLATFORM_REVISION=${REVISION}
OURBOX_AIRGAP_PLATFORM_VERSION=${VERSION}
OURBOX_AIRGAP_PLATFORM_CREATED=${CREATED}
OURBOX_PLATFORM_CONTRACT_REF=${OURBOX_PLATFORM_CONTRACT_REF}
OURBOX_PLATFORM_CONTRACT_DIGEST=${OURBOX_PLATFORM_CONTRACT_DIGEST}
AIRGAP_PLATFORM_ARCH=${ARCH}
K3S_VERSION=${K3S_VERSION}
OURBOX_PLATFORM_PROFILE=demo-apps
OURBOX_PLATFORM_IMAGES_LOCK_PATH=platform/images.lock.json
OURBOX_PLATFORM_IMAGES_LOCK_SHA256=${IMAGES_LOCK_SHA256}
EOF_MANIFEST

cp -a "${render_dir}/images.lock.json" "${build_dir}/platform/images.lock.json"
cp -a "${ROOT}/platform-contract/profiles/demo-apps/profile.env" "${build_dir}/platform/profile.env"
if [[ -f "${APPLICATION_CATALOG_FILE}" ]]; then
  cp -a "${APPLICATION_CATALOG_FILE}" "${build_dir}/platform/catalog.json"
fi
if [[ -f "${render_dir}/selected-apps.json" ]]; then
  cp -a "${render_dir}/selected-apps.json" "${build_dir}/platform/selected-apps.json"
else
  die "rendered platform contract did not produce selected-apps.json"
fi

cat > "${DIST_DIR}/airgap-platform.meta.env" <<EOF_META
OURBOX_AIRGAP_PLATFORM_SOURCE=https://github.com/techofourown/sw-ourbox-os
OURBOX_AIRGAP_PLATFORM_REVISION=${REVISION}
OURBOX_AIRGAP_PLATFORM_VERSION=${VERSION}
OURBOX_AIRGAP_PLATFORM_CREATED=${CREATED}
OURBOX_PLATFORM_CONTRACT_REF=${OURBOX_PLATFORM_CONTRACT_REF}
OURBOX_PLATFORM_CONTRACT_DIGEST=${OURBOX_PLATFORM_CONTRACT_DIGEST}
AIRGAP_PLATFORM_ARCH=${ARCH}
EOF_META

TARBALL="${DIST_DIR}/airgap-platform.tar.gz"
tar -C "${build_dir}" -czf "${TARBALL}" k3s platform manifest.env
log "Built ${TARBALL}"
