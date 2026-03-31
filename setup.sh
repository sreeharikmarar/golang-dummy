#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="golang-dummy"
IMAGE_NAME="golang-dummy:latest"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
fail() { echo -e "${RED}[x]${NC} $*"; exit 1; }

check_prereqs() {
    log "Checking prerequisites..."
    local missing=0
    for cmd in docker kind kubectl; do
        if ! command -v "$cmd" &>/dev/null; then
            fail "$cmd is not installed"
            missing=1
        fi
        echo "  $cmd: $(command -v "$cmd")"
    done
    if ! docker info &>/dev/null; then
        fail "Docker daemon is not running"
    fi
    [ "$missing" -eq 0 ] || exit 1
    log "All prerequisites met"
}

create_cluster() {
    if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
        warn "Cluster '${CLUSTER_NAME}' already exists, deleting..."
        kind delete cluster --name "$CLUSTER_NAME"
    fi
    log "Creating Kind cluster '${CLUSTER_NAME}'..."
    kind create cluster --name "$CLUSTER_NAME" --config kind-config.yaml
    log "Waiting for nodes to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=120s
    log "Cluster is ready"
}

build_and_load() {
    log "Building Docker image '${IMAGE_NAME}'..."
    docker build -t "$IMAGE_NAME" .
    log "Loading image into Kind cluster..."
    kind load docker-image "$IMAGE_NAME" --name "$CLUSTER_NAME"
    log "Image loaded"
}

deploy() {
    log "Applying Kubernetes manifests..."
    kubectl apply -f k8s/deploy.yaml
    log "Waiting for rollout..."
    kubectl rollout status deployment/golang-dummy --timeout=120s
    log "Deployment ready"
}

smoke_test() {
    log "Running smoke tests..."
    local base_url="http://localhost:30080"
    local passed=0
    local failed=0

    # Wait for service to be reachable
    local retries=10
    while ! curl -sf "$base_url/ping" &>/dev/null; do
        retries=$((retries - 1))
        if [ "$retries" -le 0 ]; then
            fail "Service not reachable after retries"
        fi
        sleep 2
    done

    run_test() {
        local name="$1"
        local expected_code="$2"
        shift 2
        local actual_code
        actual_code=$(curl -s -o /dev/null -w "%{http_code}" "$@") || true
        if [ "$actual_code" = "$expected_code" ]; then
            echo -e "  ${GREEN}PASS${NC} $name (HTTP $actual_code)"
            passed=$((passed + 1))
        else
            echo -e "  ${RED}FAIL${NC} $name (expected $expected_code, got $actual_code)"
            failed=$((failed + 1))
        fi
    }

    run_test "GET /ping"            200 "$base_url/ping"
    run_test "GET /health"          200 "$base_url/health"
    run_test "GET /hello"           200 "$base_url/hello"
    run_test "GET /headers"         200 "$base_url/headers"
    run_test "GET /status/200"      200 "$base_url/status/200"
    run_test "GET /status/404"      404 "$base_url/status/404"
    run_test "GET /status/503"      503 "$base_url/status/503"
    run_test "GET /info"            200 "$base_url/info"
    run_test "GET /env"             200 "$base_url/env"
    run_test "GET /delay/100"       200 "$base_url/delay/100"
    run_test "POST /echo"           200 -X POST -H "Content-Type: text/plain" -d "hello" "$base_url/echo"

    echo ""
    log "Results: ${passed} passed, ${failed} failed"
    [ "$failed" -eq 0 ] || fail "Some tests failed"
}

print_info() {
    echo ""
    log "Setup complete!"
    echo ""
    echo "  Base URL: http://localhost:30080"
    echo ""
    echo "  Endpoints:"
    echo "    GET  /ping           - Health check (returns 'pong')"
    echo "    GET  /health         - Structured health check (JSON)"
    echo "    GET  /hello          - Hello world (JSON)"
    echo "    GET  /headers        - Echo request headers (JSON)"
    echo "    GET  /status/{code}  - Return arbitrary HTTP status"
    echo "    POST /echo           - Echo request body"
    echo "    GET  /env            - Pod environment variables (JSON)"
    echo "    GET  /info           - Server info: hostname, IPs, uptime (JSON)"
    echo "    GET  /delay/{ms}     - Delayed response (max 30s)"
    echo ""
    echo "  Useful commands:"
    echo "    kubectl get pods"
    echo "    kubectl logs -l app=golang-dummy -f"
    echo "    ./setup.sh teardown"
    echo ""
}

teardown() {
    log "Deleting Kind cluster '${CLUSTER_NAME}'..."
    kind delete cluster --name "$CLUSTER_NAME"
    log "Cluster deleted"
}

case "${1:-setup}" in
    setup)
        check_prereqs
        create_cluster
        build_and_load
        deploy
        smoke_test
        print_info
        ;;
    teardown)
        teardown
        ;;
    *)
        echo "Usage: $0 {setup|teardown}"
        exit 1
        ;;
esac
