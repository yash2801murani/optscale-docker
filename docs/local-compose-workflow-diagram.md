# OptScale Local Compose Workflow Diagram

This document shows the end-to-end local startup path for the Phase 1 Docker Compose stack.

## Startup Flow

```mermaid
flowchart TD
    A["Developer runs `make up`"] --> B["Makefile: `prepare`"]
    B --> C["`.env` is created from `.env.example` if missing"]
    B --> D["`tools/render_local_config.py` renders `docker/local/config.yaml` from `docker/local/config.yaml.tpl`"]
    A --> E["`docker compose up -d`"]
    E --> F["`docker-compose.yml` loads service graph and `.env`"]

    F --> G["Stateful services start first"]
    G --> G1["etcd"]
    G --> G2["mariadb"]
    G --> G3["mongo"]
    G --> G4["rabbitmq"]
    G --> G5["redis"]
    G --> G6["clickhouse"]
    G --> G7["influxdb"]
    G --> G8["minio"]

    G1 --> H["`configurator` container starts from `docker_images/configurator/Dockerfile`"]
    G2 --> H
    G3 --> H
    G4 --> H
    G5 --> H
    G6 --> H
    G7 --> H
    G8 --> H

    D --> H
    H --> I["`configurator.py` reads `docker/local/config.yaml`"]
    I --> J["Writes service config into `etcd`"]
    I --> K["Creates databases, queues, buckets, and bootstrap keys"]
    J --> L["`/configured` key written to `etcd`"]
    K --> L

    L --> M["Application services wait on healthy dependencies"]
    M --> M1["auth"]
    M --> M2["restapi"]
    M --> M3["keeper"]
    M --> M4["herald-api"]
    M --> M5["herald-engine"]
    M --> M6["katara"]
    M --> M7["katara-worker"]
    M --> M8["metroculus-api"]
    M --> M9["metroculus-worker"]
    M --> M10["metroculus-scheduler"]
    M --> M11["trapper-worker"]
    M --> M12["trapper-scheduler"]
    M --> M13["diworker"]
    M --> M14["bumiworker"]
    M --> M15["bumischeduler"]
    M --> M16["slacker"]
    M --> M17["jira-bus"]

    M1 --> N["`ngui` starts from `ngui/Dockerfile`"]
    M2 --> N
    M3 --> N
    M16 --> N
    M17 --> N

    N --> O["`ngui/server/server.ts` loads backend service URLs"]
    O --> P["`nginx` serves host port 80"]
    P --> Q["Browser reaches `http://localhost`"]

    Q --> R["`/` routes to `ngui`"]
    Q --> S["`/api` routes to `ngui` GraphQL/API server"]
    Q --> T["`/auth`, `/restapi`, `/jira_bus` are proxied for compatibility"]

    S --> U["`ngui` calls internal services using container DNS"]
    U --> U1["`http://auth:8905`"]
    U --> U2["`http://restapi:8999`"]
    U --> U3["`http://keeper:8973`"]
    U --> U4["`http://slacker:80`"]

    style A fill:#1f2937,color:#fff,stroke:#111827
    style P fill:#b45309,color:#fff,stroke:#78350f
    style Q fill:#0f766e,color:#fff,stroke:#115e59
    style H fill:#374151,color:#fff,stroke:#111827
    style N fill:#2563eb,color:#fff,stroke:#1d4ed8
```

## What To Read First

- `Makefile` controls the local bootstrap.
- `docker-compose.yml` defines the runtime graph and dependency order.
- `docker/local/config.yaml.tpl` defines the `etcd` seed data.
- `docker_images/configurator/configurator.py` turns the rendered config into live cluster state.
- `nginx.conf` and `ngui/server/server.ts` define the request path from the browser into the backend services.
