#!/usr/bin/env python3
import argparse
import json
import os
import re
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

CATALOG_ID_RE = re.compile(r"^[a-z0-9][a-z0-9-]*$")
SELECTION_MODES = {"catalog-defaults", "all-apps", "custom"}
LANDING_IMAGE_REF = (
    "docker.io/library/nginx@"
    "sha256:65645c7bb6a0661892a8b03b89d0743208a18dd2f3f17a54ef4b76fb8e2f2a10"
)
LANDING_STATUS_IMAGE_REF = (
    "docker.io/library/python:3.12-alpine@"
    "sha256:7747d47f92cfca63a6e2b50275e23dba8407c30d8ae929a88ddd49a5d3f2d331"
)
LANDING_STATUS_ROUTE_PATH = "/_ourbox/app-status.json"
LANDING_STATUS_ROUTE_DESCRIPTION = "landing-app-status"
LANDING_STATUS_BODY_MARKER = "ourbox-landing-status"
LANDING_ROUTE_DESCRIPTION = "landing-root"
LANDING_BODY_MARKER = "Your apps, served by your machine, to your phone."


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
        raise SystemExit(
            f"application catalog not found at {catalog_path}; "
            "supported renders require explicit application intent"
        )

    catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    if catalog.get("schema") != 1:
        raise SystemExit(f"application catalog at {catalog_path} must declare schema=1")
    if catalog.get("kind") != "ourbox-application-catalog":
        raise SystemExit(f"application catalog at {catalog_path} must declare kind=ourbox-application-catalog")
    catalog_id = str(catalog.get("catalog_id", "")).strip()
    catalog_name = str(catalog.get("catalog_name", "")).strip()
    if not catalog_id:
        raise SystemExit(f"application catalog at {catalog_path} must declare catalog_id")
    if not CATALOG_ID_RE.fullmatch(catalog_id):
        raise SystemExit(
            f"application catalog at {catalog_path} declares invalid catalog_id {catalog_id!r}; expected lowercase machine token"
        )
    if not catalog_name:
        raise SystemExit(f"application catalog at {catalog_path} must declare catalog_name")

    apps = catalog.get("apps")
    if not isinstance(apps, list) or not apps:
        raise SystemExit(f"application catalog at {catalog_path} must declare a non-empty apps list")

    app_ids: list[str] = []
    app_uids: set[str] = set()
    default_backends = 0
    for app in apps:
        app_id = str(app.get("id", "")).strip()
        app_uid = str(app.get("app_uid", "")).strip()
        if not app_id:
            raise SystemExit(f"application catalog at {catalog_path} contains an app without an id")
        if app_id in app_ids:
            raise SystemExit(f"application catalog at {catalog_path} contains a duplicate app id: {app_id}")
        if not app_uid:
            raise SystemExit(f"application catalog at {catalog_path} app {app_id!r} must declare app_uid")
        if app_uid in app_uids:
            raise SystemExit(f"application catalog at {catalog_path} contains a duplicate app_uid: {app_uid}")
        services = app.get("services")
        if not isinstance(services, list) or not services:
            raise SystemExit(
                f"application catalog at {catalog_path} app {app_id!r} must declare a non-empty services list"
            )
        for svc_idx, svc in enumerate(services):
            svc_name = str(svc.get("name", "")).strip()
            if not svc_name:
                raise SystemExit(
                    f"application catalog at {catalog_path} app {app_id!r} service [{svc_idx}] must declare a name"
                )
            svc_image = str(svc.get("image", "")).strip()
            if not svc_image:
                raise SystemExit(
                    f"application catalog at {catalog_path} app {app_id!r} service {svc_name!r} must declare an image"
                )
            image_names = app.get("image_names", [])
            if svc_image not in image_names:
                raise SystemExit(
                    f"application catalog at {catalog_path} app {app_id!r} service {svc_name!r} "
                    f"references image {svc_image!r} not in image_names {image_names!r}"
                )
            if "port" not in svc:
                raise SystemExit(
                    f"application catalog at {catalog_path} app {app_id!r} service {svc_name!r} must declare a port"
                )

        service_names = {str(svc.get("name", "")).strip() for svc in services}
        top_service_name = str(app.get("service_name", "")).strip()
        if top_service_name and top_service_name not in service_names:
            raise SystemExit(
                f"application catalog at {catalog_path} app {app_id!r} declares service_name {top_service_name!r} "
                f"which does not match any services entry {sorted(service_names)!r}"
            )

        app_ids.append(app_id)
        app_uids.add(app_uid)
        if bool(app.get("default_backend", False)):
            default_backends += 1

    default_app_ids = catalog.get("default_app_ids", [])
    if not isinstance(default_app_ids, list) or not default_app_ids:
        raise SystemExit(f"application catalog at {catalog_path} must declare non-empty default_app_ids")
    unknown_defaults = sorted(set(default_app_ids) - set(app_ids))
    if unknown_defaults:
        raise SystemExit(
            f"application catalog at {catalog_path} declares unknown default_app_ids: {', '.join(unknown_defaults)}"
        )
    if default_backends > 1:
        raise SystemExit(f"application catalog at {catalog_path} declares more than one default_backend app")

    return catalog, catalog_path


