#!/usr/bin/env bash
set -euo pipefail

log() { echo "[$(date -Is)] $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIST_DIR="${ROOT}/dist"
VERSIONS_FILE="${ROOT}/tools/airgap-platform/versions.env"

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
: "${NGINX_IMAGE:?NGINX_IMAGE not set in versions.env}"
: "${DUFS_IMAGE:?DUFS_IMAGE not set in versions.env}"
: "${FLATNOTES_IMAGE:?FLATNOTES_IMAGE not set in versions.env}"

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

CLI="${CONTAINER_CLI:-$(pick_cli || true)}"
[[ -n "${CLI}" ]] || die "No container CLI found (install docker/nerdctl/podman)"
log "Using container CLI: ${CLI}"

build_dir="$(mktemp -d)"
trap 'rm -rf "${build_dir}"' EXIT

mkdir -p "${build_dir}/k3s" "${build_dir}/platform/images"

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
  local base="$(cli_base "${CLI}")"

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
      ${CLI} pull --arch="${ARCH}" --os=linux "${image}"
      ${CLI} save -o "${tar_path}" "${image}"
      ;;
    *)
      die "Unsupported container CLI: ${CLI}"
      ;;
  esac
}

IMAGES=("${NGINX_IMAGE}" "${DUFS_IMAGE}" "${FLATNOTES_IMAGE}")

for img in "${IMAGES[@]}"; do
  tar_name="$(image_tar_name "${img}")"
  out_path="${build_dir}/platform/images/${tar_name}"
  log "Pull + save (${ARCH}) ${img} -> ${tar_name}"
  pull_and_save_image "${img}" "${out_path}"
  if [[ ! -s "${out_path}" ]]; then
    die "Image save failed for ${img} (${out_path} missing)"
  fi
done

REVISION="$(git -C "${ROOT}" rev-parse HEAD)"
CREATED="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
VERSION="dev"
if git -C "${ROOT}" describe --tags --exact-match >/dev/null 2>&1; then
  VERSION="$(git -C "${ROOT}" describe --tags --exact-match)"
fi

cat > "${build_dir}/manifest.env" <<EOF_MANIFEST
OURBOX_AIRGAP_PLATFORM_SCHEMA=1
OURBOX_AIRGAP_PLATFORM_KIND=airgap-platform
AIRGAP_PLATFORM_ARCH=${ARCH}
K3S_VERSION=${K3S_VERSION}
NGINX_IMAGE=${NGINX_IMAGE}
DUFS_IMAGE=${DUFS_IMAGE}
FLATNOTES_IMAGE=${FLATNOTES_IMAGE}
EOF_MANIFEST

cat > "${DIST_DIR}/airgap-platform.meta.env" <<EOF_META
OURBOX_AIRGAP_PLATFORM_SOURCE=https://github.com/techofourown/sw-ourbox-os
OURBOX_AIRGAP_PLATFORM_REVISION=${REVISION}
OURBOX_AIRGAP_PLATFORM_VERSION=${VERSION}
OURBOX_AIRGAP_PLATFORM_CREATED=${CREATED}
AIRGAP_PLATFORM_ARCH=${ARCH}
EOF_META

TARBALL="${DIST_DIR}/airgap-platform.tar.gz"
tar -C "${build_dir}" -czf "${TARBALL}" k3s platform manifest.env
log "Built ${TARBALL}"
