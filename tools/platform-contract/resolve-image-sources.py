#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import subprocess
from pathlib import Path


DIGEST_RE = re.compile(r"^sha256:[0-9a-f]{64}$")
PINNED_REF_RE = re.compile(r"^[^\s]+@sha256:[0-9a-f]{64}$")


def fail(message: str) -> "NoReturn":
    raise SystemExit(message)


def repository_for_ref(ref: str) -> str:
    without_digest = ref.split("@", 1)[0]
    last_slash = without_digest.rfind("/")
    last_colon = without_digest.rfind(":")
    if last_colon > last_slash:
        return without_digest[:last_colon]
    return without_digest


def resolve_pinned_ref(ref: str) -> str:
    if PINNED_REF_RE.fullmatch(ref):
        return ref

    digest = subprocess.run(
        ["oras", "resolve", ref],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()
    if not DIGEST_RE.fullmatch(digest):
        fail(f"oras resolve returned an invalid digest for {ref!r}: {digest!r}")
    return f"{repository_for_ref(ref)}@{digest}"


def load_catalog_expectations(catalog_path: Path) -> dict[str, set[str]]:
    catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    if catalog.get("schema") != 1 or catalog.get("kind") != "ourbox-application-catalog":
        fail(f"{catalog_path} must declare schema=1 and kind=ourbox-application-catalog")

    apps = catalog.get("apps")
    if not isinstance(apps, list) or not apps:
        fail(f"{catalog_path} must declare a non-empty apps list")

    expected: dict[str, set[str]] = {}
    app_ids: set[str] = set()
    for app in apps:
        app_id = str(app.get("id", "")).strip()
        if not app_id:
            fail(f"{catalog_path} contains an app without an id")
        if app_id in app_ids:
            fail(f"{catalog_path} contains duplicate app id {app_id!r}")
        app_ids.add(app_id)

        image_names = app.get("image_names")
        if not isinstance(image_names, list) or not image_names:
            fail(f"{catalog_path} app {app_id!r} must declare a non-empty image_names list")
        for raw_name in image_names:
            image_name = str(raw_name).strip()
            if not image_name:
                fail(f"{catalog_path} app {app_id!r} declares an empty image name")
            expected.setdefault(image_name, set()).add(app_id)

    return expected


def main() -> int:
    parser = argparse.ArgumentParser(description="Resolve image source refs into a generated images.lock.json")
    parser.add_argument("--input", required=True, help="Path to image-sources JSON")
    parser.add_argument("--output", required=True, help="Destination images.lock.json path")
    parser.add_argument("--profile", required=True, help="Expected profile name")
    parser.add_argument("--catalog", help="Optional catalog.json used to validate app image coverage")
    parser.add_argument(
        "--require-used-by",
        action="append",
        default=[],
        help="Require each source entry to include this used_by value (may be repeated)",
    )
    args = parser.parse_args()

    input_path = Path(args.input).resolve()
    output_path = Path(args.output).resolve()
    payload = json.loads(input_path.read_text(encoding="utf-8"))
    if payload.get("schema") != 1:
        fail(f"{input_path} must declare schema=1")

    profile = str(payload.get("profile", "")).strip()
    if profile != args.profile:
        fail(f"{input_path} must declare profile={args.profile!r}")

    expected_by_name: dict[str, set[str]] | None = None
    if args.catalog:
        expected_by_name = load_catalog_expectations(Path(args.catalog).resolve())

    required_used_by = {item.strip() for item in args.require_used_by if item.strip()}
    source_entries = payload.get("images")
    if not isinstance(source_entries, list) or not source_entries:
        fail(f"{input_path} must declare a non-empty images list")

    resolved_entries = []
    seen_names: set[str] = set()
    for entry in source_entries:
        name = str(entry.get("name", "")).strip()
        ref = str(entry.get("ref", "")).strip()
        used_by = entry.get("used_by")
        if not name or not ref:
            fail(f"{input_path} entries must declare non-empty name and ref")
        if any(ch.isspace() for ch in ref):
            fail(f"{input_path} ref must be a single-line OCI ref without whitespace: {ref!r}")
        if name in seen_names:
            fail(f"{input_path} contains duplicate image name {name!r}")
        if not isinstance(used_by, list) or not used_by:
            fail(f"{input_path} entry {name!r} must declare a non-empty used_by list")

        normalized_used_by = [str(item).strip() for item in used_by]
        if any(not item for item in normalized_used_by):
            fail(f"{input_path} entry {name!r} contains an empty used_by value")
        used_by_set = set(normalized_used_by)
        if len(used_by_set) != len(normalized_used_by):
            fail(f"{input_path} entry {name!r} contains duplicate used_by values")
        if required_used_by and not required_used_by.issubset(used_by_set):
            required_display = ", ".join(sorted(required_used_by))
            fail(f"{input_path} entry {name!r} must declare used_by including {required_display}")

        if expected_by_name is not None:
            expected = expected_by_name.get(name)
            if not expected:
                fail(f"{input_path} entry {name!r} is not referenced by the catalog")
            if used_by_set != expected:
                fail(
                    f"{input_path} entry {name!r} used_by does not match catalog references: "
                    f"expected {sorted(expected)!r}, got {sorted(used_by_set)!r}"
                )

        resolved_entries.append(
            {
                "name": name,
                "ref": resolve_pinned_ref(ref),
                "used_by": normalized_used_by,
            }
        )
        seen_names.add(name)

    if expected_by_name is not None:
        missing = sorted(set(expected_by_name) - seen_names)
        if missing:
            fail(f"catalog references image names missing from {input_path}: {', '.join(missing)}")

    output = {
        "schema": 1,
        "profile": args.profile,
        "images": resolved_entries,
    }
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(output, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
