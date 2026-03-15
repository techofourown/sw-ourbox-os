#!/usr/bin/env python3
import argparse
import json
from pathlib import Path

import yaml


REQUIRED_LABELS = (
    "app.kubernetes.io/name",
    "app.kubernetes.io/part-of",
    "app.kubernetes.io/managed-by",
    "ourbox.techofourown.io/contract-profile",
    "ourbox.techofourown.io/contract-revision",
    "ourbox.techofourown.io/route-model",
)

REQUIRED_ANNOTATIONS = (
    "ourbox.techofourown.io/contract-source",
    "ourbox.techofourown.io/contract-revision",
    "ourbox.techofourown.io/contract-version",
    "ourbox.techofourown.io/contract-created",
    "ourbox.techofourown.io/contract-digest",
    "ourbox.techofourown.io/box-host",
    "ourbox.techofourown.io/tls-mode",
    "ourbox.techofourown.io/ingress-class",
    "ourbox.techofourown.io/storage-class",
)

EXPECTED_ROUTE_MARKERS = {
    "landing-root": {
        "body_marker": "Your apps, served by your machine, to your phone.",
        "source_file": None,
    },
    "landing-app-status": {
        "body_marker": "ourbox-landing-status",
        "source_file": "landing-status/app.py",
    },
    "dufs-root": {
        "body_marker": "Upload files",
        "source_file": None,
    },
    "flatnotes-root": {
        "body_marker": "flatnotes",
        "source_file": None,
    },
    "todo-bloom-root": {
        "body_marker": "Todo Bloom",
        "source_file": None,
    },
}


def load_resources(manifests_dir: Path) -> list[dict]:
    resources: list[dict] = []
    for manifest_path in sorted(manifests_dir.glob("*.yaml")):
        docs = list(yaml.safe_load_all(manifest_path.read_text(encoding="utf-8")))
        for doc in docs:
            if doc:
                resources.append(doc)
    return resources


def resource_key(resource: dict) -> tuple[str, str, str]:
    metadata = resource.get("metadata", {})
    namespace = metadata.get("namespace", "")
    return resource["kind"], namespace, metadata["name"]


def selector_matches(selector: dict[str, str], labels: dict[str, str]) -> bool:
    return all(labels.get(key) == value for key, value in selector.items())


def get_service_ports(service: dict) -> set[int | str]:
    ports: set[int | str] = set()
    for entry in service.get("spec", {}).get("ports", []):
        if "port" in entry:
            ports.add(entry["port"])
        if "name" in entry:
            ports.add(entry["name"])
    return ports


def wildcard_suffix(host: str) -> str | None:
    if host.startswith("*.") and len(host) > 2:
        return host[1:]
    return None


def load_env_file(path: Path) -> dict[str, str]:
    data: dict[str, str] = {}
    if not path.is_file():
        return data
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        key, value = line.split("=", 1)
        data[key] = value
    return data


def expected_landing_apps(render_dir: Path, selected_app_ids: list[str], box_host: str) -> list[dict[str, str]]:
    catalog_path = render_dir / "catalog.json"
    if catalog_path.is_file():
        catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
        app_by_id = {str(app["id"]): app for app in catalog.get("apps", [])}
        apps: list[dict[str, str]] = []
        for app_id in selected_app_ids:
            app = app_by_id.get(app_id)
            if not app or bool(app.get("default_backend", False)):
                continue
            apps.append(
                {
                    "id": app_id,
                    "name": str(app["display_name"]),
                    "description": str(app["description"]),
                    "host": str(app["host_template"]).format(box_host=box_host),
                    "path": str(app.get("path", "/")),
                    "service_name": str(app["service_name"]),
                }
            )
        return apps

    legacy = {
        "dufs": {
            "id": "dufs",
            "name": "Files",
            "description": "Upload, download, and share files.",
            "host": f"files.{box_host}",
            "path": "/",
            "service_name": "dufs",
        },
        "flatnotes": {
            "id": "flatnotes",
            "name": "Notes",
            "description": "Write and organize markdown notes.",
            "host": f"notes.{box_host}",
            "path": "/",
            "service_name": "flatnotes",
        },
        "todo-bloom": {
            "id": "todo-bloom",
            "name": "Todo",
            "description": "Plan your day with clarity.",
            "host": f"todo.{box_host}",
            "path": "/",
            "service_name": "todo-bloom",
        },
    }
    return [legacy[app_id] for app_id in selected_app_ids if app_id in legacy]


