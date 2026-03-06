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
        "readinessProbe": {"httpGet": {"path": "/", "port": "http"}, "initialDelaySeconds": 5, "periodSeconds": 5},
        "livenessProbe": {"httpGet": {"path": "/", "port": "http"}, "initialDelaySeconds": 15, "periodSeconds": 15},
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
) -> dict:
    return {
        "apiVersion": "networking.k8s.io/v1",
        "kind": "Ingress",
        "metadata": resource_metadata(
            metadata,
            profile_env,
            "demo-apps-ingress",
            box_host,
            tls_mode,
            ingress_class,
            storage_class,
            name="ourbox-demo-apps",
            readiness_required=True,
        ),
        "spec": {
            "ingressClassName": ingress_class,
            "defaultBackend": {"service": {"name": "landing", "port": {"number": 80}}},
            "rules": [
                {
                    "host": box_host,
                    "http": {"paths": [{"path": "/", "pathType": "Prefix", "backend": {"service": {"name": "landing", "port": {"number": 80}}}}]},
                },
                {
                    "host": f"*.{box_host}",
                    "http": {"paths": [{"path": "/", "pathType": "Prefix", "backend": {"service": {"name": "landing", "port": {"number": 80}}}}]},
                },
                {
                    "host": f"files.{box_host}",
                    "http": {"paths": [{"path": "/", "pathType": "Prefix", "backend": {"service": {"name": "dufs", "port": {"number": 5000}}}}]},
                },
                {
                    "host": f"notes.{box_host}",
                    "http": {"paths": [{"path": "/", "pathType": "Prefix", "backend": {"service": {"name": "flatnotes", "port": {"number": 8080}}}}]},
                },
                {
                    "host": f"todo.{box_host}",
                    "http": {"paths": [{"path": "/", "pathType": "Prefix", "backend": {"service": {"name": "todo-bloom", "port": {"number": 80}}}}]},
                },
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


def write_routes(path: Path, box_host: str) -> None:
    lines = [
        "host\tpath\texpected_status\tbody_marker\tdescription",
        f"{box_host}\t/\t200\tOurBox Platform Contract Baseline\tlanding-root",
        f"files.{box_host}\t/\t200\tDUFS\tdufs-root",
        f"notes.{box_host}\t/\t200\tFlatnotes\tflatnotes-root",
        f"todo.{box_host}\t/\t200\tTodo Bloom\ttodo-bloom-root",
    ]
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Render the OurBox platform contract for a concrete input set.")
    parser.add_argument("--contract-root", required=True, help="Path to the contract root")
    parser.add_argument("--output-dir", required=True, help="Destination for the rendered bundle")
    parser.add_argument("--profile", default=os.environ.get("OURBOX_PLATFORM_PROFILE", "demo-apps"))
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
                "images_lock.json": LiteralStr(json.dumps(images_lock, indent=2, sort_keys=True)),
            },
        ),
    )
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
            args=["/data", "--bind", "0.0.0.0", "--port", "5000", "--allow-all", "--render-index"],
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
            env=[{"name": "FLATNOTES_PATH", "value": "/data"}, {"name": "FLATNOTES_PORT", "value": "8080"}],
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
            "READINESS_LABEL_SELECTOR": f"ourbox.techofourown.io/contract-profile={profile_env['OURBOX_PLATFORM_PROFILE']},ourbox.techofourown.io/readiness-required=true",
            "HTTP_ROUTES_FILE": "verification/http-routes.tsv",
        },
    )
    (output_dir / "images.lock.json").write_text(json.dumps(images_lock, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    write_routes(verification_dir / "http-routes.tsv", args.box_host)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
