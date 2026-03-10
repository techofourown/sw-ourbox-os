#!/usr/bin/env python3
import argparse
import json
from pathlib import Path

from json_schema_validate import validate_instance


def validate_file(schema_path: Path, data_path: Path) -> None:
    schema = json.loads(schema_path.read_text(encoding="utf-8"))
    data = json.loads(data_path.read_text(encoding="utf-8"))
    errors = validate_instance(data, schema)
    if errors:
        details = "\n".join(f"- {e}" for e in errors)
        raise SystemExit(f"Schema validation failed for {data_path}:\n{details}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate repository schema contract files")
    parser.add_argument("--approved-only", action="store_true")
    parser.add_argument("--publish-record", action="append", default=[])
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[2]
    approved_schema = root / "schemas" / "approved-upstream-inputs.schema.json"
    publish_schema = root / "schemas" / "artifact-publish-record.schema.json"

    validate_file(approved_schema, root / "release" / "approved-upstream-inputs.json")

    if not args.approved_only:
        fixture_dir = root / "tools" / "publish-records" / "fixtures"
        for fixture in sorted(fixture_dir.glob("*.json")):
            validate_file(publish_schema, fixture)

        for explicit in args.publish_record:
            validate_file(publish_schema, (root / explicit).resolve() if not explicit.startswith("/") else Path(explicit))

        for dist_record in sorted((root / "dist").glob("*.publish-record.json")):
            validate_file(publish_schema, dist_record)

    print("Schema validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
