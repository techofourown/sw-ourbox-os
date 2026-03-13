#!/usr/bin/env python3
import argparse
import json
import os
import shutil
from pathlib import Path

import yaml


class LiteralStr(str):
    pass


class LiteralDumper(yaml.SafeDumper):
    pass


def literal_representer(dumper, data):
    return dumper.represent_scalar("tag:yaml.org,2002:str", data, style="|")


LiteralDumper.add_representer(LiteralStr, literal_representer)


METADATA_KEYS = (
    "OURBOX_PLATFORM_CONTRACT_SCHEMA",
    "OURBOX_PLATFORM_CONTRACT_KIND",
    "OURBOX_PLATFORM_CONTRACT_SOURCE",
    "OURBOX_PLATFORM_CONTRACT_REVISION",
    "OURBOX_PLATFORM_CONTRACT_VERSION",
    "OURBOX_PLATFORM_CONTRACT_CREATED",
    "OURBOX_PLATFORM_CONTRACT_DIGEST",
)


def load_env_file(path: Path) -> dict[str, str]:
    data: dict[str, str] = {}
    if not path.exists():
        return data
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        key, value = line.split("=", 1)
        data[key] = value
    return data


def write_env_file(path: Path, data: dict[str, str]) -> None:
    lines = [f"{key}={value}" for key, value in data.items()]
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def load_metadata(contract_root: Path) -> dict[str, str]:
    data = {key: os.environ.get(key, "") for key in METADATA_KEYS}
    data.update(load_env_file(contract_root / "contract.env"))
    digest_path = contract_root / "contract.digest"
    if digest_path.exists():
        data["OURBOX_PLATFORM_CONTRACT_DIGEST"] = digest_path.read_text(encoding="utf-8").strip()
    defaults = {
        "OURBOX_PLATFORM_CONTRACT_SCHEMA": "1",
        "OURBOX_PLATFORM_CONTRACT_KIND": "platform-contract",
        "OURBOX_PLATFORM_CONTRACT_SOURCE": "https://github.com/techofourown/sw-ourbox-os",
        "OURBOX_PLATFORM_CONTRACT_REVISION": "unknown",
        "OURBOX_PLATFORM_CONTRACT_VERSION": "dev",
        "OURBOX_PLATFORM_CONTRACT_CREATED": "unknown",
        "OURBOX_PLATFORM_CONTRACT_DIGEST": "unknown",
    }
    for key, value in defaults.items():
        if not data.get(key):
            data[key] = value
    return data


def yaml_dump(path: Path, document: dict) -> None:
    path.write_text(
        yaml.dump(document, Dumper=LiteralDumper, sort_keys=False),
        encoding="utf-8",
    )


def load_assets(path: Path) -> dict[str, LiteralStr]:
    assets: dict[str, LiteralStr] = {}
    for file_path in sorted(path.iterdir()):
        if not file_path.is_file():
            continue
        assets[file_path.name] = LiteralStr(file_path.read_text(encoding="utf-8"))
    return assets


def load_application_catalog(profile_dir: Path, catalog_override: str | None) -> tuple[dict | None, Path | None]:
    catalog_path = Path(catalog_override).resolve() if catalog_override else profile_dir / "catalog.json"
    if not catalog_path.exists():
        return None, None

    catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    if catalog.get("schema") != 1:
        raise SystemExit(f"application catalog at {catalog_path} must declare schema=1")
    if catalog.get("kind") != "ourbox-application-catalog":
        raise SystemExit(f"application catalog at {catalog_path} must declare kind=ourbox-application-catalog")

    apps = catalog.get("apps")
    if not isinstance(apps, list) or not apps:
        raise SystemExit(f"application catalog at {catalog_path} must declare a non-empty apps list")

    app_ids: list[str] = []
    for app in apps:
        app_id = str(app.get("id", "")).strip()
        if not app_id:
            raise SystemExit(f"application catalog at {catalog_path} contains an app without an id")
        if app_id in app_ids:
            raise SystemExit(f"application catalog at {catalog_path} contains a duplicate app id: {app_id}")
        app_ids.append(app_id)

    default_app_ids = catalog.get("default_app_ids", [])
    if not isinstance(default_app_ids, list) or not default_app_ids:
        raise SystemExit(f"application catalog at {catalog_path} must declare non-empty default_app_ids")
    unknown_defaults = sorted(set(default_app_ids) - set(app_ids))
    if unknown_defaults:
        raise SystemExit(
            f"application catalog at {catalog_path} declares unknown default_app_ids: {', '.join(unknown_defaults)}"
        )

    return catalog, catalog_path


