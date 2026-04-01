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
| GET | `/info` | Server info: hostname, IPs, version, git commit, build time, color, track — for deployment verification |
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

The service is designed to work with any deployment strategy (Argo Rollouts, Istio, blue-green, canary). The platform manages rollout infrastructure — the app just exposes its identity.

### Response Headers

Every response includes deployment identity headers:

| Header | Source | Description |
|--------|--------|-------------|
| `X-App-Version` | `APP_VERSION` env or build-time version | Identifies the app version |
| `X-Git-Commit` | Build-time ldflags | Git SHA of the build |
| `X-App-Color` | `APP_COLOR` env (if set) | Blue-green deployment color |
| `X-App-Track` | `APP_TRACK` env (if set) | Canary deployment track |

### Verifying Traffic Distribution

After deploying with a rollout strategy, verify which versions are serving traffic:

```sh
# Check response headers
curl -v localhost:30080/info 2>&1 | grep -i "x-app-"

# Check /info JSON (includes version, git_commit, build_time, color, track)
curl -s localhost:30080/info | jq '{version, git_commit, color, track, hostname}'

# Run automated distribution check
./setup.sh verify 20    # or: make verify
```

The verify command curls `/info` N times and shows a distribution summary:
```
  Versions:
    v1              15/20 (75%)
    v2              5/20 (25%)
  Tracks:
    stable          15/20 (75%)
    canary          5/20 (25%)
```

### Build-Time Version Info

Version, git commit SHA, and build timestamp are injected at build time via ldflags. The platform CI/CD pipeline can set `VERSION` during the build:

```sh
make VERSION=v1.2.0 docker-build
```

At runtime, the platform can override the version via `APP_VERSION` env var and set `APP_COLOR`/`APP_TRACK` as needed for the active rollout strategy.

## Use Cases

- **Canary verification** — check `X-App-Version`/`X-App-Track` headers to verify traffic split
- **Blue-green verification** — check `X-App-Color` header to confirm active deployment
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
| `APP_VERSION` | build-time version | Overrides the version reported in headers and `/info` |
| `APP_COLOR` | _(unset)_ | Blue-green color identifier (e.g., `blue`, `green`) |
| `APP_TRACK` | _(unset)_ | Canary track identifier (e.g., `stable`, `canary`) |
