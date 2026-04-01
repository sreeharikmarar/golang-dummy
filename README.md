# golang-dummy

A lightweight Go HTTP test server for verifying Kubernetes networking, service mesh configurations, HTTP client behavior, and load balancing.

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/ping` | Returns `pong` — simple health check |
| GET | `/health` | JSON health status with timestamp and uptime — for K8s probes |
| GET | `/hello` | Returns `{"hello": "world"}` |
| GET | `/headers` | Echoes request headers as JSON — for proxy/mesh header inspection |
| GET | `/status/{code}` | Returns the specified HTTP status code (100-599) |
| POST | `/echo` | Echoes request body back with same Content-Type (max 1MB) |
| GET | `/env` | Returns curated environment variables as JSON (POD_NAME, POD_IP, NODE_NAME, etc.) |
| GET | `/info` | Server info: hostname, IPs, version, git commit, build time — for deployment verification |
| GET | `/delay/{ms}` | Responds after the specified delay in milliseconds (max 30s) |

## Quick Start

### Run locally

```sh
make run
# or
PORT=8080 go run main.go start
```

### Test endpoints

```sh
curl localhost:8080/ping
curl localhost:8080/health
curl localhost:8080/headers
curl localhost:8080/status/503
curl localhost:8080/info
curl localhost:8080/delay/500
curl -X POST -H "Content-Type: application/json" -d '{"test": true}' localhost:8080/echo
```

## Kind Cluster Setup

Deploy to a local Kind cluster with a single command:

```sh
./setup.sh
```

This will:
1. Check prerequisites (docker, kind, kubectl)
2. Create a 3-node Kind cluster (1 control-plane + 2 workers)
3. Build and load the Docker image
4. Deploy with 2 replicas
5. Run smoke tests against all endpoints
6. Print connection info

Access the server at `http://localhost:30080`.

### Teardown

```sh
./setup.sh teardown
```

## Build

```sh
make build                  # Build binary with version info (git SHA, timestamp)
make VERSION=v1.2.0 build   # Build with explicit version
make docker-build            # Build Docker image
make test                    # Run tests
make lint                    # Run golangci-lint
```

## Deployment Strategy Support

The service is strategy-agnostic. Each build gets a unique version from `git describe` — that's the only identity needed. The platform (Argo Rollouts, Istio, etc.) handles the rollout strategy; the app just reports what version it is.

### Response Headers

Every response includes:

| Header | Source | Description |
|--------|--------|-------------|
| `X-App-Version` | Build-time `git describe` | Version tag or SHA (e.g., `v0.1.0-3-gabc123`) |
| `X-Git-Commit` | Build-time `git rev-parse` | Short git commit SHA |

### Build-Time Version Info

Version, git commit SHA, and build timestamp are resolved inside the Dockerfile via `git describe`, `git rev-parse`, and `date`. No external build args required. Each build gets a unique, immutable version — the only identity needed to distinguish pods during any rollout strategy.

- With a git tag: version = `v0.1.0` (on tag) or `v0.1.0-3-gabc123` (3 commits after tag)
- Without tags: version = short commit SHA (e.g., `cc64394`)

### Verifying Traffic Distribution

After deploying with a rollout strategy, verify which versions are serving traffic:

```sh
# Check response headers
curl -sI localhost:30080/ping | grep X-App

# Check /info JSON
curl -s localhost:30080/info | jq '{version, git_commit, build_time, hostname}'

# Run automated distribution check (requires jq)
./setup.sh verify 20    # or: make verify
```

Example verify output during a canary rollout:
```
  Versions:
    v0.1.0                    15/20 (75%)
    v0.1.0-3-gabc123          5/20 (25%)
  Hosts:
    pod-abc                   10/20 (50%)
    pod-def                   5/20 (25%)
    pod-ghi                   5/20 (25%)
```

## Use Cases

- **Canary / blue-green verification** — check `X-App-Version` header to verify traffic split between builds
- **Load balancing verification** — hit `/info` repeatedly to see different pod hostnames
- **Service mesh testing** — inspect injected headers via `/headers`
- **Error handling** — use `/status/{code}` to simulate any HTTP error
- **Latency testing** — use `/delay/{ms}` to simulate slow upstreams
- **K8s config verification** — check downward API values via `/env`
- **Probe configuration** — use `/health` for liveness and readiness probes
- **Payload testing** — send arbitrary payloads to `/echo`

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | Server listen port |