def resolve_selected_apps(catalog: dict, selected_apps_path: str | None) -> tuple[str, list[str], dict[str, dict]]:
    app_entries = catalog["apps"]
    app_by_id = {str(app["id"]): app for app in app_entries}
    default_app_ids = [str(app_id) for app_id in catalog["default_app_ids"]]

    if not selected_apps_path:
        return "catalog-defaults", default_app_ids, app_by_id

    selected_path = Path(selected_apps_path).resolve()
    data = json.loads(selected_path.read_text(encoding="utf-8"))
    if data.get("schema") != 1:
        raise SystemExit(f"selected-apps file at {selected_path} must declare schema=1")
    if data.get("kind") != "ourbox-selected-applications":
        raise SystemExit(f"selected-apps file at {selected_path} must declare kind=ourbox-selected-applications")

    catalog_id = str(data.get("catalog_id", "")).strip()
    if catalog_id != str(catalog.get("catalog_id", "")).strip():
        raise SystemExit(
            f"selected-apps file at {selected_path} targets catalog_id={catalog_id!r}, expected {catalog.get('catalog_id')!r}"
        )

    selection_mode = str(data.get("selection_mode", "")).strip()
    if not selection_mode:
        raise SystemExit(f"selected-apps file at {selected_path} must declare selection_mode")

    selected_app_ids = data.get("selected_app_ids")
    if not isinstance(selected_app_ids, list) or not selected_app_ids:
        raise SystemExit(f"selected-apps file at {selected_path} must declare a non-empty selected_app_ids list")

    normalized_ids: list[str] = []
    seen_ids: set[str] = set()
    for raw_app_id in selected_app_ids:
        app_id = str(raw_app_id).strip()
        if not app_id:
            raise SystemExit(f"selected-apps file at {selected_path} contains an empty app id")
        if app_id in seen_ids:
            raise SystemExit(f"selected-apps file at {selected_path} contains duplicate app id {app_id}")
        if app_id not in app_by_id:
            raise SystemExit(f"selected-apps file at {selected_path} references unknown app id {app_id}")
        normalized_ids.append(app_id)
        seen_ids.add(app_id)

    return selection_mode, normalized_ids, app_by_id


def selected_application_route_specs(
    catalog: dict,
    selected_app_ids: list[str],
    box_host: str,
    *,
    catalog_path: Path | None = None,
) -> list[dict]:
    app_by_id = {str(app["id"]): app for app in catalog["apps"]}
    route_specs: list[dict] = []
    for app_id in selected_app_ids:
        app = app_by_id[app_id]
        missing_keys = [
            key
            for key in ("host_template", "service_name", "service_port", "expected_status", "body_marker", "route_description")
            if key not in app
        ]
        if missing_keys:
            location = f" at {catalog_path}" if catalog_path else ""
            raise SystemExit(
                f"application catalog{location} app {app_id!r} is missing required route keys: {', '.join(missing_keys)}"
            )
        route_specs.append(
            {
                "host": str(app["host_template"]).format(box_host=box_host),
                "path": str(app.get("path", "/")),
                "service_name": str(app["service_name"]),
                "service_port": int(app["service_port"]),
                "expected_status": int(app["expected_status"]),
                "body_marker": str(app["body_marker"]),
                "description": str(app["route_description"]),
                "default_backend": bool(app.get("default_backend", False)),
            }
        )
    return route_specs


def common_labels(metadata: dict[str, str], profile_env: dict[str, str], component: str) -> dict[str, str]:
    return {
        "app.kubernetes.io/name": component,
        "app.kubernetes.io/part-of": "ourbox-os",
        "app.kubernetes.io/managed-by": "sw-ourbox-os",
        "ourbox.techofourown.io/contract-profile": profile_env["OURBOX_PLATFORM_PROFILE"],
        "ourbox.techofourown.io/contract-revision": metadata["OURBOX_PLATFORM_CONTRACT_REVISION"][:63],
        "ourbox.techofourown.io/route-model": profile_env["OURBOX_PLATFORM_ROUTE_MODEL"],
    }


