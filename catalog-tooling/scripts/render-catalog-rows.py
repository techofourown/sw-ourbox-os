#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import re
from pathlib import Path

PINNED_REF_RE = re.compile(r"^[^\s]+@sha256:[0-9a-f]{64}$")
DIGEST_RE = re.compile(r"^sha256:[0-9a-f]{64}$")
TIMESTAMP_RE = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$")
HEADER = [
    "channel",
    "tag",
    "created",
    "version",
    "revision",
    "arch",
    "platform_contract_digest",
    "platform_profile",
    "platform_images_lock_sha256",
    "artifact_digest",
    "pinned_ref",
]


def load_env(path: Path) -> dict[str, str]:
    data: dict[str, str] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        key, value = line.split("=", 1)
        data[key] = value
    return data


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_existing_rows(path: Path | None) -> list[dict[str, str]]:
    if path is None or not path.is_file():
        return []
    with path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        if reader.fieldnames != HEADER:
            raise SystemExit(f"{path} does not declare the expected catalog.tsv header")
        return [{key: str(value or "").strip() for key, value in row.items()} for row in reader]


def render_row(
    *,
    channel: str,
    immutable_tag: str,
    created: str,
    version: str,
    revision: str,
    arch: str,
    platform_contract_digest: str,
    platform_profile: str,
    images_lock_sha256: str,
    artifact_digest: str,
    pinned_ref: str,
) -> dict[str, str]:
    if not channel:
        raise SystemExit("channel must be non-empty")
    if not immutable_tag:
        raise SystemExit("tag must be non-empty")
    if not TIMESTAMP_RE.fullmatch(created):
        raise SystemExit(f"created must be an RFC3339 UTC timestamp with Z suffix: {created!r}")
    if not version:
        raise SystemExit("version must be non-empty")
    if not revision:
        raise SystemExit("revision must be non-empty")
    if not arch:
        raise SystemExit("arch must be non-empty")
    if not DIGEST_RE.fullmatch(platform_contract_digest):
        raise SystemExit("platform contract digest must be sha256-pinned")
    if not platform_profile:
        raise SystemExit("platform profile must be non-empty")
    if not re.fullmatch(r"[0-9a-f]{64}", images_lock_sha256):
        raise SystemExit("images lock sha256 must be a plain 64-character hex digest")
    if not DIGEST_RE.fullmatch(artifact_digest):
        raise SystemExit("artifact digest must be sha256-pinned")
    if not PINNED_REF_RE.fullmatch(pinned_ref):
        raise SystemExit("pinned ref must be digest-pinned")

    return {
        "channel": channel,
        "tag": immutable_tag,
        "created": created,
        "version": version,
        "revision": revision,
        "arch": arch,
        "platform_contract_digest": platform_contract_digest,
        "platform_profile": platform_profile,
        "platform_images_lock_sha256": images_lock_sha256,
        "artifact_digest": artifact_digest,
        "pinned_ref": pinned_ref,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Render installer-browsable catalog rows for an application catalog repo.")
    parser.add_argument("--catalog-json", required=True)
    parser.add_argument("--profile-env", required=True)
    parser.add_argument("--images-lock", required=True)
    parser.add_argument("--existing-catalog")
    parser.add_argument("--out-catalog", required=True)
    parser.add_argument("--channel", default="stable")
    parser.add_argument("--tag", required=True)
    parser.add_argument("--created", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--revision", required=True)
    parser.add_argument("--arch", required=True)
    parser.add_argument("--artifact-digest", required=True)
    parser.add_argument("--pinned-ref", required=True)
    args = parser.parse_args()

    catalog_json = Path(args.catalog_json).resolve()
    profile_env = Path(args.profile_env).resolve()
    images_lock = Path(args.images_lock).resolve()
    existing_catalog = Path(args.existing_catalog).resolve() if args.existing_catalog else None
    out_catalog = Path(args.out_catalog).resolve()

    catalog = json.loads(catalog_json.read_text(encoding="utf-8"))
    profile = load_env(profile_env)
    catalog_id = str(catalog.get("catalog_id", "")).strip()
    if not catalog_id:
        raise SystemExit(f"{catalog_json} must declare catalog_id")
    if str(profile.get("OURBOX_APPLICATION_CATALOG_ID", "")).strip() != catalog_id:
        raise SystemExit(f"{profile_env} OURBOX_APPLICATION_CATALOG_ID does not match {catalog_id!r}")

    existing_rows = load_existing_rows(existing_catalog)
    new_row = render_row(
        channel=str(args.channel).strip(),
        immutable_tag=str(args.tag).strip(),
        created=str(args.created).strip(),
        version=str(args.version).strip(),
        revision=str(args.revision).strip(),
        arch=str(args.arch).strip(),
        platform_contract_digest=os.environ.get("OURBOX_PLATFORM_CONTRACT_DIGEST", "").strip(),
        platform_profile=catalog_id,
        images_lock_sha256=sha256_file(images_lock),
        artifact_digest=str(args.artifact_digest).strip(),
        pinned_ref=str(args.pinned_ref).strip(),
    )

    merged_rows = [
        row
        for row in existing_rows
        if not (row.get("channel") == new_row["channel"] and row.get("tag") == new_row["tag"])
    ]
    merged_rows.append(new_row)
    merged_rows.sort(key=lambda row: row["created"], reverse=True)

    out_catalog.parent.mkdir(parents=True, exist_ok=True)
    with out_catalog.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=HEADER, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        for row in merged_rows:
            writer.writerow(row)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