def load_images_lock(profile_dir: Path, images_lock_override: str | None) -> tuple[dict, Path]:
    images_lock_path = Path(images_lock_override).resolve() if images_lock_override else profile_dir / "images.lock.json"
    if not images_lock_path.exists():
        raise SystemExit(f"images.lock.json not found at {images_lock_path}")
    images_lock = json.loads(images_lock_path.read_text(encoding="utf-8"))
    images = images_lock.get("images")
    if not isinstance(images, list) or not images:
        raise SystemExit(f"images lock at {images_lock_path} must declare a non-empty images list")
    for image in images:
        name = str(image.get("name", "")).strip()
        ref = str(image.get("ref", "")).strip()
        if not name:
            raise SystemExit(f"images lock at {images_lock_path} contains an image without a name")
        if not ref:
            raise SystemExit(f"images lock at {images_lock_path} contains an image without a ref")
    return images_lock, images_lock_path


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
    if selection_mode not in SELECTION_MODES:
        raise SystemExit(
            f"selected-apps file at {selected_path} declares unsupported selection_mode {selection_mode!r}"
        )

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


def normalize_route_path(value: str | None) -> str:
    path = str(value or "/").strip() or "/"
    if not path.startswith("/"):
        path = "/" + path
    return path


def resolved_selected_application_surface(
    catalog: dict,
    selected_app_ids: list[str],
    box_host: str,
    *,
    selection_mode: str,
    catalog_path: Path | None = None,
) -> dict:
    app_by_id = {str(app["id"]): app for app in catalog["apps"]}
    resolved_apps: list[dict] = []
    default_backend_app_id: str | None = None

    for app_id in selected_app_ids:
        app = app_by_id[app_id]
        missing_keys = [
            key
            for key in (
                "display_name",
                "description",
                "host_template",
                "service_name",
                "service_port",
                "expected_status",
                "body_marker",
                "route_description",
                "services",
            )
            if key not in app
        ]
        if missing_keys:
            location = f" at {catalog_path}" if catalog_path else ""
            raise SystemExit(
                f"application catalog{location} app {app_id!r} is missing required runtime-surface keys: {', '.join(missing_keys)}"
            )

        path = normalize_route_path(app.get("path", "/"))
        host = str(app["host_template"]).format(box_host=box_host)
        default_backend = bool(app.get("default_backend", False))

        if default_backend:
            if default_backend_app_id is not None:
                location = f" at {catalog_path}" if catalog_path else ""
                raise SystemExit(
                    f"application catalog{location} declares multiple selected default_backend apps: "
                    f"{default_backend_app_id!r} and {app_id!r}"
                )
            default_backend_app_id = app_id

        resolved_apps.append(
            {
                "id": app_id,
                "app_uid": str(app.get("app_uid", app_id)),
                "local_app_id": str(app.get("local_app_id", "")),
                "display_name": str(app["display_name"]),
                "description": str(app["description"]),
                "host": host,
                "path": path,
                "url": f"http://{host}{path}",
                "service_name": str(app["service_name"]),
                "service_port": int(app["service_port"]),
                "route_description": str(app["route_description"]),
                "expected_status": int(app["expected_status"]),
                "body_marker": str(app["body_marker"]),
                "default_backend": default_backend,
                "show_on_landing": True,
                "publish_mdns_alias": host != box_host,
                "include_in_status": True,
            }
        )

    status_route = {
        "host": box_host,
        "path": LANDING_STATUS_ROUTE_PATH,
        "path_type": "Exact",
        "service_name": "landing-status",
        "service_port": 8080,
        "expected_status": 200,
        "body_marker": LANDING_STATUS_BODY_MARKER,
        "description": LANDING_STATUS_ROUTE_DESCRIPTION,
    }

    return {
        "schema": 1,
        "kind": "ourbox-selected-app-surface",
        "application_catalog_id": str(catalog["catalog_id"]),
        "application_catalog_name": str(catalog["catalog_name"]),
        "selection_mode": selection_mode,
        "box_host": box_host,
        "default_backend_app_id": default_backend_app_id,
        "status_route": status_route,
        "apps": resolved_apps,
    }


