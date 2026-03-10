#!/usr/bin/env python3
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

import sys
sys.path.insert(0, str(ROOT / "tools" / "policy"))
from json_schema_validate import validate_instance


REQUIRED_KEYS = {
    "platform-contract": {
        "artifact_metadata": [
            "OURBOX_PLATFORM_CONTRACT_SOURCE",
            "OURBOX_PLATFORM_CONTRACT_REVISION",
            "OURBOX_PLATFORM_CONTRACT_VERSION",
            "OURBOX_PLATFORM_CONTRACT_CREATED",
        ],
        "input_metadata": ["PROFILE_DEFAULT"],
        "dist_files": ["payload", "meta_env", "push_log", "pinned_ref"],
    },
    "install-defaults": {
        "artifact_metadata": [
            "OURBOX_INSTALL_DEFAULTS_SOURCE",
            "OURBOX_INSTALL_DEFAULTS_REVISION",
            "OURBOX_INSTALL_DEFAULTS_VERSION",
            "OURBOX_INSTALL_DEFAULTS_CREATED",
        ],
        "input_metadata": ["PROFILE_COUNT", "PROFILE_IDS"],
        "dist_files": ["payload", "meta_env", "push_log", "pinned_ref"],
    },
    "airgap-platform": {
        "artifact_metadata": [
            "OURBOX_AIRGAP_PLATFORM_SOURCE",
            "OURBOX_AIRGAP_PLATFORM_REVISION",
            "OURBOX_AIRGAP_PLATFORM_VERSION",
            "OURBOX_AIRGAP_PLATFORM_CREATED",
            "AIRGAP_PLATFORM_ARCH",
        ],
        "input_metadata": ["K3S_VERSION", "OURBOX_PLATFORM_PROFILE", "OURBOX_PLATFORM_IMAGES_LOCK_SHA256"],
        "dist_files": ["payload", "meta_env", "push_log", "pinned_ref"],
    },
}


def ensure_required_map_keys(family: str, kind: str, values: dict[str, str]) -> None:
    missing = [k for k in REQUIRED_KEYS[family][kind] if k not in values]
    if missing:
        raise SystemExit(f"Missing required {kind} keys for {family}: {', '.join(missing)}")


def parse_json_map(raw: str, name: str) -> dict[str, str]:
    data = json.loads(raw)
    if not isinstance(data, dict) or not all(isinstance(k, str) and isinstance(v, str) for k, v in data.items()):
        raise SystemExit(f"{name} must be a JSON object of string:string pairs")
    return data


def main() -> int:
    parser = argparse.ArgumentParser(description="Write and validate artifact publish records")
    parser.add_argument("--output", required=True)
    parser.add_argument("--artifact-family", required=True)
    parser.add_argument("--artifact-type", required=True)
    parser.add_argument("--artifact-repo", required=True)
    parser.add_argument("--artifact-ref", required=True)
    parser.add_argument("--artifact-pinned-ref", required=True)
    parser.add_argument("--artifact-digest", required=True)
    parser.add_argument("--source-repo", required=True)
    parser.add_argument("--source-commit", required=True)
    parser.add_argument("--source-version", required=True)
    parser.add_argument("--created", required=True)
    parser.add_argument("--artifact-metadata-json", required=True)
    parser.add_argument("--input-metadata-json", required=True)
    parser.add_argument("--dist-files-json", required=True)
    args = parser.parse_args()

    family = args.artifact_family
    if family not in REQUIRED_KEYS:
        raise SystemExit(f"Unsupported artifact family: {family}")

    artifact_metadata = parse_json_map(args.artifact_metadata_json, "artifact_metadata")
    input_metadata = parse_json_map(args.input_metadata_json, "input_metadata")
    dist_files = parse_json_map(args.dist_files_json, "dist_files")

    ensure_required_map_keys(family, "artifact_metadata", artifact_metadata)
    ensure_required_map_keys(family, "input_metadata", input_metadata)
    ensure_required_map_keys(family, "dist_files", dist_files)

    record = {
        "schema": 1,
        "artifact_family": family,
        "artifact_type": args.artifact_type,
        "artifact_repo": args.artifact_repo,
        "artifact_ref": args.artifact_ref,
        "artifact_pinned_ref": args.artifact_pinned_ref,
        "artifact_digest": args.artifact_digest,
        "source_repo": args.source_repo,
        "source_commit": args.source_commit,
        "source_version": args.source_version,
        "created": args.created,
        "artifact_metadata": artifact_metadata,
        "input_metadata": input_metadata,
        "dist_files": dist_files,
    }

    schema_path = ROOT / "schemas" / "artifact-publish-record.schema.json"
    schema = json.loads(schema_path.read_text(encoding="utf-8"))
    errors = validate_instance(record, schema)
    if errors:
        raise SystemExit("Publish record schema validation failed:\n" + "\n".join(f"- {e}" for e in errors))

    output_path = (ROOT / args.output) if not args.output.startswith("/") else Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote publish record: {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
