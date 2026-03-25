#!/usr/bin/env bash
set -euo pipefail

log() { echo "[$(date -Is)] $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIST_DIR="${ROOT}/dist"
VERSIONS_FILE="${ROOT}/tools/ourbox-substrate/versions.env"
SUBSTRATE_PROFILE_DIR="${ROOT}/tools/ourbox-substrate/profiles/demo-apps"
PLATFORM_PROFILE_ENV_FILE="${SUBSTRATE_PROFILE_DIR}/profile.env"
PLATFORM_IMAGE_SOURCES_FILE="${SUBSTRATE_PROFILE_DIR}/platform-image-sources.json"

command -v curl >/dev/null 2>&1 || die "curl is required"
command -v git >/dev/null 2>&1 || die "git is required (to stamp revision)"
command -v python3 >/dev/null 2>&1 || die "python3 is required"
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

resolve_k3s_images_asset() {
  local arch="$1"
  local release_json
  local release_api
  local api_token
  local -a curl_args

  release_json="$(mktemp)"
  release_api="https://api.github.com/repos/k3s-io/k3s/releases/tags/${K3S_VERSION}"
  curl_args=(
    -fsSL
    -H "Accept: application/vnd.github+json"
    -o "${release_json}"
  )

  api_token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
  if [[ -n "${api_token}" ]]; then
    curl_args+=(-H "Authorization: Bearer ${api_token}")
  fi

  if ! curl "${curl_args[@]}" "${release_api}"; then
    rm -f "${release_json}"
    die "failed to fetch K3s release metadata for ${K3S_VERSION}"
  fi

  if ! python3 - "${release_json}" "${arch}" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as fh:
    data = json.load(fh)

assets = data.get("assets")
if not isinstance(assets, list):
    raise SystemExit("release JSON must include an assets list")

arch = sys.argv[2]
matches = []
for asset in assets:
    if not isinstance(asset, dict):
        continue
    name = str(asset.get("name", "")).strip()
    url = str(asset.get("browser_download_url", "")).strip()
    if not name or not url:
        continue
    if not name.startswith("k3s-"):
        continue
    if not name.endswith(f"-{arch}.tar"):
        continue
    if "images" not in name:
        continue
    matches.append(url)

if not matches:
    raise SystemExit(f"release JSON did not contain a k3s images tar for arch={arch}")
if len(matches) != 1:
    raise SystemExit(f"release JSON matched multiple k3s images tar assets for arch={arch}")

print(matches[0])
PY
  then
    rm -f "${release_json}"
    die "failed to resolve K3s images asset for ${arch}"
  fi

  rm -f "${release_json}"
}

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
  # The shared rootless overlay store on the substrate builder can produce
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
[[ -f "${PLATFORM_PROFILE_ENV_FILE}" ]] || die "Missing ${PLATFORM_PROFILE_ENV_FILE}"
[[ -f "${PLATFORM_IMAGE_SOURCES_FILE}" ]] || die "Missing ${PLATFORM_IMAGE_SOURCES_FILE}"

PLATFORM_PROFILE="$(awk -F= '/^OURBOX_PLATFORM_PROFILE=/{print $2; exit}' "${PLATFORM_PROFILE_ENV_FILE}")"
[[ -n "${PLATFORM_PROFILE}" ]] || die "OURBOX_PLATFORM_PROFILE is missing from ${PLATFORM_PROFILE_ENV_FILE}"

GENERATED_PLATFORM_IMAGES_LOCK="${build_dir}/generated-platform-images.lock.json"
python3 "${ROOT}/tools/platform-contract/resolve-image-sources.py" \
  --input "${PLATFORM_IMAGE_SOURCES_FILE}" \
  --profile "${PLATFORM_PROFILE}" \
  --require-used-by _platform \
  --output "${GENERATED_PLATFORM_IMAGES_LOCK}"

log "Using substrate-local platform profile metadata plus generated platform-owned image lock."

REVISION="$(git -C "${ROOT}" rev-parse HEAD)"
CREATED="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
VERSION="dev"
if git -C "${ROOT}" describe --tags --exact-match >/dev/null 2>&1; then
  VERSION="$(git -C "${ROOT}" describe --tags --exact-match)"
fi

mapfile -t IMAGES < <(python3 - <<'PY' "${GENERATED_PLATFORM_IMAGES_LOCK}" "${PLATFORM_PROFILE}"
import json
import sys

from pathlib import Path

source_path = Path(sys.argv[1])
expected_profile = sys.argv[2]
data = json.loads(source_path.read_text(encoding="utf-8"))
if data.get("schema") != 1:
    raise SystemExit(f"{source_path} must declare schema=1")

profile = str(data.get("profile", "")).strip()
if profile != expected_profile:
    raise SystemExit(f"{source_path} must declare profile={expected_profile!r}")

images = data.get("images")
if not isinstance(images, list):
    raise SystemExit(f"{source_path} must declare an images list")

seen_names = set()
seen_refs = set()
for entry in images:
    name = str(entry.get("name", "")).strip()
    used_by = entry.get("used_by")
    if not isinstance(used_by, list):
        raise SystemExit(f"{source_path} contains an image entry without a used_by list")
    normalized_used_by = [str(item).strip() for item in used_by]
    if "_platform" not in normalized_used_by:
        raise SystemExit(f"{source_path} entry {name!r} must declare used_by including '_platform'")

    ref = str(entry.get("ref", "")).strip()
    if not name:
        raise SystemExit(f"{source_path} contains a platform image without a name")
    if not ref:
        raise SystemExit(f"{source_path} contains a platform image without a ref")
    if name in seen_names:
        raise SystemExit(f"{source_path} contains a duplicate platform image name: {name}")

    seen_names.add(name)
    if ref not in seen_refs:
        print(ref)
        seen_refs.add(ref)

if not seen_refs:
    raise SystemExit(f"{source_path} did not contain any platform-owned image entries")
PY
)
IMAGES_LOCK_SHA256="$(sha256sum "${GENERATED_PLATFORM_IMAGES_LOCK}" | awk '{print $1}')"
log "Resolved ${#IMAGES[@]} unique platform-owned image refs for substrate bundle."

# k3s binaries + substrate images
BIN_URL="https://github.com/k3s-io/k3s/releases/download/${K3S_VERSION}/k3s"
if [[ "${ARCH}" == "arm64" ]]; then
  BIN_URL="https://github.com/k3s-io/k3s/releases/download/${K3S_VERSION}/k3s-arm64"
fi

k3s_images_tar="k3s-images-${ARCH}.tar"
k3s_images_url="$(resolve_k3s_images_asset "${ARCH}")"

log "Fetch k3s binary (${ARCH}) @ ${K3S_VERSION}"
curl -fsSL -o "${build_dir}/k3s/k3s" "${BIN_URL}"
chmod +x "${build_dir}/k3s/k3s"

log "Fetch k3s images (${ARCH}) @ ${K3S_VERSION}"
curl -fsSL -o "${build_dir}/k3s/${k3s_images_tar}" "${k3s_images_url}"

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
OURBOX_SUBSTRATE_SOURCE=https://github.com/techofourown/sw-ourbox-os
OURBOX_SUBSTRATE_REVISION=${REVISION}
OURBOX_SUBSTRATE_VERSION=${VERSION}
OURBOX_SUBSTRATE_CREATED=${CREATED}
OURBOX_SUBSTRATE_ARCH=${ARCH}
K3S_VERSION=${K3S_VERSION}
OURBOX_PLATFORM_PROFILE=${PLATFORM_PROFILE}
OURBOX_PLATFORM_IMAGES_LOCK_PATH=platform/images.lock.json
OURBOX_PLATFORM_IMAGES_LOCK_SHA256=${IMAGES_LOCK_SHA256}
EOF_MANIFEST

cp -a "${GENERATED_PLATFORM_IMAGES_LOCK}" "${build_dir}/platform/images.lock.json"
cp -a "${PLATFORM_PROFILE_ENV_FILE}" "${build_dir}/platform/profile.env"

cat > "${DIST_DIR}/ourbox-substrate.meta.env" <<EOF_META
OURBOX_SUBSTRATE_SOURCE=https://github.com/techofourown/sw-ourbox-os
OURBOX_SUBSTRATE_REVISION=${REVISION}
OURBOX_SUBSTRATE_VERSION=${VERSION}
OURBOX_SUBSTRATE_CREATED=${CREATED}
OURBOX_SUBSTRATE_ARCH=${ARCH}
EOF_META

TARBALL="${DIST_DIR}/ourbox-substrate.tar.gz"
tar -C "${build_dir}" -czf "${TARBALL}" k3s platform manifest.env
log "Built ${TARBALL}"
