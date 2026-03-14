#!/usr/bin/env python3
import json
import os
import ssl
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import Request, urlopen


TARGETS_FILE = Path(os.environ.get("OURBOX_APP_TARGETS_FILE", "/app/ourbox-app-targets.json"))
STATUS_ROUTE = os.environ.get("OURBOX_STATUS_ROUTE", "/_ourbox/app-status.json")
HEALTH_ROUTE = "/healthz"
LISTEN_HOST = os.environ.get("OURBOX_STATUS_HOST", "0.0.0.0")
LISTEN_PORT = int(os.environ.get("OURBOX_STATUS_PORT", "8080"))
TOKEN_FILE = Path("/var/run/secrets/kubernetes.io/serviceaccount/token")
CA_FILE = Path("/var/run/secrets/kubernetes.io/serviceaccount/ca.crt")
NAMESPACE_FILE = Path("/var/run/secrets/kubernetes.io/serviceaccount/namespace")
KUBE_HOST = os.environ.get("KUBERNETES_SERVICE_HOST", "kubernetes.default.svc")
KUBE_PORT = os.environ.get("KUBERNETES_SERVICE_PORT_HTTPS", "443")

FAILING_REASONS = {
    "CrashLoopBackOff",
    "CreateContainerConfigError",
    "CreateContainerError",
    "ErrImagePull",
    "ImagePullBackOff",
    "RunContainerError",
    "Error",
    "Failed",
}
STARTING_REASONS = {
    "ContainerCreating",
    "Pending",
    "PodInitializing",
}


def load_targets() -> dict:
    return json.loads(TARGETS_FILE.read_text(encoding="utf-8"))


def namespace() -> str:
    if NAMESPACE_FILE.is_file():
        return NAMESPACE_FILE.read_text(encoding="utf-8").strip()
    return "ourbox-system"


def kube_get(path: str, params: dict[str, str] | None = None) -> dict:
    query = ""
    if params:
        query = "?" + urlencode(params)
    request = Request(
        f"https://{KUBE_HOST}:{KUBE_PORT}{path}{query}",
        headers={"Authorization": f"Bearer {TOKEN_FILE.read_text(encoding='utf-8').strip()}"},
    )
    context = ssl.create_default_context(cafile=str(CA_FILE))
    with urlopen(request, context=context, timeout=5) as response:
        return json.load(response)


def first_pod_problem(pod: dict) -> str:
    for status in pod.get("status", {}).get("containerStatuses", []) or []:
        state = status.get("state", {})
        waiting = state.get("waiting")
        if waiting and waiting.get("reason"):
            return str(waiting["reason"])
        terminated = state.get("terminated")
        if terminated and terminated.get("reason"):
            return str(terminated["reason"])
    phase = str(pod.get("status", {}).get("phase", "Unknown"))
    if phase and phase != "Running":
        return phase
    return "NotReady"


def classify_target(target: dict, deployments: dict[str, dict], pods_by_name: dict[str, list[dict]]) -> dict:
    service_name = str(target["service_name"])
    deployment = deployments.get(service_name)
    pods = pods_by_name.get(service_name, [])

    desired = int((deployment or {}).get("spec", {}).get("replicas", 1) or 0)
    ready = int((deployment or {}).get("status", {}).get("readyReplicas", 0) or 0)
    available = int((deployment or {}).get("status", {}).get("availableReplicas", 0) or 0)
    restarts = sum(
        int(status.get("restartCount", 0) or 0)
        for pod in pods
        for status in pod.get("status", {}).get("containerStatuses", []) or []
    )
    problem = next((first_pod_problem(pod) for pod in pods if first_pod_problem(pod)), "")

    if deployment is None:
        tone = "error"
        label = "Missing"
        summary = "Deployment missing"
    elif desired > 0 and ready >= desired and available >= desired:
        tone = "healthy"
        label = "Running"
        summary = f"{ready}/{desired} pods ready"
        if restarts:
            suffix = "restart" if restarts == 1 else "restarts"
            summary += f" · {restarts} {suffix}"
    elif problem in FAILING_REASONS:
        tone = "error"
        label = "Issue"
        summary = f"{ready}/{max(desired, 1)} pods ready · {problem}"
    elif problem in STARTING_REASONS or pods:
        tone = "warning"
        label = "Starting"
        summary = f"{ready}/{max(desired, 1)} pods ready"
        if problem:
            summary += f" · {problem}"
    else:
        tone = "error"
        label = "Issue"
        summary = f"{ready}/{max(desired, 1)} pods ready · No pods observed"

    return {
        "id": target["id"],
        "name": target["name"],
        "description": target["description"],
        "host": target["host"],
        "path": target.get("path", "/"),
        "status": tone,
        "status_label": label,
        "status_summary": summary,
        "desired_pods": desired,
        "ready_pods": ready,
        "available_pods": available,
        "restart_count": restarts,
    }


def build_payload() -> dict:
    targets = load_targets()
    apps = list(targets.get("apps", []))
    now = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")

    try:
        ns = namespace()
        deployments_raw = kube_get(f"/apis/apps/v1/namespaces/{ns}/deployments")
        pods_raw = kube_get(f"/api/v1/namespaces/{ns}/pods")
        deployments = {item["metadata"]["name"]: item for item in deployments_raw.get("items", [])}
        pods_by_name: dict[str, list[dict]] = {}
        for pod in pods_raw.get("items", []):
            labels = pod.get("metadata", {}).get("labels", {}) or {}
            app_name = labels.get("app.kubernetes.io/name")
            if app_name:
                pods_by_name.setdefault(str(app_name), []).append(pod)
        rendered_apps = [classify_target(app, deployments, pods_by_name) for app in apps]
        cluster_status = "ok"
        error = ""
    except Exception as exc:  # pragma: no cover - exercised in-cluster
        rendered_apps = [
            {
                "id": app["id"],
                "name": app["name"],
                "description": app["description"],
                "host": app["host"],
                "path": app.get("path", "/"),
                "status": "unknown",
                "status_label": "Unknown",
                "status_summary": "Cluster status unavailable",
                "desired_pods": 0,
                "ready_pods": 0,
                "available_pods": 0,
                "restart_count": 0,
            }
            for app in apps
        ]
        cluster_status = "error"
        error = str(exc)

    payload = {
        "schema": 1,
        "kind": "ourbox-landing-status",
        "checked_at": now,
        "cluster_status": cluster_status,
        "apps": rendered_apps,
    }
    if error:
        payload["error"] = error
    return payload


class Handler(BaseHTTPRequestHandler):
    def write_json(self, status_code: int, payload: dict) -> None:
        body = json.dumps(payload, indent=2, sort_keys=True).encode("utf-8") + b"\n"
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:  # noqa: N802
        if self.path == HEALTH_ROUTE:
            self.write_json(200, {"status": "ok"})
            return
        if self.path != STATUS_ROUTE:
            self.write_json(404, {"status": "not-found"})
            return
        self.write_json(200, build_payload())

    def log_message(self, format: str, *args) -> None:  # noqa: A003
        return


if __name__ == "__main__":
    server = ThreadingHTTPServer((LISTEN_HOST, LISTEN_PORT), Handler)
    server.serve_forever()
