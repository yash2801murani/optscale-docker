# OptScale Local Compose Architecture

This document explains how the Phase 1 local Docker Compose architecture works, file by file and service by service.

## 1. The Entry Point: `make up`

The local workflow starts in [Makefile](/Users/dc/migration-project/optscale/Makefile).

When a developer runs:

```bash
make up
```

the following happens:

1. `make up` depends on `prepare`.
2. `prepare` creates `.env` from `.env.example` if it does not already exist.
3. `prepare` renders `docker/local/config.yaml` from `docker/local/config.yaml.tpl`.
4. `docker compose up -d` starts the full service stack.

That means the runtime is no longer driven by a custom wrapper or a hidden bootstrap script. The startup path is explicit, reproducible, and easy to inspect.

## 2. Configuration Flow

The configuration chain is:

| Source | Output | Purpose |
| --- | --- | --- |
| `.env.example` | `.env` | Safe local defaults for developers |
| `docker/local/config.yaml.tpl` | `docker/local/config.yaml` | Seed configuration for `etcd` |
| `docker-compose.yml` | Running services | Service graph and dependency order |

The rendered `docker/local/config.yaml` is especially important because it preserves the existing application expectation that many runtime settings live in `etcd`.

## 3. Stateful Services First

The Compose file starts the stateful foundation before the application services.

The local stack includes:

- `etcd`
- `mariadb`
- `mongo`
- `rabbitmq`
- `redis`
- `clickhouse`
- `influxdb`
- `minio`

Each of these services uses a persistent Docker volume so the local VM keeps data across restarts.

Healthchecks gate the app startup so the Python services do not start until the infrastructure is actually ready.

## 4. Config Bootstrap: `configurator`

The `configurator` service is built from [docker_images/configurator/Dockerfile](/Users/dc/migration-project/optscale/docker_images/configurator/Dockerfile) and runs [docker_images/configurator/configurator.py](/Users/dc/migration-project/optscale/docker_images/configurator/configurator.py).

This service is the bridge between static local configuration and live runtime state.

### What it does

1. Reads `docker/local/config.yaml`.
2. Connects to MariaDB, MongoDB, RabbitMQ, InfluxDB, MinIO, ClickHouse, and Etcd.
3. Creates the required databases and buckets.
4. Seeds the `etcd` key tree with the runtime contract used by the application.
5. Writes the `/configured` flag into `etcd`.

### Why it matters

The application code still expects the same config semantics used in the Kubernetes deployment. `configurator` makes that possible locally without Kubernetes.

## 5. Application Services

After the infrastructure is healthy and `configurator` has populated `etcd`, the application services start.

The main services are:

- `auth`
- `restapi`
- `keeper`
- `herald-api`
- `herald-engine`
- `katara`
- `katara-worker`
- `metroculus-api`
- `metroculus-worker`
- `metroculus-scheduler`
- `trapper-worker`
- `trapper-scheduler`
- `diworker`
- `bumiworker`
- `bumischeduler`
- `slacker`
- `jira-bus`

These services all build from local Dockerfiles in the repository, so the Compose stack reflects the actual source tree.

### Dependency model

The Compose `depends_on` rules are not just cosmetic. They encode the required startup order:

- `configurator` must complete successfully before most app services start.
- `restapi` waits for `etcd`, `mariadb`, and `rabbitmq`.
- `auth` waits for `etcd` and `mariadb`.
- worker and scheduler services wait for the queues, config store, and their backend APIs.

This prevents many startup race conditions and makes local smoke testing predictable.

## 6. Frontend and Gateway

The presentation layer is split into two services:

- `ngui`
- `nginx`

### `ngui`

The `ngui` service is built from [ngui/Dockerfile](/Users/dc/migration-project/optscale/ngui/Dockerfile) and runs a Node.js server from [ngui/server/server.ts](/Users/dc/migration-project/optscale/ngui/server/server.ts).

It serves two jobs:

1. Static frontend delivery.
2. Application-side API proxying and GraphQL handling.

It is important to understand that `/api` does not go directly to `restapi`. It goes to the `ngui` server first.

The `ngui` server then calls internal services using explicit container DNS endpoints:

- `http://auth:8905`
- `http://restapi:8999`
- `http://keeper:8973`
- `http://slacker:80`

### `nginx`

The `nginx` service is the host-facing entry point on port `80`.

It routes:

- `/` to `ngui`
- `/api` and `/api/` to `ngui`
- `/auth`, `/restapi`, and `/jira_bus` for compatibility routes

## 7. The Request Path

The browser-to-backend flow is:

1. User opens the local URL in the browser.
2. The browser reaches `nginx` on host port `80`.
3. `nginx` forwards `/` and `/api` traffic to `ngui`.
4. `ngui` handles the frontend flow and makes backend calls to `auth`, `restapi`, `keeper`, `slacker`, and others.
5. Those backend services use `etcd` for runtime configuration and the stateful services for persistence.

## 8. Why This Architecture Is Better

This Compose architecture gives us the following benefits:

- Local developer environments are simple and repeatable.
- Boot order is explicit and easier to debug.
- Runtime state is isolated from infrastructure orchestration.
- The platform can be reasoned about as a service graph instead of a wrapper script.
- The same logical model can now be translated into Kubernetes more safely in Phase 2.

## 9. Files To Review First

If you want to understand the flow quickly, start with these files:

| File | Why It Matters |
| --- | --- |
| [Makefile](/Users/dc/migration-project/optscale/Makefile) | Entry point for `make up` and `make migrate` |
| [docker-compose.yml](/Users/dc/migration-project/optscale/docker-compose.yml) | Service graph, healthchecks, dependencies, volumes |
| [docker/local/config.yaml.tpl](/Users/dc/migration-project/optscale/docker/local/config.yaml.tpl) | Rendered `etcd` seed data |
| [docker_images/configurator/configurator.py](/Users/dc/migration-project/optscale/docker_images/configurator/configurator.py) | Bootstraps databases and writes config into `etcd` |
| [nginx.conf](/Users/dc/migration-project/optscale/nginx.conf) | Browser routing and reverse proxy behavior |
| [ngui/server/server.ts](/Users/dc/migration-project/optscale/ngui/server/server.ts) | Frontend server and backend service wiring |

## 10. Summary

The current architecture is a deliberate middle layer between the legacy wrapper-driven deployment and the eventual enterprise Kubernetes deployment.

It is:

- explicit
- reproducible
- local-first
- stateful where needed
- decoupled from Kubernetes for development

That makes Phase 2 much easier to execute without reintroducing the fragility we removed in Phase 1.
