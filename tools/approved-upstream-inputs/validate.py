#!/usr/bin/env python3
import argparse
import json
import shutil
import subprocess
import tarfile
import tempfile
from pathlib import Path


def run(cmd: list[str], *, capture: bool = False) -> str:
    completed = subprocess.run(
        cmd,
        check=True,
        text=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
    )
    return completed.stdout.strip() if capture else ""


def resolve_digest(ref: str) -> str:
    digest = run(["oras", "resolve", ref], capture=True)
    if not digest.startswith("sha256:"):
        raise SystemExit(f"oras resolve returned a non-digest for {ref}: {digest!r}")
    return digest


def ensure_digest_pair(name: str, versioned_ref: str, pinned_ref: str, expected_digest: str) -> None:
    resolved_versioned = resolve_digest(versioned_ref)
    resolved_pinned = resolve_digest(pinned_ref)
    actual_pinned = pinned_ref.rsplit("@", 1)[-1]
    if resolved_versioned != expected_digest:
        raise SystemExit(
            f"{name} versioned ref {versioned_ref} resolved to {resolved_versioned}, expected {expected_digest}"
        )
    if resolved_pinned != expected_digest:
        raise SystemExit(
            f"{name} pinned ref {pinned_ref} resolved to {resolved_pinned}, expected {expected_digest}"
        )
    if actual_pinned != expected_digest:
        raise SystemExit(
            f"{name} pinned ref {pinned_ref} does not embed expected digest {expected_digest}"
        )


def verify_platform_contract(platform_contract: dict[str, str]) -> None:
    marker = platform_contract["required_route_marker"]

    with tempfile.TemporaryDirectory(prefix="approved-platform-contract-") as tmpdir:
        tmp_path = Path(tmpdir)
        pull_dir = tmp_path / "pull"
        extract_dir = tmp_path / "extract"

        run(["oras", "pull", platform_contract["versioned_ref"], "-o", str(pull_dir)])

        tarball = pull_dir / "dist" / "platform-contract.tar.gz"
        if not tarball.is_file():
            raise SystemExit(f"Missing pulled platform contract tarball: {tarball}")

        extract_dir.mkdir(parents=True, exist_ok=True)
        with tarfile.open(tarball, "r:gz") as handle:
            handle.extractall(extract_dir)

        contract_root = extract_dir / "platform-contract"
        landing_html = contract_root / "landing" / "index.html"
        routes_tsv = contract_root / "rendered" / "defaults" / "demo-apps" / "verification" / "http-routes.tsv"

        if marker not in landing_html.read_text(encoding="utf-8"):
            raise SystemExit(
                f"Platform contract landing page does not contain required marker {marker!r}"
            )

        if not routes_tsv.is_file():
            raise SystemExit(f"Missing rendered verification routes file: {routes_tsv}")

        found_landing_route = False
        for raw_line in routes_tsv.read_text(encoding="utf-8").splitlines():
            if not raw_line or raw_line.startswith("host\t"):
                continue
            host, path, expected_status, body_marker, description = raw_line.split("\t", 4)
            if description == "landing-root":
                found_landing_route = True
                if expected_status != "200":
                    raise SystemExit(
                        f"landing-root route expected_status is {expected_status}, expected 200"
                    )
                if body_marker != marker:
                    raise SystemExit(
                        f"landing-root marker is {body_marker!r}, expected {marker!r}"
                    )
                if path != "/":
                    raise SystemExit(f"landing-root path is {path!r}, expected '/'")
        if not found_landing_route:
            raise SystemExit("verification/http-routes.tsv is missing the landing-root route")


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate the approved upstream input snapshot.")
    parser.add_argument("--approved-inputs", required=True, help="Path to approved-upstream-inputs.json")
    args = parser.parse_args()

    if shutil.which("oras") is None:
        raise SystemExit("oras is required to validate approved upstream inputs")

    approved_inputs_path = Path(args.approved_inputs).resolve()
    snapshot = json.loads(approved_inputs_path.read_text(encoding="utf-8"))

    if snapshot.get("schema") != 1:
        raise SystemExit("approved-upstream-inputs.json schema must be 1")
    if not str(snapshot.get("approved_release_tag", "")).startswith("v"):
        raise SystemExit("approved_release_tag must be a version tag such as v0.10.1")

    platform_contract = snapshot["platform_contract"]
    ensure_digest_pair(
        "platform-contract",
        platform_contract["versioned_ref"],
        platform_contract["pinned_ref"],
        platform_contract["digest"],
    )
    verify_platform_contract(platform_contract)

    for arch in ("arm64", "amd64"):
        airgap = snapshot["airgap_platform"][arch]
        ensure_digest_pair(
            f"airgap-platform/{arch}",
            airgap["versioned_ref"],
            airgap["pinned_ref"],
            airgap["digest"],
        )

    print(
        "Validated approved upstream inputs:",
        snapshot["approved_release_tag"],
        platform_contract["digest"],
        snapshot["airgap_platform"]["arm64"]["digest"],
        snapshot["airgap_platform"]["amd64"]["digest"],
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
