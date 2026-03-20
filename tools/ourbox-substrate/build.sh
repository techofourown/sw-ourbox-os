#!/usr/bin/env bash
set -euo pipefail

log() { echo "[$(date -Is)] $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIST_DIR="${ROOT}/dist"
VERSIONS_FILE="${ROOT}/tools/ourbox-substrate/versions.env"
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

[[ -z "${OURBOX_APPLICATION_CATALOG_REF:-}" ]] \
  || die "ourbox-substrate build no longer accepts OURBOX_APPLICATION_CATALOG_REF"
[[ -z "${OURBOX_ALLOW_FIXTURE_APPLICATION_CATALOG:-}" ]] \
  || die "ourbox-substrate build no longer uses OURBOX_ALLOW_FIXTURE_APPLICATION_CATALOG"
[[ -f "${FIXTURE_APPLICATION_CATALOG_FILE}" ]] || die "Missing ${FIXTURE_APPLICATION_CATALOG_FILE}"
[[ -f "${FIXTURE_APPLICATION_IMAGES_LOCK_FILE}" ]] || die "Missing ${FIXTURE_APPLICATION_IMAGES_LOCK_FILE}"

log "Using in-repo demo-apps render fixtures only to derive platform-owned substrate metadata."

REVISION="$(git -C "${ROOT}" rev-parse HEAD)"
CREATED="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
VERSION="dev"
if git -C "${ROOT}" describe --tags --exact-match >/dev/null 2>&1; then
  VERSION="$(git -C "${ROOT}" describe --tags --exact-match)"
fi

# Render the checked-in contract so the substrate bundle stays aligned with the
# current platform sources, then filter the result down to platform-owned refs.
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
  --application-catalog "${FIXTURE_APPLICATION_CATALOG_FILE}" \
  --images-lock-file "${FIXTURE_APPLICATION_IMAGES_LOCK_FILE}" \
  --box-host "ourbox.local" \
  --tls-mode "lan-http" \
  --ingress-class "traefik" \
  --storage-class "local-path"

python3 "${LINT_SCRIPT}" \
  --contract-root "${ROOT}/platform-contract" \
  --render-dir "${render_dir}"

PLATFORM_IMAGES_LOCK_FILE="${build_dir}/platform-images.lock.json"
mapfile -t IMAGES < <(python3 - <<'PY' "${render_dir}/images.lock.json" "${PLATFORM_IMAGES_LOCK_FILE}"
import json
import sys

from pathlib import Path

source_path = Path(sys.argv[1])
filtered_path = Path(sys.argv[2])
data = json.loads(source_path.read_text(encoding="utf-8"))
images = data.get("images")
if not isinstance(images, list):
    raise SystemExit(f"{source_path} must declare an images list")

filtered_images = []
seen_refs = set()
for entry in images:
    used_by = entry.get("used_by")
    if not isinstance(used_by, list):
        raise SystemExit(f"{source_path} contains an image entry without a used_by list")
    normalized_used_by = [str(item).strip() for item in used_by]
    if "_platform" not in normalized_used_by:
        continue

    ref = str(entry.get("ref", "")).strip()
    if not ref:
        raise SystemExit(f"{source_path} contains a platform image without a ref")

    filtered_images.append(entry)
    if ref not in seen_refs:
        print(ref)
        seen_refs.add(ref)

if not filtered_images:
    raise SystemExit(f"{source_path} did not contain any platform-owned image entries")

filtered_lock = dict(data)
filtered_lock["images"] = filtered_images
filtered_path.write_text(
    json.dumps(filtered_lock, indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)
PY
)
IMAGES_LOCK_SHA256="$(sha256sum "${PLATFORM_IMAGES_LOCK_FILE}" | awk '{print $1}')"
log "Resolved ${#IMAGES[@]} unique platform-owned image refs for substrate bundle."

# k3s binaries + substrate images
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
OURBOX_SUBSTRATE_SCHEMA=1
OURBOX_SUBSTRATE_KIND=ourbox-substrate
OURBOX_SUBSTRATE_SOURCE=https://github.com/techofourown/sw-ourbox-os
OURBOX_SUBSTRATE_REVISION=${REVISION}
OURBOX_SUBSTRATE_VERSION=${VERSION}
OURBOX_SUBSTRATE_CREATED=${CREATED}
OURBOX_PLATFORM_CONTRACT_REF=${OURBOX_PLATFORM_CONTRACT_REF}
OURBOX_PLATFORM_CONTRACT_DIGEST=${OURBOX_PLATFORM_CONTRACT_DIGEST}
OURBOX_SUBSTRATE_ARCH=${ARCH}
K3S_VERSION=${K3S_VERSION}
OURBOX_PLATFORM_PROFILE=demo-apps
OURBOX_PLATFORM_IMAGES_LOCK_PATH=platform/images.lock.json
OURBOX_PLATFORM_IMAGES_LOCK_SHA256=${IMAGES_LOCK_SHA256}
EOF_MANIFEST

cp -a "${PLATFORM_IMAGES_LOCK_FILE}" "${build_dir}/platform/images.lock.json"
cp -a "${ROOT}/platform-contract/profiles/demo-apps/profile.env" "${build_dir}/platform/profile.env"

cat > "${DIST_DIR}/ourbox-substrate.meta.env" <<EOF_META
OURBOX_SUBSTRATE_SOURCE=https://github.com/techofourown/sw-ourbox-os
OURBOX_SUBSTRATE_REVISION=${REVISION}
OURBOX_SUBSTRATE_VERSION=${VERSION}
OURBOX_SUBSTRATE_CREATED=${CREATED}
OURBOX_PLATFORM_CONTRACT_REF=${OURBOX_PLATFORM_CONTRACT_REF}
OURBOX_PLATFORM_CONTRACT_DIGEST=${OURBOX_PLATFORM_CONTRACT_DIGEST}
OURBOX_SUBSTRATE_ARCH=${ARCH}
EOF_META

TARBALL="${DIST_DIR}/ourbox-substrate.tar.gz"
tar -C "${build_dir}" -czf "${TARBALL}" k3s platform manifest.env
log "Built ${TARBALL}"