def common_annotations(
    metadata: dict[str, str],
    profile_env: dict[str, str],
    box_host: str,
    tls_mode: str,
    ingress_class: str,
    storage_class: str,
) -> dict[str, str]:
    return {
        "ourbox.techofourown.io/contract-source": metadata["OURBOX_PLATFORM_CONTRACT_SOURCE"],
        "ourbox.techofourown.io/contract-revision": metadata["OURBOX_PLATFORM_CONTRACT_REVISION"],
        "ourbox.techofourown.io/contract-version": metadata["OURBOX_PLATFORM_CONTRACT_VERSION"],
        "ourbox.techofourown.io/contract-created": metadata["OURBOX_PLATFORM_CONTRACT_CREATED"],
        "ourbox.techofourown.io/contract-digest": metadata["OURBOX_PLATFORM_CONTRACT_DIGEST"],
        "ourbox.techofourown.io/contract-profile-kind": profile_env["OURBOX_PLATFORM_PROFILE_KIND"],
        "ourbox.techofourown.io/box-host": box_host,
        "ourbox.techofourown.io/tls-mode": tls_mode,
        "ourbox.techofourown.io/ingress-class": ingress_class,
        "ourbox.techofourown.io/storage-class": storage_class,
    }


def resource_metadata(
    metadata: dict[str, str],
    profile_env: dict[str, str],
    component: str,
    box_host: str,
    tls_mode: str,
    ingress_class: str,
    storage_class: str,
    *,
    name: str | None = None,
    namespace: str | None = "ourbox-system",
    readiness_required: bool = False,
    storage_required: bool = False,
) -> dict:
    labels = common_labels(metadata, profile_env, component)
    if readiness_required:
        labels["ourbox.techofourown.io/readiness-required"] = "true"
    if storage_required:
        labels["ourbox.techofourown.io/storage-required"] = "true"
    meta = {
        "name": name or component,
        "labels": labels,
        "annotations": common_annotations(metadata, profile_env, box_host, tls_mode, ingress_class, storage_class),
    }
    if namespace:
        meta["namespace"] = namespace
    return meta


def deployment(
    metadata: dict[str, str],
    profile_env: dict[str, str],
    box_host: str,
    tls_mode: str,
    ingress_class: str,
    storage_class: str,
    *,
    name: str,
    image: str,
    container_port: int,
    container_name: str,
    volumes: list[dict] | None = None,
    volume_mounts: list[dict] | None = None,
    env: list[dict] | None = None,
    args: list[str] | None = None,
    readiness_probe: dict | None = None,
    liveness_probe: dict | None = None,
    storage_required: bool = False,
) -> dict:
    pod_labels = {
        "app.kubernetes.io/name": name,
        "app.kubernetes.io/part-of": "ourbox-os",
        "ourbox.techofourown.io/contract-profile": profile_env["OURBOX_PLATFORM_PROFILE"],
    }
    container = {
        "name": container_name,
        "image": image,
        "imagePullPolicy": "IfNotPresent",
        "ports": [{"containerPort": container_port, "name": "http"}],
        "readinessProbe": readiness_probe
        or {"httpGet": {"path": "/", "port": "http"}, "initialDelaySeconds": 5, "periodSeconds": 5},
        "livenessProbe": liveness_probe
        or {"httpGet": {"path": "/", "port": "http"}, "initialDelaySeconds": 15, "periodSeconds": 15},
    }
    if args:
        container["args"] = args
    if env:
        container["env"] = env
    if volume_mounts:
        container["volumeMounts"] = volume_mounts
    spec = {
        "apiVersion": "apps/v1",
        "kind": "Deployment",
        "metadata": resource_metadata(
            metadata,
            profile_env,
            name,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            readiness_required=True,
            storage_required=storage_required,
        ),
        "spec": {
            "replicas": 1,
            "selector": {"matchLabels": dict(pod_labels)},
            "template": {
                "metadata": {"labels": dict(pod_labels)},
                "spec": {"containers": [container]},
            },
        },
    }
    if volumes:
        spec["spec"]["template"]["spec"]["volumes"] = volumes
    return spec


