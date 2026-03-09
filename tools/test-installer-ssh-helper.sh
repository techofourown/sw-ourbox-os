#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT}/tools/installer-ssh-helper.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

reset_env() {
  unset OURBOX_INSTALLER_SSH_MODE
  unset OURBOX_INSTALLER_SSH_USER
  unset OURBOX_INSTALLER_SSH_PASSWORD_HASH
  unset OURBOX_INSTALLER_SSH_AUTHORIZED_KEYS
  unset OURBOX_INSTALLER_SSH_ALLOW_ROOT
  unset OURBOX_INSTALLER_SSH_GENERATE_PASSWORD_IF_EMPTY
}

expect_success() {
  local label="$1"
  shift
  if ! "$@"; then
    printf 'FAIL: %s\n' "${label}" >&2
    exit 1
  fi
}

expect_failure() {
  local label="$1"
  shift
  if ( "$@" ) >/dev/null 2>&1; then
    printf 'FAIL: %s\n' "${label}" >&2
    exit 1
  fi
}

test_off_renders_expected_fragment() {
  local config="${TMP}/off.conf"
  reset_env
  OURBOX_INSTALLER_SSH_MODE="off"
  ourbox_installer_ssh_normalize_inputs
  expect_success "off requested posture" ourbox_installer_ssh_validate_requested_posture
  expect_success "off materialized auth" ourbox_installer_ssh_validate_materialized_auth
  ourbox_installer_ssh_write_sshd_fragment "${config}"
  grep -qx 'PermitRootLogin no' "${config}"
  grep -qx 'PasswordAuthentication no' "${config}"
  grep -qx 'AllowUsers nobody' "${config}"
}

test_key_without_keys_fails_requested_posture() {
  reset_env
  OURBOX_INSTALLER_SSH_MODE="key"
  ourbox_installer_ssh_normalize_inputs
  expect_failure "key without keys fails requested posture" ourbox_installer_ssh_validate_requested_posture
}

test_password_without_hash_and_without_generation_fails_requested_posture() {
  reset_env
  OURBOX_INSTALLER_SSH_MODE="password"
  OURBOX_INSTALLER_SSH_GENERATE_PASSWORD_IF_EMPTY="0"
  ourbox_installer_ssh_normalize_inputs
  expect_failure \
    "password without hash and without generation fails requested posture" \
    ourbox_installer_ssh_validate_requested_posture
}

test_password_without_hash_and_with_generation_passes_requested_posture() {
  reset_env
  OURBOX_INSTALLER_SSH_MODE="password"
  OURBOX_INSTALLER_SSH_GENERATE_PASSWORD_IF_EMPTY="1"
  ourbox_installer_ssh_normalize_inputs
  expect_success \
    "password without hash and with generation passes requested posture" \
    ourbox_installer_ssh_validate_requested_posture
}

test_materialized_auth_still_fails_until_hash_exists() {
  reset_env
  OURBOX_INSTALLER_SSH_MODE="password"
  OURBOX_INSTALLER_SSH_GENERATE_PASSWORD_IF_EMPTY="1"
  ourbox_installer_ssh_normalize_inputs
  expect_failure \
    "materialized auth fails until a password hash exists" \
    ourbox_installer_ssh_validate_materialized_auth
}

test_both_with_keys_only_passes_materialized_auth() {
  reset_env
  OURBOX_INSTALLER_SSH_MODE="both"
  OURBOX_INSTALLER_SSH_AUTHORIZED_KEYS="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITestInstallerKey only@test"
  ourbox_installer_ssh_normalize_inputs
  expect_success "both with keys requested posture" ourbox_installer_ssh_validate_requested_posture
  expect_success "both with keys materialized auth" ourbox_installer_ssh_validate_materialized_auth
}

test_both_with_hash_only_passes_materialized_auth() {
  reset_env
  OURBOX_INSTALLER_SSH_MODE="both"
  OURBOX_INSTALLER_SSH_PASSWORD_HASH="\$6\$testsalt\$0123456789abcdef"
  ourbox_installer_ssh_normalize_inputs
  expect_success "both with hash requested posture" ourbox_installer_ssh_validate_requested_posture
  expect_success "both with hash materialized auth" ourbox_installer_ssh_validate_materialized_auth
}

test_root_default_stays_off() {
  local config="${TMP}/default.conf"
  reset_env
  OURBOX_INSTALLER_SSH_MODE="off"
  ourbox_installer_ssh_normalize_inputs
  [[ "${OURBOX_INSTALLER_SSH_ALLOW_ROOT}" == "0" ]]
  ourbox_installer_ssh_write_sshd_fragment "${config}"
  grep -qx 'PermitRootLogin no' "${config}"
}

main() {
  test_off_renders_expected_fragment
  test_key_without_keys_fails_requested_posture
  test_password_without_hash_and_without_generation_fails_requested_posture
  test_password_without_hash_and_with_generation_passes_requested_posture
  test_materialized_auth_still_fails_until_hash_exists
  test_both_with_keys_only_passes_materialized_auth
  test_both_with_hash_only_passes_materialized_auth
  test_root_default_stays_off
  printf 'installer ssh helper tests: PASS\n'
}

main "$@"