def surface_route_specs(surface: dict) -> list[dict]:
    route_specs = [
        {
            "host": str(app["host"]),
            "path": str(app["path"]),
            "path_type": "Prefix",
            "service_name": str(app["service_name"]),
            "service_port": int(app["service_port"]),
            "expected_status": int(app["expected_status"]),
            "body_marker": str(app["body_marker"]),
            "description": str(app["route_description"]),
            "default_backend": bool(app.get("default_backend", False)),
        }
        for app in surface["apps"]
    ]
    status_route = surface.get("status_route")
    if status_route:
        route_specs.append(
            {
                "host": str(status_route["host"]),
                "path": str(status_route["path"]),
                "path_type": str(status_route.get("path_type", "Prefix")),
                "service_name": str(status_route["service_name"]),
                "service_port": int(status_route["service_port"]),
                "expected_status": int(status_route["expected_status"]),
                "body_marker": str(status_route["body_marker"]),
                "description": str(status_route["description"]),
                "default_backend": False,
            }
        )
    return route_specs


def public_landing_specs(apps: list[dict]) -> list[dict[str, str]]:
    return [
        {
            "id": str(app["id"]),
            "name": str(app["name"]),
            "description": str(app["description"]),
            "host": str(app["host"]),
            "path": str(app["path"]),
        }
        for app in apps
    ]


def landing_surface_specs(surface: dict) -> list[dict[str, str]]:
    return [
        {
            "id": str(app["id"]),
            "name": str(app["display_name"]),
            "description": str(app["description"]),
            "host": str(app["host"]),
            "path": str(app["path"]),
            "service_name": str(app["service_name"]),
        }
        for app in surface["apps"]
        if bool(app.get("show_on_landing", False))
    ]


def landing_status_surface_specs(surface: dict) -> list[dict[str, str]]:
    return [
        {
            "id": str(app["id"]),
            "name": str(app["display_name"]),
            "description": str(app["description"]),
            "host": str(app["host"]),
            "path": str(app["path"]),
            "service_name": str(app["service_name"]),
        }
        for app in surface["apps"]
        if bool(app.get("include_in_status", False))
    ]


def landing_assets_data(box_host: str, apps: list[dict[str, str]]) -> dict[str, LiteralStr]:
    return {
        "ourbox-apps.json": LiteralStr(
            json.dumps(
                {
                    "schema": 1,
                    "kind": "ourbox-landing-app-list",
                    "box_host": box_host,
                    "apps": public_landing_specs(apps),
                },
                indent=2,
                sort_keys=True,
            )
            + "\n"
        )
    }


def landing_status_assets_data(box_host: str, apps: list[dict[str, str]]) -> dict[str, LiteralStr]:
    return {
        "ourbox-app-targets.json": LiteralStr(
            json.dumps(
                {
                    "schema": 1,
                    "kind": "ourbox-landing-app-targets",
                    "box_host": box_host,
                    "apps": apps,
                },
                indent=2,
                sort_keys=True,
            )
            + "\n"
        )
    }


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
    command: list[str] | None = None,
    args: list[str] | None = None,
    readiness_probe: dict | None = None,
    liveness_probe: dict | None = None,
    storage_required: bool = False,
    service_account_name: str | None = None,
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
    if command:
        container["command"] = command
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
    if service_account_name:
        spec["spec"]["template"]["spec"]["serviceAccountName"] = service_account_name
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


def serviceaccount(
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
        "kind": "ServiceAccount",
        "metadata": resource_metadata(
            metadata,
            profile_env,
            name,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            name=name,
        ),
    }


def role(
    metadata: dict[str, str],
    profile_env: dict[str, str],
    box_host: str,
    tls_mode: str,
    ingress_class: str,
    storage_class: str,
    *,
    name: str,
    rules: list[dict],
) -> dict:
    return {
        "apiVersion": "rbac.authorization.k8s.io/v1",
        "kind": "Role",
        "metadata": resource_metadata(
            metadata,
            profile_env,
            name,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            name=name,
        ),
        "rules": rules,
    }