def service(
    metadata: dict[str, str],
    profile_env: dict[str, str],
    box_host: str,
    tls_mode: str,
    ingress_class: str,
    storage_class: str,
    *,
    name: str,
    port: int,
) -> dict:
    return {
        "apiVersion": "v1",
        "kind": "Service",
        "metadata": resource_metadata(
            metadata,
            profile_env,
            name,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            readiness_required=True,
        ),
        "spec": {
            "selector": {
                "app.kubernetes.io/name": name,
                "app.kubernetes.io/part-of": "ourbox-os",
                "ourbox.techofourown.io/contract-profile": profile_env["OURBOX_PLATFORM_PROFILE"],
            },
            "ports": [{"name": "http", "port": port, "targetPort": "http"}],
        },
    }


def pvc(
    metadata: dict[str, str],
    profile_env: dict[str, str],
    box_host: str,
    tls_mode: str,
    ingress_class: str,
    storage_class: str,
    *,
    name: str,
) -> dict:
    return {
        "apiVersion": "v1",
        "kind": "PersistentVolumeClaim",
        "metadata": resource_metadata(
            metadata,
            profile_env,
            name,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            storage_required=True,
        ),
        "spec": {
            "accessModes": ["ReadWriteOnce"],
            "storageClassName": storage_class,
            "resources": {"requests": {"storage": "5Gi"}},
        },
    }


def ingress(
    metadata: dict[str, str],
    profile_env: dict[str, str],
    box_host: str,
    tls_mode: str,
    ingress_class: str,
    storage_class: str,
    *,
    name: str,
    route_specs: list[dict],
    default_backend: dict,
) -> dict:
    rules_by_host: dict[str, list[dict]] = {}
    for route in route_specs:
        rules_by_host.setdefault(route["host"], []).append(
            {
                "path": route["path"],
                "pathType": "Prefix",
                "backend": {
                    "service": {
                        "name": route["service_name"],
                        "port": {"number": route["service_port"]},
                    }
                },
            }
        )

    return {
        "apiVersion": "networking.k8s.io/v1",
        "kind": "Ingress",
        "metadata": resource_metadata(
            metadata,
            profile_env,
            name,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            name=name,
            readiness_required=True,
        ),
        "spec": {
            "ingressClassName": ingress_class,
            "defaultBackend": {"service": {"name": default_backend["service_name"], "port": {"number": default_backend["service_port"]}}},
            "rules": [
                {"host": host, "http": {"paths": paths}}
                for host, paths in rules_by_host.items()
            ],
        },
    }


def configmap(
    metadata: dict[str, str],
    profile_env: dict[str, str],
    box_host: str,
    tls_mode: str,
    ingress_class: str,
    storage_class: str,
    *,
    name: str,
    component: str,
    data: dict[str, str],
) -> dict:
    return {
        "apiVersion": "v1",
        "kind": "ConfigMap",
        "metadata": resource_metadata(
            metadata,
            profile_env,
            component,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            name=name,
        ),
        "data": data,
    }


