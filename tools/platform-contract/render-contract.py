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
LANDING_STATUS_IMAGE_REF = (
    "docker.io/library/python:3.12-alpine@"
    "sha256:7747d47f92cfca63a6e2b50275e23dba8407c30d8ae929a88ddd49a5d3f2d331"
)
LANDING_STATUS_ROUTE_PATH = "/_ourbox/app-status.json"
LANDING_STATUS_ROUTE_DESCRIPTION = "landing-app-status"
LANDING_STATUS_BODY_MARKER = "ourbox-landing-status"


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
    landing_app_id: str | None = None

    for app_id in selected_app_ids:
        app = app_by_id[app_id]
        missing_keys = [
            key
            for key in (
                "display_name",
                "description",
                "renderer",
                "host_template",
                "service_name",
                "service_port",
                "expected_status",
                "body_marker",
                "route_description",
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
        renderer = str(app["renderer"]).strip()

        if default_backend:
            if default_backend_app_id is not None:
                location = f" at {catalog_path}" if catalog_path else ""
                raise SystemExit(
                    f"application catalog{location} declares multiple selected default_backend apps: "
                    f"{default_backend_app_id!r} and {app_id!r}"
                )
            default_backend_app_id = app_id

        if renderer == "landing":
            if landing_app_id is not None:
                location = f" at {catalog_path}" if catalog_path else ""
                raise SystemExit(
                    f"application catalog{location} declares multiple selected landing renderers: "
                    f"{landing_app_id!r} and {app_id!r}"
                )
            landing_app_id = app_id

        resolved_apps.append(
            {
                "id": app_id,
                "app_uid": str(app.get("app_uid", app_id)),
                "local_app_id": str(app.get("local_app_id", "")),
                "display_name": str(app["display_name"]),
                "description": str(app["description"]),
                "renderer": renderer,
                "host": host,
                "path": path,
                "url": f"http://{host}{path}",
                "service_name": str(app["service_name"]),
                "service_port": int(app["service_port"]),
                "route_description": str(app["route_description"]),
                "expected_status": int(app["expected_status"]),
                "body_marker": str(app["body_marker"]),
                "default_backend": default_backend,
                "show_on_landing": not default_backend,
                "publish_mdns_alias": host != box_host,
                "include_in_status": not default_backend,
            }
        )

    status_route = None
    if landing_app_id is not None:
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
        "landing_selected": landing_app_id is not None,
        "landing_app_id": landing_app_id,
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


def resolve_primary_image_ref(app: dict, image_refs: dict[str, str], *, catalog_path: Path | None = None) -> str:
    image_names = app.get("image_names")
    if not isinstance(image_names, list) or not image_names:
        location = f" at {catalog_path}" if catalog_path else ""
        raise SystemExit(
            f"application catalog{location} app {app.get('id')!r} must declare a non-empty image_names list"
        )
    primary_image = str(image_names[0]).strip()
    if not primary_image:
        location = f" at {catalog_path}" if catalog_path else ""
        raise SystemExit(f"application catalog{location} app {app.get('id')!r} declares an empty primary image name")
    if primary_image not in image_refs:
        location = f" at {catalog_path}" if catalog_path else ""
        raise SystemExit(
            f"application catalog{location} app {app.get('id')!r} references unknown image name {primary_image!r}"
        )
    return image_refs[primary_image]


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


def emit_static_http_app(
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
    extra_assets: dict[str, LiteralStr] | None = None,
) -> None:
    app_id = str(app["id"])
    service_name = str(app["service_name"])
    service_port = int(app["service_port"])
    image_ref = resolve_primary_image_ref(app, image_refs, catalog_path=catalog_path)
    asset_dir_name = str(app.get("asset_dir", "")).strip()

    if asset_dir_name:
        location = f" at {catalog_path}" if catalog_path else ""
        raise SystemExit(
            f"application catalog{location} app {app_id!r} declares unsupported asset_dir {asset_dir_name!r}; "
            "static assets must come from the selected application image"
        )

    volumes = None
    volume_mounts = None
    asset_data: dict[str, LiteralStr] = {}
    if extra_assets:
        asset_data.update(extra_assets)
    if asset_data:
        configmap_name = f"{service_name}-assets"
        yaml_dump(
            manifests_dir / f"{service_name}-configmap.yaml",
            configmap(
                metadata,
                profile_env,
                box_host,
                tls_mode,
                ingress_class,
                storage_class,
                name=configmap_name,
                component=configmap_name,
                data=asset_data,
            ),
        )
        volumes = [{"name": "assets", "configMap": {"name": configmap_name}}]
        volume_mounts = [
            {
                "name": "assets",
                "mountPath": f"/usr/share/nginx/html/{file_name}",
                "subPath": file_name,
                "readOnly": True,
            }
            for file_name in sorted(asset_data)
        ]

    yaml_dump(
        manifests_dir / f"{service_name}-deployment.yaml",
        deployment(
            metadata,
            profile_env,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            name=service_name,
            image=image_ref,
            container_port=service_port,
            container_name=app_id.replace("/", "-"),
            volumes=volumes,
            volume_mounts=volume_mounts,
        ),
    )
    yaml_dump(
        manifests_dir / f"{service_name}-service.yaml",
        service(
            metadata,
            profile_env,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            name=service_name,
            port=service_port,
        ),
    )


def emit_dufs_app(
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
    service_name = str(app["service_name"])
    service_port = int(app["service_port"])
    image_ref = resolve_primary_image_ref(app, image_refs, catalog_path=catalog_path)
    yaml_dump(
        manifests_dir / f"{service_name}-pvc.yaml",
        pvc(
            metadata,
            profile_env,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            name=f"{service_name}-data",
        ),
    )
    yaml_dump(
        manifests_dir / f"{service_name}-deployment.yaml",
        deployment(
            metadata,
            profile_env,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            name=service_name,
            image=image_ref,
            container_port=service_port,
            container_name=service_name,
            args=["/data", "--bind", "0.0.0.0", "--port", str(service_port), "--allow-all"],
            readiness_probe={"httpGet": {"path": "/", "port": "http"}, "initialDelaySeconds": 5, "periodSeconds": 5},
            liveness_probe={"httpGet": {"path": "/", "port": "http"}, "initialDelaySeconds": 15, "periodSeconds": 15},
            volumes=[{"name": "data", "persistentVolumeClaim": {"claimName": f"{service_name}-data"}}],
            volume_mounts=[{"name": "data", "mountPath": "/data"}],
            storage_required=True,
        ),
    )
    yaml_dump(
        manifests_dir / f"{service_name}-service.yaml",
        service(
            metadata,
            profile_env,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            name=service_name,
            port=service_port,
        ),
    )


def emit_flatnotes_app(
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
    service_name = str(app["service_name"])
    service_port = int(app["service_port"])
    image_ref = resolve_primary_image_ref(app, image_refs, catalog_path=catalog_path)
    yaml_dump(
        manifests_dir / f"{service_name}-pvc.yaml",
        pvc(
            metadata,
            profile_env,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            name=f"{service_name}-data",
        ),
    )
    yaml_dump(
        manifests_dir / f"{service_name}-deployment.yaml",
        deployment(
            metadata,
            profile_env,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            name=service_name,
            image=image_ref,
            container_port=service_port,
            container_name=service_name,
            env=[
                {"name": "FLATNOTES_AUTH_TYPE", "value": "none"},
                {"name": "FLATNOTES_PATH", "value": "/data"},
                {"name": "FLATNOTES_PORT", "value": str(service_port)},
            ],
            volumes=[{"name": "data", "persistentVolumeClaim": {"claimName": f"{service_name}-data"}}],
            volume_mounts=[{"name": "data", "mountPath": "/data"}],
            storage_required=True,
        ),
    )
    yaml_dump(
        manifests_dir / f"{service_name}-service.yaml",
        service(
            metadata,
            profile_env,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            name=service_name,
            port=service_port,
        ),
    )


def emit_landing_status_service(
    manifests_dir: Path,
    contract_root: Path,
    metadata: dict[str, str],
    profile_env: dict[str, str],
    box_host: str,
    tls_mode: str,
    ingress_class: str,
    storage_class: str,
    *,
    status_apps: list[dict[str, str]],
) -> None:
    assets_dir = contract_root / "landing-status"
    configmap_name = "landing-status-assets"
    service_name = "landing-status"
    serviceaccount_name = "landing-status"
    role_name = "landing-status"
    rolebinding_name = "landing-status"
    asset_data = load_assets(assets_dir)
    asset_data.update(landing_status_assets_data(box_host, status_apps))

    yaml_dump(
        manifests_dir / f"{service_name}-configmap.yaml",
        configmap(
            metadata,
            profile_env,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            name=configmap_name,
            component=configmap_name,
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
        manifests_dir / f"{service_name}-deployment.yaml",
        deployment(
            metadata,
            profile_env,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            name=service_name,
            image=LANDING_STATUS_IMAGE_REF,
            container_port=8080,
            container_name=service_name,
            command=["python3", "/app/app.py"],
            readiness_probe={"httpGet": {"path": "/healthz", "port": "http"}, "initialDelaySeconds": 2, "periodSeconds": 5},
            liveness_probe={"httpGet": {"path": "/healthz", "port": "http"}, "initialDelaySeconds": 5, "periodSeconds": 10},
            volumes=[{"name": "assets", "configMap": {"name": configmap_name}}],
            volume_mounts=[{"name": "assets", "mountPath": "/app", "readOnly": True}],
            service_account_name=serviceaccount_name,
        ),
    )
    yaml_dump(
        manifests_dir / f"{service_name}-service.yaml",
        service(
            metadata,
            profile_env,
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            name=service_name,
            port=8080,
        ),
    )


def emit_application_manifests(
    manifests_dir: Path,
    contract_root: Path,
    metadata: dict[str, str],
    profile_env: dict[str, str],
    box_host: str,
    tls_mode: str,
    ingress_class: str,
    storage_class: str,
    *,
    selected_app_ids: list[str],
    landing_app_id: str | None,
    app_by_id: dict[str, dict],
    image_refs: dict[str, str],
    catalog_path: Path | None,
    landing_assets: dict[str, LiteralStr] | None = None,
) -> None:
    for app_id in selected_app_ids:
        app = app_by_id[app_id]
        renderer = str(app.get("renderer", "")).strip()
        if renderer in {"landing", "todo-bloom", "hello-world", "static-http"}:
            emit_static_http_app(
                manifests_dir,
                metadata,
                profile_env,
                box_host,
                tls_mode,
                ingress_class,
                storage_class,
                app=app,
                image_refs=image_refs,
                catalog_path=catalog_path,
                extra_assets=landing_assets if app_id == landing_app_id else None,
            )
            continue
        if renderer == "dufs":
            emit_dufs_app(
                manifests_dir,
                metadata,
                profile_env,
                box_host,
                tls_mode,
                ingress_class,
                storage_class,
                app=app,
                image_refs=image_refs,
                catalog_path=catalog_path,
            )
            continue
        if renderer == "flatnotes":
            emit_flatnotes_app(
                manifests_dir,
                metadata,
                profile_env,
                box_host,
                tls_mode,
                ingress_class,
                storage_class,
                app=app,
                image_refs=image_refs,
                catalog_path=catalog_path,
            )
            continue
        location = f" at {catalog_path}" if catalog_path else ""
        raise SystemExit(f"application catalog{location} app {app_id!r} declares unsupported renderer {renderer!r}")


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
    landing_app_id = selected_app_surface.get("landing_app_id")
    application_catalog_id = str(application_catalog["catalog_id"])
    application_catalog_name = str(application_catalog["catalog_name"])

    default_backend = next((route for route in route_specs if route["default_backend"]), route_specs[0])

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
                        {"landing-status": LANDING_STATUS_IMAGE_REF} if selected_app_surface["landing_selected"] else {},
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
        contract_root,
        metadata,
        profile_env,
        args.box_host,
        tls_mode,
        ingress_class,
        storage_class,
        selected_app_ids=selected_app_ids,
        landing_app_id=landing_app_id,
        app_by_id=app_by_id,
        image_refs=image_refs,
        catalog_path=application_catalog_path,
        landing_assets=landing_assets_data(args.box_host, landing_apps),
    )
    if selected_app_surface["landing_selected"]:
        emit_landing_status_service(
            manifests_dir,
            contract_root,
            metadata,
            profile_env,
            args.box_host,
            tls_mode,
            ingress_class,
            storage_class,
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
    (output_dir / "images.lock.json").write_text(json.dumps(images_lock, indent=2, sort_keys=True) + "\n", encoding="utf-8")
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
