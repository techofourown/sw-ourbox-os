#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/ourbox-verify-runtime-smoke.XXXXXX")"
SERVER_PID=""
trap '[[ -n "${SERVER_PID}" ]] && kill "${SERVER_PID}" 2>/dev/null || true; rm -rf "${TMP_ROOT}"' EXIT

RENDER_DIR="${TMP_ROOT}/render"
CONTRACT_DIR="${TMP_ROOT}/contract"
BIN_DIR="${TMP_ROOT}/bin"
mkdir -p "${RENDER_DIR}" "${CONTRACT_DIR}" "${BIN_DIR}"

PORT="$(python3 - <<'PY'
import socket
s = socket.socket()
s.bind(("127.0.0.1", 0))
print(s.getsockname()[1])
s.close()
PY
)"

cat > "${RENDER_DIR}/render.env" <<EOF_RENDER
READINESS_LABEL_SELECTOR=app.kubernetes.io/part-of=ourbox-os
OURBOX_PLATFORM_PROFILE=demo-apps
OURBOX_PLATFORM_ROUTE_MODEL=ingress
BOX_HOST=smoke.ourbox.local
TLS_MODE=lan-http
INGRESS_CLASS=traefik
STORAGE_CLASS=local-path
HTTP_ROUTES_FILE=${RENDER_DIR}/http-routes.tsv
EOF_RENDER

cat > "${RENDER_DIR}/http-routes.tsv" <<'EOF_ROUTES'
host	path	expected_status	body_marker	description
landing.smoke.ourbox.local	/	200	Landing	landing-root
EOF_ROUTES

cat > "${CONTRACT_DIR}/contract.env" <<'EOF_CONTRACT'
OURBOX_PLATFORM_CONTRACT_SOURCE=https://github.com/techofourown/sw-ourbox-os
OURBOX_PLATFORM_CONTRACT_REVISION=smoke-revision
OURBOX_PLATFORM_CONTRACT_VERSION=smoke-version
EOF_CONTRACT
printf 'sha256:%064d\n' 0 > "${CONTRACT_DIR}/contract.digest"

cat > "${TMP_ROOT}/release.env" <<'EOF_RELEASE'
OURBOX_PLATFORM_CONTRACT_SOURCE=https://github.com/techofourown/sw-ourbox-os
OURBOX_PLATFORM_CONTRACT_REVISION=smoke-revision
OURBOX_PLATFORM_CONTRACT_VERSION=smoke-version
OURBOX_APPLICATION_CATALOG_NAME="Merged Application Catalog"
EOF_RELEASE

cat > "${TMP_ROOT}/bad-release.env" <<'EOF_BAD_RELEASE'
OURBOX_PLATFORM_CONTRACT_SOURCE=https://github.com/techofourown/sw-ourbox-os
OURBOX_PLATFORM_CONTRACT_REVISION=smoke-revision
OURBOX_PLATFORM_CONTRACT_VERSION=smoke-version
OURBOX_APPLICATION_CATALOG_NAME=Merged Application Catalog
EOF_BAD_RELEASE

cat > "${TMP_ROOT}/http-server.py" <<'EOF_SERVER'
#!/usr/bin/env python3
from http.server import BaseHTTPRequestHandler, HTTPServer
import sys

port = int(sys.argv[1])

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        body = b"Landing"
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        return

HTTPServer(("127.0.0.1", port), Handler).serve_forever()
EOF_SERVER
chmod +x "${TMP_ROOT}/http-server.py"
python3 "${TMP_ROOT}/http-server.py" "${PORT}" >/dev/null 2>&1 &
SERVER_PID="$!"

cat > "${BIN_DIR}/k3s" <<'EOF_K3S'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" != "kubectl" ]]; then
  echo "unexpected k3s subcommand: ${*}" >&2
  exit 1
fi
shift

if [[ "${1:-}" == "--kubeconfig" ]]; then
  shift 2
fi

case "${1:-}" in
  get)
    case "${2:-}" in
      nodes)
        printf 'True\n'
        ;;
      deployment)
        printf 'ourbox-system\tlanding\n'
        ;;
      service)
        printf 'ourbox-system\tlanding\n'
        ;;
      endpoints)
        printf '10.42.0.9 '
        ;;
      configmap)
        key="${@: -1}"
        case "${key}" in
          *contract_source*) printf 'https://github.com/techofourown/sw-ourbox-os' ;;
          *contract_revision*) printf 'smoke-revision' ;;
          *contract_version*) printf 'smoke-version' ;;
          *contract_digest*) printf 'sha256:0000000000000000000000000000000000000000000000000000000000000000' ;;
          *profile*) printf 'demo-apps' ;;
          *route_model*) printf 'ingress' ;;
          *box_host*) printf 'smoke.ourbox.local' ;;
          *tls_mode*) printf 'lan-http' ;;
          *ingress_class*) printf 'traefik' ;;
          *storage_class*) printf 'local-path' ;;
          *) echo "unexpected configmap jsonpath: ${key}" >&2; exit 1 ;;
        esac
        ;;
      pods)
        printf 'traefik-0\n'
        ;;
      *)
        echo "unexpected kubectl get target: ${2:-}" >&2
        exit 1
        ;;
    esac
    ;;
  rollout)
    [[ "${2:-}" == "status" ]] || { echo "unexpected rollout args: $*" >&2; exit 1; }
    ;;
  logs)
    printf 'traefik: all clear\n'
    ;;
  *)
    echo "unexpected kubectl command: $*" >&2
    exit 1
    ;;
esac
EOF_K3S
chmod +x "${BIN_DIR}/k3s"

touch "${TMP_ROOT}/kubeconfig"

bash "${ROOT}/tools/platform-contract/verify-runtime.sh" \
  --kubeconfig "${TMP_ROOT}/kubeconfig" \
  --k3s-bin "${BIN_DIR}/k3s" \
  --render-dir "${RENDER_DIR}" \
  --contract-dir "${CONTRACT_DIR}" \
  --release-file "${TMP_ROOT}/release.env" \
  --route-base-url "http://127.0.0.1:${PORT}"

set +e
bash "${ROOT}/tools/platform-contract/verify-runtime.sh" \
  --kubeconfig "${TMP_ROOT}/kubeconfig" \
  --k3s-bin "${BIN_DIR}/k3s" \
  --render-dir "${RENDER_DIR}" \
  --contract-dir "${CONTRACT_DIR}" \
  --release-file "${TMP_ROOT}/bad-release.env" \
  --route-base-url "http://127.0.0.1:${PORT}" \
  >"${TMP_ROOT}/bad-release.log" 2>&1
status=$?
set -e

[[ "${status}" -ne 0 ]] || {
  echo "verify-runtime should reject malformed release metadata" >&2
  exit 1
}
grep -F "failed to parse release metadata file" "${TMP_ROOT}/bad-release.log" >/dev/null || {
  cat "${TMP_ROOT}/bad-release.log" >&2
  exit 1
}
grep -F "malformed release metadata line" "${TMP_ROOT}/bad-release.log" >/dev/null || {
  cat "${TMP_ROOT}/bad-release.log" >&2
  exit 1
}

printf '[%s] verify-runtime smoke passed\n' "$(date -Is)"