def rolebinding(
    metadata: dict[str, str],
    profile_env: dict[str, str],
    box_host: str,
    tls_mode: str,
    ingress_class: str,
    storage_class: str,
    *,
    name: str,
    role_name: str,
    serviceaccount_name: str,
) -> dict:
    return {
        "apiVersion": "rbac.authorization.k8s.io/v1",
        "kind": "RoleBinding",
        "metadata": resource_metadata(
            metadata,
            profile_env,
            name,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            name=name,
        ),
        "subjects": [
            {
                "kind": "ServiceAccount",
                "name": serviceaccount_name,
                "namespace": "ourbox-system",
            }
        ],
        "roleRef": {
            "apiGroup": "rbac.authorization.k8s.io",
            "kind": "Role",
            "name": role_name,
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
    size: str = "5Gi",
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
            "resources": {"requests": {"storage": size}},
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
                "pathType": route.get("path_type", "Prefix"),
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


def resolve_service_image_ref(
    app: dict,
    svc: dict,
    image_refs: dict[str, str],
    *,
    catalog_path: Path | None = None,
) -> str:
    svc_image = str(svc["image"]).strip()
    if svc_image not in image_refs:
        location = f" at {catalog_path}" if catalog_path else ""
        raise SystemExit(
            f"application catalog{location} app {app.get('id')!r} service {svc.get('name')!r} "
            f"references unknown image name {svc_image!r}"
        )
    return image_refs[svc_image]


def emit_app(
    manifests_dir: Path,
    metadata: dict[str, str],
    profile_env: dict[str, str],
    box_host: str,
    tls_mode: str,
    ingress_class: str,
    storage_class: str,
    *,
    app: dict,
    image_refs: dict[str, str],
    catalog_path: Path | None,
) -> None:
    services_spec = app["services"]
    for svc in services_spec:
        svc_name = str(svc["name"])
        svc_port = int(svc["port"])
        svc_image_ref = resolve_service_image_ref(app, svc, image_refs, catalog_path=catalog_path)
        health_path = str(svc["health_path"])

        svc_command = list(svc.get("command", []))
        svc_args = list(svc.get("args", []))
        svc_env_map = dict(svc.get("env", {}))
        svc_storage = svc.get("storage")

        env_list = [{"name": k, "value": v} for k, v in svc_env_map.items()] or None
        volumes = None
        volume_mounts = None
        has_storage = svc_storage is not None

        if has_storage:
            pvc_name = f"{svc_name}-data"
            mount_path = str(svc_storage["mount_path"])
            storage_size = str(svc_storage["size"])
            yaml_dump(
                manifests_dir / f"{svc_name}-pvc.yaml",
                pvc(
                    metadata,
                    profile_env,
                    box_host,
                    tls_mode,
                    ingress_class,
                    storage_class,
                    name=pvc_name,
                    size=storage_size,
                ),
            )
            volumes = [{"name": "data", "persistentVolumeClaim": {"claimName": pvc_name}}]
            volume_mounts = [{"name": "data", "mountPath": mount_path}]

        yaml_dump(
            manifests_dir / f"{svc_name}-deployment.yaml",
            deployment(
                metadata,
                profile_env,
                box_host,
                tls_mode,
                ingress_class,
                storage_class,
                name=svc_name,
                image=svc_image_ref,
                container_port=svc_port,
                container_name=svc_name,
                command=svc_command or None,
                args=svc_args or None,
                env=env_list,
                readiness_probe={"httpGet": {"path": health_path, "port": "http"}, "initialDelaySeconds": 5, "periodSeconds": 5},
                liveness_probe={"httpGet": {"path": health_path, "port": "http"}, "initialDelaySeconds": 15, "periodSeconds": 15},
                volumes=volumes,
                volume_mounts=volume_mounts,
                storage_required=has_storage,
            ),
        )
        yaml_dump(
            manifests_dir / f"{svc_name}-service.yaml",
            service(
                metadata,
                profile_env,
                box_host,
                tls_mode,
                ingress_class,
                storage_class,
                name=svc_name,
                port=svc_port,
            ),
        )


def emit_landing_infra(
    manifests_dir: Path,
    contract_root: Path,
    metadata: dict[str, str],
    profile_env: dict[str, str],
    box_host: str,
    tls_mode: str,
    ingress_class: str,
    storage_class: str,
    *,
    landing_apps: list[dict[str, str]],
    status_apps: list[dict[str, str]],
) -> None:
    # --- Landing page (nginx serving the app-directory page) ---
    landing_service_name = "landing"
    landing_assets = landing_assets_data(box_host, landing_apps)
    landing_configmap_name = f"{landing_service_name}-assets"
    yaml_dump(
        manifests_dir / f"{landing_service_name}-configmap.yaml",
        configmap(
            metadata,
            profile_env,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            name=landing_configmap_name,
            component=landing_configmap_name,
            data=landing_assets,
        ),
    )
    yaml_dump(
        manifests_dir / f"{landing_service_name}-deployment.yaml",
        deployment(
            metadata,
            profile_env,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            name=landing_service_name,
            image=LANDING_IMAGE_REF,
            container_port=80,
            container_name=landing_service_name,
            volumes=[{"name": "assets", "configMap": {"name": landing_configmap_name}}],
            volume_mounts=[
                {
                    "name": "assets",
                    "mountPath": f"/usr/share/nginx/html/{file_name}",
                    "subPath": file_name,
                    "readOnly": True,
                }
                for file_name in sorted(landing_assets)
            ],
        ),
    )
    yaml_dump(
        manifests_dir / f"{landing_service_name}-service.yaml",
        service(
            metadata,
            profile_env,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            name=landing_service_name,
            port=80,
        ),
    )

    # --- Landing status service (python health-checker) ---
    assets_dir = contract_root / "landing-status"
    status_configmap_name = "landing-status-assets"
    status_service_name = "landing-status"
    serviceaccount_name = "landing-status"
    role_name = "landing-status"
    rolebinding_name = "landing-status"
    asset_data = load_assets(assets_dir)
    asset_data.update(landing_status_assets_data(box_host, status_apps))

    yaml_dump(
        manifests_dir / f"{status_service_name}-configmap.yaml",
        configmap(
            metadata,
            profile_env,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            name=status_configmap_name,
            component=status_configmap_name,
            data=asset_data,
        ),
    )
    yaml_dump(
        manifests_dir / f"{serviceaccount_name}-serviceaccount.yaml",
        serviceaccount(
            metadata,
            profile_env,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            name=serviceaccount_name,
        ),
    )
    yaml_dump(
        manifests_dir / f"{role_name}-role.yaml",
        role(
            metadata,
            profile_env,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            name=role_name,
            rules=[
                {"apiGroups": [""], "resources": ["pods"], "verbs": ["get", "list"]},
                {"apiGroups": ["apps"], "resources": ["deployments"], "verbs": ["get", "list"]},
            ],
        ),
    )
    yaml_dump(
        manifests_dir / f"{rolebinding_name}-rolebinding.yaml",
        rolebinding(
            metadata,
            profile_env,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            name=rolebinding_name,
            role_name=role_name,
            serviceaccount_name=serviceaccount_name,
        ),
    )
    yaml_dump(
        manifests_dir / f"{status_service_name}-deployment.yaml",
        deployment(
            metadata,
            profile_env,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            name=status_service_name,
            image=LANDING_STATUS_IMAGE_REF,
            container_port=8080,
            container_name=status_service_name,
            command=["python3", "/app/app.py"],
            readiness_probe={"httpGet": {"path": "/healthz", "port": "http"}, "initialDelaySeconds": 2, "periodSeconds": 5},
            liveness_probe={"httpGet": {"path": "/healthz", "port": "http"}, "initialDelaySeconds": 5, "periodSeconds": 10},
            volumes=[{"name": "assets", "configMap": {"name": status_configmap_name}}],
            volume_mounts=[{"name": "assets", "mountPath": "/app", "readOnly": True}],
            service_account_name=serviceaccount_name,
        ),
    )
    yaml_dump(
        manifests_dir / f"{status_service_name}-service.yaml",
        service(
            metadata,
            profile_env,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            name=status_service_name,
            port=8080,
        ),
    )


def emit_application_manifests(
    manifests_dir: Path,
    metadata: dict[str, str],
    profile_env: dict[str, str],
    box_host: str,
    tls_mode: str,
    ingress_class: str,
    storage_class: str,
    *,
    selected_app_ids: list[str],
    app_by_id: dict[str, dict],
    image_refs: dict[str, str],
    catalog_path: Path | None,
) -> None:
    for app_id in selected_app_ids:
        emit_app(
            manifests_dir,
            metadata,
            profile_env,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            app=app_by_id[app_id],
            image_refs=image_refs,
            catalog_path=catalog_path,
        )


def main() -> int:
    parser = argparse.ArgumentParser(description="Render the OurBox platform contract for a concrete input set.")
    parser.add_argument("--contract-root", required=True, help="Path to the contract root")
    parser.add_argument("--output-dir", required=True, help="Destination for the rendered bundle")
    parser.add_argument("--profile", default=os.environ.get("OURBOX_PLATFORM_PROFILE", "demo-apps"))
    parser.add_argument("--application-catalog", help="Optional override path for the application catalog JSON")
    parser.add_argument("--images-lock-file", help="Optional override path for the rendered images.lock.json")
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
    images_lock, _images_lock_path = load_images_lock(profile_dir, args.images_lock_file)
    image_refs = {item["name"]: item["ref"] for item in images_lock["images"]}
    application_catalog, application_catalog_path = load_application_catalog(profile_dir, args.application_catalog)
    selection_mode, selected_app_ids, app_by_id = resolve_selected_apps(application_catalog, args.selected_apps_file)
    selected_app_surface = resolved_selected_application_surface(
        application_catalog,
        selected_app_ids,
        args.box_host,
        selection_mode=selection_mode,
        catalog_path=application_catalog_path,
    )
    route_specs = surface_route_specs(selected_app_surface)
    landing_apps = landing_surface_specs(selected_app_surface)
    status_apps = landing_status_surface_specs(selected_app_surface)
    application_catalog_id = str(application_catalog["catalog_id"])
    application_catalog_name = str(application_catalog["catalog_name"])

    landing_route = {
        "host": args.box_host,
        "path": "/",
        "path_type": "Prefix",
        "service_name": "landing",
        "service_port": 80,
        "expected_status": 200,
        "body_marker": LANDING_BODY_MARKER,
        "description": LANDING_ROUTE_DESCRIPTION,
        "default_backend": True,
    }
    route_specs.append(landing_route)

    default_backend = landing_route

    if output_dir.exists():
        shutil.rmtree(output_dir)
    manifests_dir = output_dir / "manifests"
    verification_dir = output_dir / "verification"
    manifests_dir.mkdir(parents=True)
    verification_dir.mkdir(parents=True)

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
                "platform_images.json": LiteralStr(
                    json.dumps(
                        {
                            "landing": LANDING_IMAGE_REF,
                            "landing-status": LANDING_STATUS_IMAGE_REF,
                        },
                        indent=2,
                        sort_keys=True,
                    )
                    + "\n"
                ),
                "images_lock.json": LiteralStr(json.dumps(images_lock, indent=2, sort_keys=True)),
            },
        ),
    )
    emit_application_manifests(
        manifests_dir,
        metadata,
        profile_env,
        args.box_host,
        tls_mode,
        ingress_class,
        storage_class,
        selected_app_ids=selected_app_ids,
        app_by_id=app_by_id,
        image_refs=image_refs,
        catalog_path=application_catalog_path,
    )
    emit_landing_infra(
        manifests_dir,
        contract_root,
        metadata,
        profile_env,
        args.box_host,
        tls_mode,
        ingress_class,
        storage_class,
        landing_apps=landing_apps,
        status_apps=status_apps,
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
            "SELECTED_APP_SURFACE_FILE": "selected-app-surface.json",
            "READINESS_LABEL_SELECTOR": f"ourbox.techofourown.io/contract-profile={profile_env['OURBOX_PLATFORM_PROFILE']},ourbox.techofourown.io/readiness-required=true",
            "HTTP_ROUTES_FILE": "verification/http-routes.tsv",
        },
    )
    (output_dir / "selected-app-surface.json").write_text(
        json.dumps(selected_app_surface, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    platform_images = [
        {"name": "_platform-landing", "ref": LANDING_IMAGE_REF, "used_by": ["_platform"]},
        {"name": "_platform-landing-status", "ref": LANDING_STATUS_IMAGE_REF, "used_by": ["_platform"]},
    ]
    images_lock_with_platform = dict(images_lock)
    images_lock_with_platform["images"] = list(images_lock["images"]) + platform_images
    (output_dir / "images.lock.json").write_text(
        json.dumps(images_lock_with_platform, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
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
