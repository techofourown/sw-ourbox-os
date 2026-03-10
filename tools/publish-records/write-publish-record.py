#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def parse_kv(items: list[str]) -> dict[str, str]:
    out: dict[str, str] = {}
    for item in items:
        key, sep, value = item.partition("=")
        if not sep or not key:
            raise SystemExit(f"Invalid KEY=VALUE pair: {item!r}")
        out[key] = value
    return out


def main() -> int:
    p = argparse.ArgumentParser(description="Write standardized artifact publish-record JSON.")
    p.add_argument("--output", required=True)
    p.add_argument("--artifact-family", required=True)
    p.add_argument("--artifact-type", required=True)
    p.add_argument("--artifact-repo", required=True)
    p.add_argument("--artifact-ref", required=True)
    p.add_argument("--artifact-pinned-ref", required=True)
    p.add_argument("--artifact-digest", required=True)
    p.add_argument("--source-repo", required=True)
    p.add_argument("--source-commit", required=True)
    p.add_argument("--source-version", required=True)
    p.add_argument("--created", required=True)
    p.add_argument("--artifact-metadata", action="append", default=[])
    p.add_argument("--input-metadata", action="append", default=[])
    p.add_argument("--dist-file", action="append", default=[])
    args = p.parse_args()

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
        "artifact_metadata": parse_kv(args.artifact_metadata),
        "input_metadata": parse_kv(args.input_metadata),
        "dist_files": parse_kv(args.dist_file),
    }

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
