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


def main() -> int:
    parser = argparse.ArgumentParser(description="Lint a rendered platform contract bundle.")
    parser.add_argument("--contract-root", required=True)
    parser.add_argument("--render-dir", required=True)
    args = parser.parse_args()

    contract_root = Path(args.contract_root).resolve()
    render_dir = Path(args.render_dir).resolve()
    manifests_dir = render_dir / "manifests"
    if not manifests_dir.is_dir():
        raise SystemExit(f"Missing manifests directory: {manifests_dir}")

    resources = load_resources(manifests_dir)
    resources_by_key = {resource_key(resource): resource for resource in resources}
    deployments = [resource for resource in resources if resource["kind"] == "Deployment"]
    services = [resource for resource in resources if resource["kind"] == "Service"]
    pvcs = [resource for resource in resources if resource["kind"] == "PersistentVolumeClaim"]
    configmaps = [resource for resource in resources if resource["kind"] == "ConfigMap"]
    images_lock = json.loads((render_dir / "images.lock.json").read_text(encoding="utf-8"))
    lock_refs = {item["ref"] for item in images_lock["images"]}
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

    if manifest_image_refs != lock_refs:
        errors.append(
            "Rendered manifest images do not match images.lock.json "
            f"(rendered={sorted(manifest_image_refs)}, lock={sorted(lock_refs)})"
        )

    configmap_names = {(resource["metadata"].get("namespace", ""), resource["metadata"]["name"]) for resource in configmaps}
    expected_asset_maps = {
        ("ourbox-system", "landing-assets"): {path.name for path in sorted((contract_root / "landing").iterdir()) if path.is_file()},
        ("ourbox-system", "todo-bloom-assets"): {path.name for path in sorted((contract_root / "todo-bloom").iterdir()) if path.is_file()},
    }
    for key, expected_files in expected_asset_maps.items():
        if key not in configmap_names:
            errors.append(f"Missing asset ConfigMap {key[1]}")
            continue
        actual_data = set(resources_by_key[("ConfigMap", key[0], key[1])].get("data", {}).keys())
        if actual_data != expected_files:
            errors.append(f"ConfigMap/{key[1]} does not match asset source files")

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
            for line in lines[1:]:
                parts = line.split("\t")
                if len(parts) != 5:
                    errors.append(f"verification/http-routes.tsv has malformed line: {line}")
                    continue
                host, path, expected_status, body_marker, description = parts
                if not all((host, path, expected_status, body_marker, description)):
                    errors.append(f"verification/http-routes.tsv has empty required field: {line}")

    if errors:
        raise SystemExit("\n".join(errors))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
