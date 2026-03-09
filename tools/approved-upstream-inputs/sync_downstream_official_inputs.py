#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


TARGETS = {
    "matchbox": {
        "title": "Matchbox",
        "airgap_arch": "arm64",
    },
    "woodbox": {
        "title": "Woodbox",
        "airgap_arch": "amd64",
    },
}


def render_content(snapshot: dict, target: str, existing_text: str) -> str:
    meta = TARGETS[target]
    release_tag = snapshot["approved_release_tag"]
    platform_ref = snapshot["platform_contract"]["pinned_ref"]
    airgap_ref = snapshot["airgap_platform"][meta["airgap_arch"]]["pinned_ref"]

    managed_keys = ("PLATFORM_CONTRACT_REF=", "AIRGAP_PLATFORM_REF=")
    existing_lines = existing_text.splitlines()
    last_managed_index = -1
    for idx, line in enumerate(existing_lines):
        if line.startswith(managed_keys):
            last_managed_index = idx

    tail_lines = existing_lines[last_managed_index + 1 :] if last_managed_index >= 0 else []
    while tail_lines and not tail_lines[0].strip():
        tail_lines = tail_lines[1:]

    header_lines = [
        f"# Approved upstream inputs consumed by the official {meta['title']} build.",
        "# PLATFORM_CONTRACT_REF and AIRGAP_PLATFORM_REF are generated from",
        "# sw-ourbox-os/release/approved-upstream-inputs.json.",
        f"# Approved snapshot release: {release_tag}",
        "# Do not hand-edit those two refs here; update the approved snapshot in",
        "# sw-ourbox-os instead.",
        "",
        f"PLATFORM_CONTRACT_REF={platform_ref}",
        f"AIRGAP_PLATFORM_REF={airgap_ref}",
    ]

    output_lines = list(header_lines)
    if tail_lines:
        output_lines.append("")
        output_lines.extend(tail_lines)
    return "\n".join(output_lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Sync a downstream official-inputs.env from the approved snapshot.")
    parser.add_argument("--approved-inputs", required=True, help="Path to release/approved-upstream-inputs.json")
    parser.add_argument("--target", choices=sorted(TARGETS), required=True)
    parser.add_argument("--file", required=True, help="Path to the downstream release/official-inputs.env")
    args = parser.parse_args()

    snapshot = json.loads(Path(args.approved_inputs).read_text(encoding="utf-8"))
    output_path = Path(args.file)
    existing_text = output_path.read_text(encoding="utf-8") if output_path.exists() else ""
    rendered = render_content(snapshot, args.target, existing_text)
    output_path.write_text(rendered, encoding="utf-8")
    print(f"Synced {output_path} from approved snapshot {snapshot['approved_release_tag']} for {args.target}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
