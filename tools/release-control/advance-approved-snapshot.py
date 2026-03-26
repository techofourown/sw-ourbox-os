#!/usr/bin/env python3
"""Advance the approved-upstream-inputs snapshot to a new release version.

Usage:
    python3 tools/release-control/advance-approved-snapshot.py v0.25.0
    python3 tools/release-control/advance-approved-snapshot.py v0.25.0 --root /path/to/repo

Reads release/approved-upstream-inputs.json, replaces the snapshot version,
all candidate channel tags (preserving arch suffixes), and all
vendored_modules revision tags with the new version, then writes the result
back.
"""
from __future__ import annotations

import json
import pathlib
import re
import sys


def advance(new_version: str, root: pathlib.Path) -> str:
    """Advance the snapshot and return a summary line."""
    snapshot_path = root / "release" / "approved-upstream-inputs.json"

    with snapshot_path.open("r", encoding="utf-8") as fh:
        data = json.load(fh)

    old_snapshot = data.get("snapshot", "")
    if not old_snapshot:
        raise SystemExit("approved-upstream-inputs.json missing snapshot field")

    data["snapshot"] = new_version

    for _key, artifact in data.get("artifacts", {}).items():
        channels = artifact.get("channels", {})
        for channel_key, channel_value in channels.items():
            if channel_key != "candidate":
                continue
            # Replace version prefix, preserving any arch suffix
            # e.g. "v0.23.4-arm64" -> "v0.25.0-arm64"
            updated = re.sub(
                r"^v\d+\.\d+\.\d+",
                new_version,
                channel_value,
            )
            channels[channel_key] = updated

    for _key, module in data.get("vendored_modules", {}).items():
        revision = module.get("revision", "")
        if not revision:
            continue
        module["revision"] = re.sub(r"^v\d+\.\d+\.\d+", new_version, revision)

    with snapshot_path.open("w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2)
        fh.write("\n")

    return f"advanced approved-upstream-inputs snapshot: {old_snapshot} -> {new_version}"


def main() -> None:
    if len(sys.argv) < 2 or not sys.argv[1].startswith("v"):
        raise SystemExit(
            f"usage: {sys.argv[0]} <version> [--root <path>]"
        )

    new_version = sys.argv[1]

    root = pathlib.Path(__file__).resolve().parent.parent.parent
    if "--root" in sys.argv:
        idx = sys.argv.index("--root")
        if idx + 1 >= len(sys.argv):
            raise SystemExit("--root requires a path argument")
        root = pathlib.Path(sys.argv[idx + 1]).resolve()

    print(advance(new_version, root))


if __name__ == "__main__":
    main()