def write_routes(path: Path, route_specs: list[dict]) -> None:
    lines = ["host\tpath\texpected_status\tbody_marker\tdescription"]
    for route in route_specs:
        lines.append(
            f"{route['host']}\t{route['path']}\t{route['expected_status']}\t{route['body_marker']}\t{route['description']}"
        )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Render the OurBox platform contract for a concrete input set.")
    parser.add_argument("--contract-root", required=True, help="Path to the contract root")
    parser.add_argument("--output-dir", required=True, help="Destination for the rendered bundle")
    parser.add_argument("--profile", default=os.environ.get("OURBOX_PLATFORM_PROFILE", "demo-apps"))
    parser.add_argument("--application-catalog", help="Optional override path for the application catalog JSON")
    parser.add_argument("--selected-apps-file", help="Optional selected-applications JSON written by the host-side composer")
    parser.add_argument("--box-host", default=os.environ.get("BOX_HOST", ""))
    parser.add_argument("--tls-mode", default=os.environ.get("TLS_MODE", ""))
    parser.add_argument("--ingress-class", default=os.environ.get("INGRESS_CLASS", ""))
    parser.add_argument("--storage-class", default=os.environ.get("STORAGE_CLASS", ""))
    args = parser.parse_args()

    contract_root = Path(args.contract_root).resolve()
    output_dir = Path(args.output_dir).resolve()
    profile_dir = contract_root / "profiles" / args.profile
    if not profile_dir.is_dir():
        raise SystemExit(f"Unknown profile: {args.profile}")

    profile_env = load_env_file(profile_dir / "profile.env")
    if not args.box_host:
        raise SystemExit("BOX_HOST is required")

    tls_mode = args.tls_mode or profile_env["OURBOX_PLATFORM_DEFAULT_TLS_MODE"]
    ingress_class = args.ingress_class or profile_env["OURBOX_PLATFORM_DEFAULT_INGRESS_CLASS"]
    storage_class = args.storage_class or profile_env["OURBOX_PLATFORM_DEFAULT_STORAGE_CLASS"]
    metadata = load_metadata(contract_root)
    images_lock = json.loads((profile_dir / "images.lock.json").read_text(encoding="utf-8"))
    image_refs = {item["name"]: item["ref"] for item in images_lock["images"]}
    application_catalog, application_catalog_path = load_application_catalog(profile_dir, args.application_catalog)
    if application_catalog is not None:
        selection_mode, selected_app_ids, _app_by_id = resolve_selected_apps(application_catalog, args.selected_apps_file)
        route_specs = selected_application_route_specs(
            application_catalog,
            selected_app_ids,
            args.box_host,
            catalog_path=application_catalog_path,
        )
        application_catalog_id = str(application_catalog["catalog_id"])
        application_catalog_name = str(application_catalog["catalog_name"])
    else:
        selection_mode = "legacy-defaults"
        selected_app_ids = ["landing", "todo-bloom", "dufs", "flatnotes"]
        route_specs = [
            {
                "host": args.box_host,
                "path": "/",
                "service_name": "landing",
                "service_port": 80,
                "expected_status": 200,
                "body_marker": "Your apps, served by your machine, to your phone.",
                "description": "landing-root",
                "default_backend": True,
            },
            {
                "host": f"files.{args.box_host}",
                "path": "/",
                "service_name": "dufs",
                "service_port": 5000,
                "expected_status": 200,
                "body_marker": "Upload files",
                "description": "dufs-root",
                "default_backend": False,
            },
            {
                "host": f"notes.{args.box_host}",
                "path": "/",
                "service_name": "flatnotes",
                "service_port": 8080,
                "expected_status": 200,
                "body_marker": "flatnotes",
                "description": "flatnotes-root",
                "default_backend": False,
            },
            {
                "host": f"todo.{args.box_host}",
                "path": "/",
                "service_name": "todo-bloom",
                "service_port": 80,
                "expected_status": 200,
                "body_marker": "Todo Bloom",
                "description": "todo-bloom-root",
                "default_backend": False,
            },
        ]
        application_catalog_id = profile_env["OURBOX_PLATFORM_PROFILE"]
        application_catalog_name = profile_env["OURBOX_PLATFORM_PROFILE_DESCRIPTION"]

    default_backend = next((route for route in route_specs if route["default_backend"]), route_specs[0])

    if output_dir.exists():
        shutil.rmtree(output_dir)
    manifests_dir = output_dir / "manifests"
    verification_dir = output_dir / "verification"
    manifests_dir.mkdir(parents=True)
    verification_dir.mkdir(parents=True)

    landing_assets = load_assets(contract_root / "landing")
    todo_assets = load_assets(contract_root / "todo-bloom")

    yaml_dump(
        manifests_dir / "00-namespace.yaml",
        {
            "apiVersion": "v1",
            "kind": "Namespace",
            "metadata": resource_metadata(
                metadata,
                profile_env,
                "ourbox-platform",
                args.box_host,
                tls_mode,
                ingress_class,
                storage_class,
                name="ourbox-system",
                namespace=None,
            ),
        },
    )
    yaml_dump(
        manifests_dir / "05-contract-metadata-configmap.yaml",
        configmap(
            metadata,
            profile_env,
            args.box_host,
            tls_mode,
            ingress_class,
            storage_class,
            name="ourbox-platform-contract",
            component="ourbox-platform-contract",
            data={
                "contract_source": metadata["OURBOX_PLATFORM_CONTRACT_SOURCE"],
                "contract_revision": metadata["OURBOX_PLATFORM_CONTRACT_REVISION"],
                "contract_version": metadata["OURBOX_PLATFORM_CONTRACT_VERSION"],
                "contract_created": metadata["OURBOX_PLATFORM_CONTRACT_CREATED"],
                "contract_digest": metadata["OURBOX_PLATFORM_CONTRACT_DIGEST"],
                "profile": profile_env["OURBOX_PLATFORM_PROFILE"],
                "profile_kind": profile_env["OURBOX_PLATFORM_PROFILE_KIND"],
                "route_model": profile_env["OURBOX_PLATFORM_ROUTE_MODEL"],
                "box_host": args.box_host,
                "tls_mode": tls_mode,
                "ingress_class": ingress_class,
                "storage_class": storage_class,
                "application_catalog_id": application_catalog_id,
                "application_catalog_name": application_catalog_name,
                "application_selection_mode": selection_mode,
                "selected_app_ids": ",".join(selected_app_ids),
                "images_lock.json": LiteralStr(json.dumps(images_lock, indent=2, sort_keys=True)),
            },
        ),
    )
    if "landing" in selected_app_ids:
        yaml_dump(
            manifests_dir / "10-landing-configmap.yaml",
            configmap(
                metadata,
                profile_env,
                args.box_host,
                tls_mode,
                ingress_class,
                storage_class,
                name="landing-assets",
                component="landing-assets",
                data=landing_assets,
            ),
        )
        yaml_dump(
            manifests_dir / "20-landing-deployment.yaml",
            deployment(
                metadata,
                profile_env,
                args.box_host,
                tls_mode,
                ingress_class,
                storage_class,
                name="landing",
                image=image_refs["nginx"],
                container_port=80,
                container_name="nginx",
                volumes=[{"name": "assets", "configMap": {"name": "landing-assets"}}],
                volume_mounts=[{"name": "assets", "mountPath": "/usr/share/nginx/html", "readOnly": True}],
            ),
        )
        yaml_dump(
            manifests_dir / "21-landing-service.yaml",
            service(
                metadata,
                profile_env,
                args.box_host,
                tls_mode,
                ingress_class,
                storage_class,
                name="landing",
                port=80,
            ),
        )

    if "todo-bloom" in selected_app_ids:
        yaml_dump(
            manifests_dir / "11-todo-bloom-configmap.yaml",
            configmap(
                metadata,
                profile_env,
                args.box_host,
                tls_mode,
                ingress_class,
                storage_class,
                name="todo-bloom-assets",
                component="todo-bloom-assets",
                data=todo_assets,
            ),
        )
        yaml_dump(
            manifests_dir / "22-todo-bloom-deployment.yaml",
            deployment(
                metadata,
                profile_env,
                args.box_host,
                tls_mode,
                ingress_class,
                storage_class,
                name="todo-bloom",
                image=image_refs["nginx"],
                container_port=80,
                container_name="nginx",
                volumes=[{"name": "assets", "configMap": {"name": "todo-bloom-assets"}}],
                volume_mounts=[{"name": "assets", "mountPath": "/usr/share/nginx/html", "readOnly": True}],
            ),
        )
        yaml_dump(
            manifests_dir / "23-todo-bloom-service.yaml",
            service(
                metadata,
                profile_env,
                args.box_host,
                tls_mode,
                ingress_class,
                storage_class,
                name="todo-bloom",
                port=80,
            ),
        )

    if "dufs" in selected_app_ids:
        yaml_dump(
            manifests_dir / "30-dufs-pvc.yaml",
            pvc(
                metadata,
                profile_env,
                args.box_host,
                tls_mode,
                ingress_class,
                storage_class,
                name="dufs-data",
            ),
        )
        yaml_dump(
            manifests_dir / "31-dufs-deployment.yaml",
            deployment(
                metadata,
                profile_env,
                args.box_host,
                tls_mode,
                ingress_class,
                storage_class,
                name="dufs",
                image=image_refs["dufs"],
                container_port=5000,
                container_name="dufs",
                args=["/data", "--bind", "0.0.0.0", "--port", "5000", "--allow-all"],
                readiness_probe={"httpGet": {"path": "/", "port": "http"}, "initialDelaySeconds": 5, "periodSeconds": 5},
                liveness_probe={"httpGet": {"path": "/", "port": "http"}, "initialDelaySeconds": 15, "periodSeconds": 15},
                volumes=[{"name": "data", "persistentVolumeClaim": {"claimName": "dufs-data"}}],
                volume_mounts=[{"name": "data", "mountPath": "/data"}],
                storage_required=True,
            ),
        )
        yaml_dump(
            manifests_dir / "32-dufs-service.yaml",
            service(
                metadata,
                profile_env,
                args.box_host,
                tls_mode,
                ingress_class,
                storage_class,
                name="dufs",
                port=5000,
            ),
        )

    if "flatnotes" in selected_app_ids:
        yaml_dump(
            manifests_dir / "40-flatnotes-pvc.yaml",
            pvc(
                metadata,
                profile_env,
                args.box_host,
                tls_mode,
                ingress_class,
                storage_class,
                name="flatnotes-data",
            ),
        )
        yaml_dump(
            manifests_dir / "41-flatnotes-deployment.yaml",
            deployment(
                metadata,
                profile_env,
                args.box_host,
                tls_mode,
                ingress_class,
                storage_class,
                name="flatnotes",
                image=image_refs["flatnotes"],
                container_port=8080,
                container_name="flatnotes",
                env=[
                    {"name": "FLATNOTES_AUTH_TYPE", "value": "none"},
                    {"name": "FLATNOTES_PATH", "value": "/data"},
                    {"name": "FLATNOTES_PORT", "value": "8080"},
                ],
                volumes=[{"name": "data", "persistentVolumeClaim": {"claimName": "flatnotes-data"}}],
                volume_mounts=[{"name": "data", "mountPath": "/data"}],
                storage_required=True,
            ),
        )
        yaml_dump(
            manifests_dir / "42-flatnotes-service.yaml",
            service(
                metadata,
                profile_env,
                args.box_host,
                tls_mode,
                ingress_class,
                storage_class,
                name="flatnotes",
                port=8080,
            ),
        )

    yaml_dump(
        manifests_dir / "50-demo-apps-ingress.yaml",
        ingress(
            metadata,
            profile_env,
            args.box_host,
            tls_mode,
            ingress_class,
            storage_class,
            name="ourbox-demo-apps",
            route_specs=route_specs,
            default_backend=default_backend,
        ),
    )

    write_env_file(
        output_dir / "render.env",
        {
            "OURBOX_PLATFORM_PROFILE": profile_env["OURBOX_PLATFORM_PROFILE"],
            "OURBOX_PLATFORM_PROFILE_KIND": profile_env["OURBOX_PLATFORM_PROFILE_KIND"],
            "OURBOX_PLATFORM_ROUTE_MODEL": profile_env["OURBOX_PLATFORM_ROUTE_MODEL"],
            "BOX_HOST": args.box_host,
            "TLS_MODE": tls_mode,
            "INGRESS_CLASS": ingress_class,
            "STORAGE_CLASS": storage_class,
            "APPLICATION_CATALOG_ID": application_catalog_id,
            "APPLICATION_SELECTION_MODE": selection_mode,
            "SELECTED_APP_IDS": ",".join(selected_app_ids),
            "READINESS_LABEL_SELECTOR": f"ourbox.techofourown.io/contract-profile={profile_env['OURBOX_PLATFORM_PROFILE']},ourbox.techofourown.io/readiness-required=true",
            "HTTP_ROUTES_FILE": "verification/http-routes.tsv",
        },
    )
    (output_dir / "images.lock.json").write_text(json.dumps(images_lock, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    if application_catalog is not None:
        (output_dir / "catalog.json").write_text(json.dumps(application_catalog, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        (output_dir / "selected-apps.json").write_text(
            json.dumps(
                {
                    "schema": 1,
                    "kind": "ourbox-selected-applications",
                    "catalog_id": application_catalog_id,
                    "selection_mode": selection_mode,
                    "selected_app_ids": selected_app_ids,
                },
                indent=2,
                sort_keys=True,
            )
            + "\n",
            encoding="utf-8",
        )
    write_routes(verification_dir / "http-routes.tsv", route_specs)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
