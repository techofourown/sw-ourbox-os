#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
import os
import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
MODULE_PATH = ROOT / "tools" / "release-control" / "release_control.py"
TESTDATA = ROOT / "tools" / "release-control" / "tests" / "testdata"

spec = importlib.util.spec_from_file_location("release_control", MODULE_PATH)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)


class EnvOverride:
    def __init__(self, **changes: str) -> None:
        self.changes = changes
        self.original: dict[str, str | None] = {}

    def __enter__(self) -> None:
        for key, value in self.changes.items():
            self.original[key] = os.environ.get(key)
            os.environ[key] = value

    def __exit__(self, exc_type, exc, tb) -> None:
        for key, original in self.original.items():
            if original is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = original


class ReleaseControlTests(unittest.TestCase):
    maxDiff = None

    def write_stub_oras(self, tempdir: Path, *, capture_catalog: bool = True, missing_catalog: bool = True) -> Path:
        stub_path = tempdir / "oras"
        stub_path.write_text(
            textwrap.dedent(
                """\
                #!/usr/bin/env bash
                set -euo pipefail
                printf '%s\\n' "$*" >> "${STUB_ORAS_LOG}"
                cmd="${1:?}"
                case "${cmd}" in
                  resolve)
                    ref="${2:?}"
                    if [[ -n "${STUB_EXISTING_IMMUTABLE_REF:-}" && "${ref}" == "${STUB_EXISTING_IMMUTABLE_REF}" ]]; then
                      printf '%s\\n' "${STUB_EXISTING_IMMUTABLE_DIGEST:-}"
                      exit 0
                    fi
                    exit 1
                    ;;
                  tag)
                    exit 0
                    ;;
                  pull)
                    ref="${2:?}"
                    if [[ -n "${STUB_DISALLOWED_PULL_REF:-}" && "${ref}" == "${STUB_DISALLOWED_PULL_REF}" ]]; then
                      echo "unexpected source-artifact pull: ${ref}" >&2
                      exit 91
                    fi
                    if [[ "${ref}" == *":rpi-catalog" || "${ref}" == *":x86-catalog" || "${ref}" == *":catalog-arm64" || "${ref}" == *":catalog-amd64" ]]; then
                      if [[ -n "${STUB_CATALOG_PULL_ERROR:-}" ]]; then
                        echo "${STUB_CATALOG_PULL_ERROR}" >&2
                        exit 17
                      fi
                      if [[ "${STUB_MISSING_CATALOG:-1}" == "1" ]]; then
                        echo "manifest not found" >&2
                        exit 1
                      fi
                      out=""
                      while [[ $# -gt 0 ]]; do
                        if [[ "$1" == "-o" ]]; then
                          out="$2"
                          shift 2
                        else
                          shift
                        fi
                      done
                      mkdir -p "${out}"
                      printf '%s\\n' "${STUB_EXISTING_CATALOG_CONTENT:-}" > "${out}/catalog.tsv"
                      exit 0
                    fi
                    echo "unexpected oras pull: ${ref}" >&2
                    exit 92
                    ;;
                  push)
                    ref="${2:?}"
                    if [[ "${ref}" == *":rpi-catalog" || "${ref}" == *":x86-catalog" || "${ref}" == *":catalog-arm64" || "${ref}" == *":catalog-amd64" ]]; then
                      cp catalog.tsv "${STUB_CAPTURE_DIR}/catalog.tsv"
                      exit 0
                    fi
                    echo "unexpected oras push: ${ref}" >&2
                    exit 93
                    ;;
                  *)
                    echo "unexpected oras command: ${cmd}" >&2
                    exit 94
                    ;;
                esac
                """
            ),
            encoding="utf-8",
        )
        stub_path.chmod(0o755)
        return stub_path

    def run_main(self, argv: list[str]) -> int:
        return module.main(argv)

    def test_write_metadata_shell_safe(self) -> None:
        with tempfile.TemporaryDirectory(prefix="release-control-test-") as tmpdir:
            tmp = Path(tmpdir)
            env_output = tmp / "meta.env"
            json_output = tmp / "meta.json"
            rc = self.run_main(
                [
                    "write-metadata",
                    "--input-json",
                    str(TESTDATA / "artifact-meta-flat.json"),
                    "--env-output",
                    str(env_output),
                    "--json-output",
                    str(json_output),
                ]
            )
            self.assertEqual(rc, 0)
            self.assertEqual(json.loads(json_output.read_text(encoding="utf-8"))["EMPTY_VALUE"], "")
            subprocess.run(
                [
                    "bash",
                    "-lc",
                    (
                        f"set -euo pipefail; source {env_output}; "
                        "[ \"$GITHUB_WORKFLOW\" = 'Official Candidate Build & Publish (Matchbox)' ]; "
                        "[ \"$SPECIAL\" = 'A & B: (demo)' ]; "
                        "[ \"$EMPTY_VALUE\" = '' ]"
                    ),
                ],
                check=True,
            )

    def test_write_metadata_rejects_non_shell_identifier_keys(self) -> None:
        with tempfile.TemporaryDirectory(prefix="release-control-test-") as tmpdir:
            tmp = Path(tmpdir)
            bad_input = tmp / "bad-meta.json"
            bad_input.write_text(json.dumps({"BUILD-TS": "2026-03-09T05:27:45Z"}) + "\n", encoding="utf-8")
            with self.assertRaises(SystemExit):
                self.run_main(
                    [
                        "write-metadata",
                        "--input-json",
                        str(bad_input),
                        "--env-output",
                        str(tmp / "meta.env"),
                        "--json-output",
                        str(tmp / "meta.json"),
                    ]
                )

    def test_build_candidate_provenance_rejects_invalid_inputs(self) -> None:
        base = json.loads((TESTDATA / "candidate-provenance-matchbox.json").read_text(encoding="utf-8"))

        scenarios: list[tuple[str, dict]] = []

        missing_role = json.loads(json.dumps(base))
        del missing_role["artifacts"]["installer"]
        scenarios.append(("missing artifact role", missing_role))

        mismatched_digest = json.loads(json.dumps(base))
        mismatched_digest["artifacts"]["os"]["artifact_digest"] = (
            "sha256:9999999999999999999999999999999999999999999999999999999999999999"
        )
        scenarios.append(("mismatched digest", mismatched_digest))

        unknown_git_sha = json.loads(json.dumps(base))
        unknown_git_sha["artifacts"]["os"]["control_fields"]["git_sha"] = "unknown"
        scenarios.append(("unknown git sha", unknown_git_sha))

        mismatched_variant = json.loads(json.dumps(base))
        mismatched_variant["artifacts"]["installer"]["control_fields"]["variant"] = "dev"
        scenarios.append(("mismatched variant", mismatched_variant))

        for label, payload in scenarios:
            with self.subTest(label=label), tempfile.TemporaryDirectory(prefix="release-control-test-") as tmpdir:
                tmp = Path(tmpdir)
                os_record = tmp / "os.json"
                installer_record = tmp / "installer.json"
                output = tmp / "candidate-provenance.json"
                if "os" in payload["artifacts"]:
                    os_record.write_text(json.dumps(payload["artifacts"]["os"], indent=2) + "\n", encoding="utf-8")
                else:
                    os_record.write_text("{}", encoding="utf-8")
                if "installer" in payload["artifacts"]:
                    installer_record.write_text(
                        json.dumps(payload["artifacts"]["installer"], indent=2) + "\n",
                        encoding="utf-8",
                    )
                else:
                    installer_record.write_text("{}", encoding="utf-8")

                with self.assertRaises(SystemExit):
                    self.run_main(
                        [
                            "build-candidate-provenance",
                            "--source-repo-url",
                            payload["source_repo"],
                            "--source-commit",
                            payload["source_commit"],
                            "--candidate-workflow",
                            payload["candidate_workflow"],
                            "--candidate-run-id",
                            payload["candidate_run_id"],
                            "--candidate-run-attempt",
                            payload["candidate_run_attempt"],
                            "--os-record",
                            str(os_record),
                            "--installer-record",
                            str(installer_record),
                            "--output",
                            str(output),
                        ]
                    )

    def test_validate_candidate_provenance_accepts_matchbox_and_woodbox(self) -> None:
        for fixture in ("candidate-provenance-matchbox.json", "candidate-provenance-woodbox.json"):
            with self.subTest(fixture=fixture):
                payload = json.loads((TESTDATA / fixture).read_text(encoding="utf-8"))
                rc = self.run_main(
                    [
                        "validate-candidate-provenance",
                        "--input",
                        str(TESTDATA / fixture),
                        "--expected-source-commit",
                        payload["source_commit"],
                    ]
                )
                self.assertEqual(rc, 0)

    def test_update_catalog_renders_matchbox_and_woodbox_rows(self) -> None:
        cases = [
            (
                "candidate-provenance-matchbox.json",
                "ghcr.io/techofourown/ourbox-matchbox-os",
                "rpi-catalog",
                "application/vnd.techofourown.ourbox.matchbox.os-catalog.v1",
                "rpi-stable",
                "target-qualified",
                "img_sha256",
                TESTDATA / "matchbox-catalog.tsv",
            ),
            (
                "candidate-provenance-woodbox.json",
                "ghcr.io/techofourown/ourbox-woodbox-os",
                "x86-catalog",
                "application/vnd.techofourown.ourbox.woodbox.os-catalog.v1",
                "x86-stable",
                "short",
                "payload_sha256",
                TESTDATA / "woodbox-catalog.tsv",
            ),
        ]
        for fixture, artifact_repo, catalog_tag, artifact_type, channel_tag, channel_mode, sha_column, expected_tsv in cases:
            with self.subTest(fixture=fixture), tempfile.TemporaryDirectory(prefix="release-control-test-") as tmpdir:
                tmp = Path(tmpdir)
                stub_dir = tmp / "bin"
                capture_dir = tmp / "capture"
                log_path = tmp / "oras.log"
                stub_dir.mkdir()
                capture_dir.mkdir()
                self.write_stub_oras(stub_dir)
                artifact_record = json.loads((TESTDATA / fixture).read_text(encoding="utf-8"))["artifacts"]["os"]
                artifact_record_path = tmp / "artifact-record.json"
                artifact_record_path.write_text(json.dumps(artifact_record, indent=2) + "\n", encoding="utf-8")
                env = {
                    "PATH": f"{stub_dir}:{os.environ['PATH']}",
                    "STUB_ORAS_LOG": str(log_path),
                    "STUB_CAPTURE_DIR": str(capture_dir),
                    "STUB_MISSING_CATALOG": "1",
                }
                with EnvOverride(**env):
                    rc = self.run_main(
                        [
                            "update-catalog",
                            "--artifact-record",
                            str(artifact_record_path),
                            "--artifact-repo",
                            artifact_repo,
                            "--catalog-tag",
                            catalog_tag,
                            "--catalog-artifact-type",
                            artifact_type,
                            "--channel-tag",
                            channel_tag,
                            "--channel-mode",
                            channel_mode,
                            "--sha-column",
                            sha_column,
                            "--timestamp",
                            "2026-03-09T07:00:00Z",
                        ]
                    )
                self.assertEqual(rc, 0)
                self.assertEqual(
                    (capture_dir / "catalog.tsv").read_text(encoding="utf-8"),
                    expected_tsv.read_text(encoding="utf-8"),
                )

    def test_update_catalog_fails_on_non_not_found_pull_error(self) -> None:
        with tempfile.TemporaryDirectory(prefix="release-control-test-") as tmpdir:
            tmp = Path(tmpdir)
            stub_dir = tmp / "bin"
            capture_dir = tmp / "capture"
            log_path = tmp / "oras.log"
            stub_dir.mkdir()
            capture_dir.mkdir()
            self.write_stub_oras(stub_dir)
            artifact_record = json.loads((TESTDATA / "candidate-provenance-matchbox.json").read_text(encoding="utf-8"))[
                "artifacts"
            ]["os"]
            artifact_record_path = tmp / "artifact-record.json"
            artifact_record_path.write_text(json.dumps(artifact_record, indent=2) + "\n", encoding="utf-8")
            env = {
                "PATH": f"{stub_dir}:{os.environ['PATH']}",
                "STUB_ORAS_LOG": str(log_path),
                "STUB_CAPTURE_DIR": str(capture_dir),
                "STUB_CATALOG_PULL_ERROR": "unauthorized: authentication required",
            }
            with EnvOverride(**env), self.assertRaises(SystemExit):
                self.run_main(
                    [
                        "update-catalog",
                        "--artifact-record",
                        str(artifact_record_path),
                        "--artifact-repo",
                        "ghcr.io/techofourown/ourbox-matchbox-os",
                        "--catalog-tag",
                        "rpi-catalog",
                        "--catalog-artifact-type",
                        "application/vnd.techofourown.ourbox.matchbox.os-catalog.v1",
                        "--channel-tag",
                        "rpi-stable",
                        "--channel-mode",
                        "target-qualified",
                        "--sha-column",
                        "img_sha256",
                        "--timestamp",
                        "2026-03-09T07:00:00Z",
                    ]
                )
            self.assertFalse((capture_dir / "catalog.tsv").exists())

    def test_update_catalog_renders_append_only_airgap_rows(self) -> None:
        with tempfile.TemporaryDirectory(prefix="release-control-test-") as tmpdir:
            tmp = Path(tmpdir)
            stub_dir = tmp / "bin"
            capture_dir = tmp / "capture"
            log_path = tmp / "oras.log"
            stub_dir.mkdir()
            capture_dir.mkdir()
            self.write_stub_oras(stub_dir)

            artifact_record = {
                "schema": 1,
                "artifact_family": "airgap-platform",
                "artifact_type": "application/vnd.techofourown.ourbox.airgap-platform.v1.tar+gzip",
                "artifact_repo": "ghcr.io/techofourown/sw-ourbox-os/airgap-platform",
                "artifact_ref": "ghcr.io/techofourown/sw-ourbox-os/airgap-platform:main-6472fb5919d1-arm64",
                "artifact_pinned_ref": "ghcr.io/techofourown/sw-ourbox-os/airgap-platform@sha256:3f228e4a091b017f156224c663648158d774c7dfcefefdc1cda303023ce20014",
                "artifact_digest": "sha256:3f228e4a091b017f156224c663648158d774c7dfcefefdc1cda303023ce20014",
                "source_repo": "https://github.com/techofourown/sw-ourbox-os",
                "source_commit": "6472fb5919d187daf832082eeaef6086b336a632",
                "source_version": "dev",
                "created": "2026-03-11T04:56:15Z",
                "artifact_metadata": {
                    "OURBOX_AIRGAP_PLATFORM_SOURCE": "https://github.com/techofourown/sw-ourbox-os",
                    "OURBOX_AIRGAP_PLATFORM_REVISION": "6472fb5919d187daf832082eeaef6086b336a632",
                    "OURBOX_AIRGAP_PLATFORM_VERSION": "dev",
                    "OURBOX_AIRGAP_PLATFORM_CREATED": "2026-03-11T04:56:15Z",
                    "AIRGAP_PLATFORM_ARCH": "arm64",
                },
                "input_metadata": {
                    "K3S_VERSION": "v1.35.0+k3s1",
                    "OURBOX_PLATFORM_PROFILE": "demo-apps",
                    "OURBOX_PLATFORM_CONTRACT_DIGEST": "sha256:134129e3edaf366728f30c6f86f431c02ec9200793f77f18495cd4d341d90157",
                    "OURBOX_PLATFORM_IMAGES_LOCK_SHA256": "f6d6171f7065059b7d7008961d0fecc5b7d65075dd7c7c3514ee5d8418f48118",
                },
                "dist_files": {
                    "payload": "dist/airgap-platform.tar.gz",
                    "meta_env": "dist/airgap-platform.meta.env",
                    "push_log": "dist/airgap-platform.arm64.push.log",
                    "pinned_ref": "dist/airgap-platform.arm64.ref",
                },
            }
            artifact_record_path = tmp / "artifact-record.json"
            artifact_record_path.write_text(json.dumps(artifact_record, indent=2) + "\n", encoding="utf-8")
            existing_catalog = "\n".join(
                [
                    "channel\ttag\tcreated\tversion\trevision\tarch\tplatform_contract_digest\tplatform_profile\tk3s_version\tplatform_images_lock_sha256\tartifact_digest\tpinned_ref",
                    "beta\tmain-old-arm64\t2026-03-10T00:00:00Z\tv0.15.0\t1111111111111111111111111111111111111111\tarm64\tsha256:134129e3edaf366728f30c6f86f431c02ec9200793f77f18495cd4d341d90157\tdemo-apps\tv1.35.0+k3s1\t1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef\tsha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\tghcr.io/techofourown/sw-ourbox-os/airgap-platform@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                ]
            )
            env = {
                "PATH": f"{stub_dir}:{os.environ['PATH']}",
                "STUB_ORAS_LOG": str(log_path),
                "STUB_CAPTURE_DIR": str(capture_dir),
                "STUB_MISSING_CATALOG": "0",
                "STUB_EXISTING_CATALOG_CONTENT": existing_catalog,
            }
            with EnvOverride(**env):
                rc = self.run_main(
                    [
                        "update-catalog",
                        "--catalog-family",
                        "airgap-platform",
                        "--artifact-record",
                        str(artifact_record_path),
                        "--artifact-repo",
                        "ghcr.io/techofourown/sw-ourbox-os/airgap-platform",
                        "--catalog-tag",
                        "catalog-arm64",
                        "--catalog-artifact-type",
                        "application/vnd.techofourown.ourbox.airgap-platform.catalog.v1",
                        "--channel-tag",
                        "stable",
                        "--channel-mode",
                        "short",
                        "--immutable-tag-override",
                        "v0.15.1-arm64",
                        "--version-override",
                        "v0.15.1",
                        "--timestamp",
                        "2026-03-11T05:00:00Z",
                    ]
                )
            self.assertEqual(rc, 0)
            self.assertEqual(
                (capture_dir / "catalog.tsv").read_text(encoding="utf-8"),
                "\n".join(
                    [
                        "channel\ttag\tcreated\tversion\trevision\tarch\tplatform_contract_digest\tplatform_profile\tk3s_version\tplatform_images_lock_sha256\tartifact_digest\tpinned_ref",
                        "beta\tmain-old-arm64\t2026-03-10T00:00:00Z\tv0.15.0\t1111111111111111111111111111111111111111\tarm64\tsha256:134129e3edaf366728f30c6f86f431c02ec9200793f77f18495cd4d341d90157\tdemo-apps\tv1.35.0+k3s1\t1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef\tsha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\tghcr.io/techofourown/sw-ourbox-os/airgap-platform@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                        "stable\tv0.15.1-arm64\t2026-03-11T05:00:00Z\tv0.15.1\t6472fb5919d187daf832082eeaef6086b336a632\tarm64\tsha256:134129e3edaf366728f30c6f86f431c02ec9200793f77f18495cd4d341d90157\tdemo-apps\tv1.35.0+k3s1\tf6d6171f7065059b7d7008961d0fecc5b7d65075dd7c7c3514ee5d8418f48118\tsha256:3f228e4a091b017f156224c663648158d774c7dfcefefdc1cda303023ce20014\tghcr.io/techofourown/sw-ourbox-os/airgap-platform@sha256:3f228e4a091b017f156224c663648158d774c7dfcefefdc1cda303023ce20014",
                        "",
                    ]
                ),
            )

    def test_promote_reconstructs_metadata_without_source_artifact_pull(self) -> None:
        cases = [
            (
                "candidate-provenance-matchbox.json",
                "promote-os",
                "os",
                [
                    "--artifact-repo",
                    "ghcr.io/techofourown/ourbox-matchbox-os",
                    "--expected-artifact-kind",
                    "os-image",
                    "--expected-artifact-type",
                    "application/vnd.techofourown.ourbox.matchbox.os-image.v1",
                    "--expected-target",
                    "rpi",
                    "--expected-variant",
                    "prod",
                    "--expected-sku",
                    "TOO-OBX-MBX-BASE-001",
                    "--immutable-tag",
                    "v0.10.3-rpi",
                    "--channel-tags",
                    "rpi-stable",
                    "--catalog-tag",
                    "rpi-catalog",
                    "--catalog-artifact-type",
                    "application/vnd.techofourown.ourbox.matchbox.os-catalog.v1",
                    "--channel-mode",
                    "target-qualified",
                    "--sha-column",
                    "img_sha256",
                ],
            ),
            (
                "candidate-provenance-matchbox.json",
                "promote-installer",
                "installer",
                [
                    "--artifact-repo",
                    "ghcr.io/techofourown/ourbox-matchbox-installer",
                    "--expected-artifact-kind",
                    "installer-image",
                    "--expected-artifact-type",
                    "application/vnd.techofourown.ourbox.matchbox.installer-image.v1",
                    "--expected-target",
                    "rpi",
                    "--expected-variant",
                    "prod",
                    "--expected-sku",
                    "TOO-OBX-MBX-BASE-001",
                    "--immutable-tag",
                    "v0.10.3-rpi-installer",
                    "--channel-tags",
                    "rpi-installer-stable",
                ],
            ),
        ]

        for fixture, subcommand, role_prefix, extra_args in cases:
            with self.subTest(subcommand=subcommand), tempfile.TemporaryDirectory(prefix="release-control-test-") as tmpdir:
                tmp = Path(tmpdir)
                stub_dir = tmp / "bin"
                capture_dir = tmp / "capture"
                deploy_dir = tmp / "deploy"
                log_path = tmp / "oras.log"
                stub_dir.mkdir()
                capture_dir.mkdir()
                deploy_dir.mkdir()
                self.write_stub_oras(stub_dir)
                provenance = json.loads((TESTDATA / fixture).read_text(encoding="utf-8"))
                env = {
                    "PATH": f"{stub_dir}:{os.environ['PATH']}",
                    "STUB_ORAS_LOG": str(log_path),
                    "STUB_CAPTURE_DIR": str(capture_dir),
                    "STUB_MISSING_CATALOG": "1",
                    "STUB_DISALLOWED_PULL_REF": provenance["artifacts"][role_prefix]["artifact_pinned_ref"],
                }
                with EnvOverride(**env):
                    rc = self.run_main(
                        [
                            subcommand,
                            "--provenance",
                            str(TESTDATA / fixture),
                            "--release-tag",
                            "v0.10.3",
                            "--promotion-context",
                            "stable",
                            *extra_args,
                            "--deploy-dir",
                            str(deploy_dir),
                        ]
                    )
                self.assertEqual(rc, 0)
                self.assertTrue((deploy_dir / f"{role_prefix}-artifact.meta.env").is_file())
                self.assertTrue((deploy_dir / f"{role_prefix}-artifact.meta.json").is_file())
                self.assertTrue((deploy_dir / f"{role_prefix}-artifact.promote.json").is_file())
                log_text = log_path.read_text(encoding="utf-8")
                self.assertNotIn(f"pull {provenance['artifacts'][role_prefix]['artifact_pinned_ref']}", log_text)


if __name__ == "__main__":
    unittest.main()