def public_landing_apps(apps: list[dict[str, str]]) -> list[dict[str, str]]:
    return [
        {
            "id": app["id"],
            "name": app["name"],
            "description": app["description"],
            "host": app["host"],
            "path": app["path"],
        }
        for app in apps
    ]


def load_catalog(path: Path) -> dict | None:
    if not path.is_file():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def app_by_id_from_catalog(catalog: dict | None) -> dict[str, dict]:
    if not catalog:
        return {}
    return {str(app["id"]): app for app in catalog.get("apps", [])}


def asset_files_for_dir(contract_root: Path, asset_dir_name: str) -> set[str]:
    asset_dir = contract_root / asset_dir_name
    if not asset_dir.is_dir():
        return set()
    return {path.name for path in sorted(asset_dir.iterdir()) if path.is_file()}


def main() -> int:
    parser = argparse.ArgumentParser(description="Lint a rendered platform contract bundle.")
    parser.add_argument("--contract-root", required=True)
    parser.add_argument("--render-dir", required=True)
    parser.add_argument("--selected-apps-file", help="Optional selected-applications JSON; defaults to render-dir/selected-apps.json when present")
    args = parser.parse_args()

    contract_root = Path(args.contract_root).resolve()
    render_dir = Path(args.render_dir).resolve()
    manifests_dir = render_dir / "manifests"
    if not manifests_dir.is_dir():
        raise SystemExit(f"Missing manifests directory: {manifests_dir}")

    selected_apps_file = Path(args.selected_apps_file).resolve() if args.selected_apps_file else render_dir / "selected-apps.json"
    catalog = load_catalog(render_dir / "catalog.json")
    app_by_id = app_by_id_from_catalog(catalog)
    if selected_apps_file.is_file():
        selected_apps = json.loads(selected_apps_file.read_text(encoding="utf-8"))
        selected_app_ids_list = list(selected_apps.get("selected_app_ids", []))
        selected_app_ids = set(selected_app_ids_list)
        if not selected_app_ids_list:
            raise SystemExit(f"selected-apps file does not declare selected_app_ids: {selected_apps_file}")
    else:
        selected_app_ids_list = ["landing", "todo-bloom", "dufs", "flatnotes"]
        selected_app_ids = {"landing", "todo-bloom", "dufs", "flatnotes"}

    resources = load_resources(manifests_dir)
    resources_by_key = {resource_key(resource): resource for resource in resources}
    deployments = [resource for resource in resources if resource["kind"] == "Deployment"]
    services = [resource for resource in resources if resource["kind"] == "Service"]
    pvcs = [resource for resource in resources if resource["kind"] == "PersistentVolumeClaim"]
    configmaps = [resource for resource in resources if resource["kind"] == "ConfigMap"]
    images_lock = json.loads((render_dir / "images.lock.json").read_text(encoding="utf-8"))
    lock_refs = {
        item["ref"]
        for item in images_lock["images"]
        if selected_app_ids.intersection(set(item.get("used_by", [])))
    }
    metadata_config = resources_by_key.get(("ConfigMap", "ourbox-system", "ourbox-platform-contract"), {})
    platform_images = json.loads(metadata_config.get("data", {}).get("platform_images.json", "{}"))
    platform_refs = set(platform_images.values())
    manifest_image_refs: set[str] = set()
    service_by_ns_name = {
        (svc["metadata"].get("namespace", ""), svc["metadata"]["name"]): svc
        for svc in services
    }
    pvc_names = {(resource["metadata"].get("namespace", ""), resource["metadata"]["name"]) for resource in pvcs}
    errors: list[str] = []

    for resource in resources:
        metadata = resource.get("metadata", {})
        labels = metadata.get("labels", {})
        annotations = metadata.get("annotations", {})
        for label in REQUIRED_LABELS:
            if label not in labels:
                errors.append(f"{resource['kind']}/{metadata.get('name')} missing label {label}")
        for annotation in REQUIRED_ANNOTATIONS:
            if annotation not in annotations:
                errors.append(f"{resource['kind']}/{metadata.get('name')} missing annotation {annotation}")

    for deployment in deployments:
        namespace = deployment["metadata"].get("namespace", "")
        template = deployment.get("spec", {}).get("template", {})
        template_labels = template.get("metadata", {}).get("labels", {})
        selector = deployment.get("spec", {}).get("selector", {}).get("matchLabels", {})
        if not selector_matches(selector, template_labels):
            errors.append(f"Deployment/{deployment['metadata']['name']} selector does not match pod template labels")
        volumes = template.get("spec", {}).get("volumes", [])
        pvc_volume_names = {
            volume["persistentVolumeClaim"]["claimName"]
            for volume in volumes
            if "persistentVolumeClaim" in volume
        }
        if deployment["metadata"].get("labels", {}).get("ourbox.techofourown.io/storage-required") == "true" and not pvc_volume_names:
            errors.append(f"Deployment/{deployment['metadata']['name']} is storage-required but has no PVC volume")
        for pvc_name in pvc_volume_names:
            if (namespace, pvc_name) not in pvc_names:
                errors.append(f"Deployment/{deployment['metadata']['name']} references missing PVC {pvc_name}")
        for container in template.get("spec", {}).get("containers", []):
            manifest_image_refs.add(container["image"])

    if manifest_image_refs != (lock_refs | platform_refs):
        errors.append(
            "Rendered manifest images do not match images.lock.json "
            f"(rendered={sorted(manifest_image_refs)}, lock={sorted(lock_refs)}, platform={sorted(platform_refs)})"
        )

    configmap_names = {(resource["metadata"].get("namespace", ""), resource["metadata"]["name"]) for resource in configmaps}
    expected_asset_maps = {}
    if "landing" in selected_app_ids:
        landing_expected = {"ourbox-apps.json"}
        landing_asset_dir = str(app_by_id.get("landing", {}).get("asset_dir", "")).strip()
        if landing_asset_dir:
            landing_expected.update(asset_files_for_dir(contract_root, landing_asset_dir))
        expected_asset_maps[("ourbox-system", "landing-assets")] = landing_expected
        expected_asset_maps[("ourbox-system", "landing-status-assets")] = {
            path.name for path in sorted((contract_root / "landing-status").iterdir()) if path.is_file()
        }
        expected_asset_maps[("ourbox-system", "landing-status-assets")].add("ourbox-app-targets.json")
    if "todo-bloom" in selected_app_ids:
        todo_bloom_asset_dir = str(app_by_id.get("todo-bloom", {}).get("asset_dir", "")).strip()
        if todo_bloom_asset_dir:
            expected_asset_maps[("ourbox-system", "todo-bloom-assets")] = asset_files_for_dir(
                contract_root,
                todo_bloom_asset_dir,
            )
    for key, expected_files in expected_asset_maps.items():
        if key not in configmap_names:
            errors.append(f"Missing asset ConfigMap {key[1]}")
            continue
        actual_data = set(resources_by_key[("ConfigMap", key[0], key[1])].get("data", {}).keys())
        if actual_data != expected_files:
            errors.append(f"ConfigMap/{key[1]} does not match asset source files")
            continue
        if key == ("ourbox-system", "landing-assets"):
            render_env = load_env_file(render_dir / "render.env")
            box_host = render_env.get("BOX_HOST", "")
            if not box_host:
                errors.append("render.env is missing BOX_HOST required to validate landing app links")
                continue
            expected_payload = json.dumps(
                {
                    "schema": 1,
                    "kind": "ourbox-landing-app-list",
                    "box_host": box_host,
                    "apps": public_landing_apps(expected_landing_apps(render_dir, selected_app_ids_list, box_host)),
                },
                indent=2,
                sort_keys=True,
            ) + "\n"
            actual_payload = resources_by_key[("ConfigMap", key[0], key[1])].get("data", {}).get("ourbox-apps.json")
            if actual_payload != expected_payload:
                errors.append("ConfigMap/landing-assets ourbox-apps.json does not match the selected app set")
        if key == ("ourbox-system", "landing-status-assets"):
            render_env = load_env_file(render_dir / "render.env")
            box_host = render_env.get("BOX_HOST", "")
            if not box_host:
                errors.append("render.env is missing BOX_HOST required to validate landing status targets")
                continue
            expected_payload = json.dumps(
                {
                    "schema": 1,
                    "kind": "ourbox-landing-app-targets",
                    "box_host": box_host,
                    "apps": expected_landing_apps(render_dir, selected_app_ids_list, box_host),
                },
                indent=2,
                sort_keys=True,
            ) + "\n"
            actual_payload = resources_by_key[("ConfigMap", key[0], key[1])].get("data", {}).get("ourbox-app-targets.json")
            if actual_payload != expected_payload:
                errors.append("ConfigMap/landing-status-assets ourbox-app-targets.json does not match the selected app set")

    for service in services:
        namespace = service["metadata"].get("namespace", "")
        selector = service.get("spec", {}).get("selector", {})
        if selector:
            if not any(
                deployment["metadata"].get("namespace", "") == namespace
                and selector_matches(selector, deployment.get("spec", {}).get("template", {}).get("metadata", {}).get("labels", {}))
                for deployment in deployments
            ):
                errors.append(f"Service/{service['metadata']['name']} selector matches no deployment pod template")

    for resource in resources:
        if resource["kind"] != "Ingress":
            continue
        namespace = resource["metadata"].get("namespace", "")
        rule_hosts = [rule.get("host", "") for rule in resource.get("spec", {}).get("rules", []) if rule.get("host")]
        backends = []
        default_backend = resource.get("spec", {}).get("defaultBackend", {})
        if "service" in default_backend:
            backends.append(default_backend["service"])
        for rule in resource.get("spec", {}).get("rules", []):
            for path_entry in rule.get("http", {}).get("paths", []):
                service_ref = path_entry.get("backend", {}).get("service")
                if service_ref:
                    backends.append(service_ref)
        for service_ref in backends:
            key = (namespace, service_ref["name"])
            service = service_by_ns_name.get(key)
            if service is None:
                errors.append(f"Ingress/{resource['metadata']['name']} references missing Service/{service_ref['name']}")
                continue
            port_ref = service_ref.get("port", {})
            expected_port = port_ref.get("number", port_ref.get("name"))
            if expected_port not in get_service_ports(service):
                errors.append(
                    f"Ingress/{resource['metadata']['name']} references Service/{service_ref['name']} port {expected_port}, "
                    "but the service does not expose it"
                )
        for host in rule_hosts:
            suffix = wildcard_suffix(host)
            if suffix is None:
                continue
            overlapping_hosts = [
                other_host
                for other_host in rule_hosts
                if other_host != host and other_host.endswith(suffix)
            ]
            if overlapping_hosts:
                errors.append(
                    f"Ingress/{resource['metadata']['name']} wildcard host {host} overlaps exact hosts {sorted(overlapping_hosts)}"
                )

    routes_file = render_dir / "verification" / "http-routes.tsv"
    if not routes_file.is_file():
        errors.append(f"Missing verification route file: {routes_file}")
    else:
        lines = [line for line in routes_file.read_text(encoding="utf-8").splitlines() if line]
        if len(lines) < 2:
            errors.append("verification/http-routes.tsv does not contain any routes")
        elif lines[0] != "host\tpath\texpected_status\tbody_marker\tdescription":
            errors.append("verification/http-routes.tsv header does not match expected 5-column format")
        else:
            seen_descriptions: set[str] = set()
            for line in lines[1:]:
                parts = line.split("\t")
                if len(parts) != 5:
                    errors.append(f"verification/http-routes.tsv has malformed line: {line}")
                    continue
                host, path, expected_status, body_marker, description = parts
                if not all((host, path, expected_status, body_marker, description)):
                    errors.append(f"verification/http-routes.tsv has empty required field: {line}")
                    continue
                seen_descriptions.add(description)
                expected = EXPECTED_ROUTE_MARKERS.get(description)
                if expected is None:
                    continue
                if body_marker != expected["body_marker"]:
                    errors.append(
                        f"verification/http-routes.tsv route {description} uses marker '{body_marker}', "
                        f"expected '{expected['body_marker']}'"
                    )
                    continue
                source_file = expected["source_file"]
                if source_file:
                    source_path = contract_root / source_file
                    if not source_path.is_file():
                        errors.append(f"verification marker source file missing: {source_path}")
                        continue
                    if expected["body_marker"] not in source_path.read_text(encoding="utf-8"):
                        errors.append(
                            f"verification marker '{expected['body_marker']}' for route {description} "
                            f"not found in source file {source_file}"
                        )
            expected_route_descriptions = {
                description
                for description, app_id in (
                    ("landing-app-status", "landing"),
                    ("landing-root", "landing"),
                    ("dufs-root", "dufs"),
                    ("flatnotes-root", "flatnotes"),
                    ("todo-bloom-root", "todo-bloom"),
                )
                if app_id in selected_app_ids
            }
            missing_descriptions = sorted(expected_route_descriptions - seen_descriptions)
            if missing_descriptions:
                errors.append(
                    "verification/http-routes.tsv is missing expected routes "
                    f"{missing_descriptions}"
                )

    if errors:
        raise SystemExit("\n".join(errors))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
