#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TOOLING_REF="${OURBOX_CATALOG_TOOLING_REF:-ghcr.io/techofourown/sw-ourbox-os/catalog-tooling:stable}"
EXPECTED_INTERFACE_VERSION="1"

TOOLING_DIR="${ROOT}/.tooling"
rm -rf "${TOOLING_DIR}"
mkdir -p "${TOOLING_DIR}"

RESOLVED_DIGEST="$(oras resolve "${TOOLING_REF}")"
PINNED_REF="${TOOLING_REF%[:@]*}@${RESOLVED_DIGEST}"
printf 'catalog-tooling: requested=%s resolved=%s\n' "${TOOLING_REF}" "${PINNED_REF}"

oras pull "${PINNED_REF}" -o "${TOOLING_DIR}"
tar -xzf "${TOOLING_DIR}/dist/catalog-tooling.tar.gz" -C "${TOOLING_DIR}"

# shellcheck disable=SC1091
source "${TOOLING_DIR}/catalog-tooling/manifest.env"
if [[ "${OURBOX_CATALOG_TOOLING_INTERFACE_VERSION}" != "${EXPECTED_INTERFACE_VERSION}" ]]; then
  echo "FATAL: tooling interface version mismatch: expected=${EXPECTED_INTERFACE_VERSION} got=${OURBOX_CATALOG_TOOLING_INTERFACE_VERSION}" >&2
  exit 1
fi

rm -rf "${ROOT}/scripts"
cp -R "${TOOLING_DIR}/catalog-tooling/scripts" "${ROOT}/scripts"

export OURBOX_CATALOG_TOOLING_REQUESTED_REF="${TOOLING_REF}"
export OURBOX_CATALOG_TOOLING_RESOLVED_DIGEST="${RESOLVED_DIGEST}"

if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "OURBOX_CATALOG_TOOLING_REQUESTED_REF=${TOOLING_REF}" >> "${GITHUB_ENV}"
  echo "OURBOX_CATALOG_TOOLING_RESOLVED_DIGEST=${RESOLVED_DIGEST}" >> "${GITHUB_ENV}"
fi
