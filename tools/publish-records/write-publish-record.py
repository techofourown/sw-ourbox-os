#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def parse_kv(entries: list[str]) -> dict[str, str]:
    out: dict[str, str] = {}
    for entry in entries:
        if "=" not in entry:
            raise SystemExit(f"Invalid KEY=VALUE entry: {entry}")
        key, value = entry.split("=", 1)
        key = key.strip()
        if not key:
            raise SystemExit(f"Invalid empty key in entry: {entry}")
        out[key] = value
    return out


def parse_env_file(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip()
    return values


def main() -> int:
    parser = argparse.ArgumentParser(description="Write canonical artifact publish record JSON.")
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
    parser.add_argument("--artifact-metadata-env", required=True)
    parser.add_argument("--input", action="append", default=[])
    parser.add_argument("--dist-file", action="append", default=[])
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    artifact_metadata = parse_env_file(Path(args.artifact_metadata_env))
    input_metadata = parse_kv(args.input)
    dist_files = parse_kv(args.dist_file)

    record = {
        "schema": 1,
        "artifact_family": args.artifact_family,
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

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote publish record: {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
