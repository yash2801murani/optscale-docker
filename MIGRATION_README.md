# OptScale Migration Readme

## Executive Summary

### Why We Moved Away From `runkube.py`

The legacy local deployment model was tightly coupled to a custom Python wrapper, Ansible orchestration, and a Kubernetes bootstrap path that was optimized for historical convenience rather than long-term maintainability. In practice, that approach made the development lifecycle harder to reason about: application boot logic, environment setup, infrastructure assumptions, and cluster state were all intertwined.

From an engineering and platform standpoint, this created four recurring problems:

| Legacy Challenge | Engineering Impact | Business Impact |
| --- | --- | --- |
| Custom wrapper-driven startup | Opaque boot sequence and difficult troubleshooting | Slower onboarding and increased support overhead |
| Kubernetes required for local iteration | Excess complexity for feature development and debugging | Higher developer resource cost |
| Configuration spread across Helm, ConfigMaps, and wrapper logic | Fragile local reproducibility | More time lost to environment drift |
| Application behavior coupled to infrastructure bootstrap | Harder to modernize or re-platform safely | Increased delivery risk for future platform work |

### Business Value Delivered in Phase 1

Phase 1 deliberately decoupled **application runtime concerns** from **cluster orchestration concerns** by moving the platform into a clean, modular Docker Compose stack for local VM development.

This created immediate operational and business value:

- **Faster developer onboarding:** Engineers can now start the platform with a small, explicit toolchain instead of learning a custom wrapper and local Kubernetes bootstrap flow.
- **Lower resource overhead for local testing:** Docker Compose is significantly lighter for day-to-day development than provisioning a full local cluster.
- **Clearer separation of concerns:** The application can now be validated independently from Kubernetes, reducing migration risk and making failures easier to isolate.
- **Improved change velocity:** Local smoke testing, service debugging, and config iteration are materially simpler and faster.

### Strategic End State: Phase 2

Phase 1 was not the destination. It was the control point that lets us move to Phase 2 with confidence.

The Phase 2 target is a **high-availability, auto-scaling, cloud-native Kubernetes deployment** with production-grade workload management, secrets handling, persistent storage, and ingress controls. By first stabilizing the platform in Docker Compose, we created a clean intermediate architecture that is substantially easier to translate into enterprise Kubernetes patterns.

## Phase 1: Docker Compose Migration

### Overview

Phase 1 converted the OptScale platform from a wrapper-driven local Kubernetes dependency into a **single, reproducible Docker Compose stack**. The result is a local runtime that builds directly from repository Dockerfiles, uses persistent local state, and preserves the original service topology closely enough to support a low-risk transition into Kubernetes later.

### Step 1: Establish the Stateful Foundation

The first step was to identify and isolate the platform’s stateful dependencies from the Helm templates and model them directly in Compose.

The resulting local stack includes:

| Service Type | Local Service | Purpose | Persistence Strategy |
| --- | --- | --- | --- |
| Relational database | MariaDB | Auth, REST API, Herald, Katara, Slacker, Jira Bus data | Named Docker volume |
| Document database | MongoDB | Keeper and report/import workloads | Named Docker volume |
| Message broker | RabbitMQ | Inter-service async messaging | Named Docker volume |
| Key-value config store | Etcd | Runtime configuration and service discovery | Named Docker volume |
| Cache / ephemeral store | Redis | Application cache and session-adjacent workloads | Named Docker volume |
| Analytics database | ClickHouse | Cost and metrics analytics | Named Docker volumes |
| Time-series store | InfluxDB | Metrics storage | Named Docker volume |
| Object storage | MinIO | S3-compatible local artifact and bucket workflows | Named Docker volume |

Key engineering decisions:

- **Official lightweight images** were used wherever possible to reduce image complexity.
- **Persistent named volumes** were enabled for all stateful services to avoid data loss across container restarts.
- **Internal ports were mapped with `expose`**, not broadly published to the host, preserving service isolation.
- **Healthchecks** were added so application services could start only after dependencies were actually ready.

### Step 2: Centralize Configuration

The legacy deployment relied heavily on Kubernetes `ConfigMaps`, `Secrets`, and Helm-templated service discovery. To support local Compose operation cleanly, configuration needed to become explicit and portable.

We introduced:

| Artifact | Role |
| --- | --- |
| `.env.example` | Canonical list of local environment variables with safe defaults |
| `.env` | Local developer override file |
| `docker/local/config.yaml.tpl` | Rendered template for `etcd` seed data |
| `tools/render_local_config.py` | Lightweight renderer for generating the local config artifact |

This gave us a deterministic configuration path:

1. Compose consumes `.env`.
2. `make prepare` renders `docker/local/config.yaml`.
3. `configurator` writes the required runtime keys into `etcd`.
4. Services read from `etcd` exactly as they did in the Helm/Kubernetes flow.

This was a critical design choice. Rather than rewriting the application to eliminate `etcd` immediately, we preserved the existing config contract and made it local-first. That reduced risk and allowed us to modernize the runtime without rewriting core application assumptions.

### Step 3: Wire Up the Python Microservices

Once persistence and configuration were stable, we mapped the core Python services into Compose and built them directly from the source tree.

Representative services included:

- `auth`
- `restapi`
- `keeper`
- `diworker`
- `herald-api`
- `herald-engine`
- `katara`
- `katara-scheduler`
- `katara-worker`
- `metroculus-api`
- `metroculus-worker`
- `metroculus-scheduler`
- `trapper-worker`
- `trapper-scheduler`
- `bumiworker`
- `bumischeduler`
- `slacker`
- `jira-bus`

Each service was configured to:

- **build from the local repository Dockerfile**
- **consume the shared environment contract**
- **wait on healthy upstream dependencies**
- **preserve the original service topology and startup assumptions**

This gave us an important modernization win: local validation now runs against the same service images the repository itself defines, instead of depending on a secondary orchestration wrapper to assemble runtime behavior.

### Step 4: Configure the API Gateway and Frontend

The presentation layer required special treatment because the OptScale frontend is not just static assets; the `ngui` service includes a Node.js server that acts as part of the API flow.

The local gateway architecture is:

| Component | Role |
| --- | --- |
| `nginx` | Public entry point on host port `80` |
| `ngui` | React frontend plus Node.js server-side GraphQL/API handling |
| `auth`, `restapi`, `jira-bus`, others | Internal backend services behind the gateway |

Important routing note:

- **`/api` traffic routes to the `ngui` Node.js server**, not directly to `restapi`.
- This is required because `ngui` acts as the GraphQL/API aggregation layer and then fans out internally to `auth`, `restapi`, `keeper`, `slacker`, and related services.

This design mirrors the real application behavior and prevented us from incorrectly flattening the request path into a simple reverse proxy pattern.

### Step 5: Improve Developer Experience

To make the new platform usable from a fresh clone, we added a small but important DX layer around the Compose stack.

The `Makefile` now provides a repeatable local workflow:

| Command | Purpose |
| --- | --- |
| `make prepare` | Ensure `.env` exists and render the local `etcd` seed config |
| `make build` | Build local images from repository Dockerfiles |
| `make up` | Start the full stack |
| `make down` | Stop the stack |
| `make logs` | Tail container logs |
| `make ps` | Inspect service status |
| `make migrate` | Run database migrations inside the appropriate containers |

This is the difference between “a set of containers” and “a usable platform.” It reduces tribal knowledge, shortens time to first successful boot, and gives the engineering team a common operational contract.

## Technical Hurdles & SRE Solutions

The first smoke test surfaced several issues that were not obvious at design time. These were not incidental bugs; they were exactly the kinds of platform integration issues that surface during a real migration.

### 1. The CronJob Dilemma

`metroculus-scheduler` and `trapper-scheduler` initially appeared unstable because they repeatedly exited and restarted under Compose.

#### Problem

These workloads are modeled upstream in Kubernetes as **`CronJob` resources**, not long-running daemons. Under a generic Compose restart policy, they appeared to crash-loop even though they were often exiting successfully after completing their work.

#### Solution

We treated them according to their real operational model:

- configured them as **one-shot jobs**
- required them to **wait for `restapi` to be healthy**
- allowed them to **exit `0` cleanly** instead of being forced into daemon semantics

#### Outcome

The Compose model now reflects the intent of the original Kubernetes design instead of masking it with a misleading restart loop.

### 2. The Environment Variable Scope Issue

`restapi` initially failed because it lost access to the required `HX_ETCD_*` variables.

#### Problem

In Docker Compose, service-level `environment:` blocks were unintentionally overriding the shared environment anchor. As a result, some services lost `HX_ETCD_HOST` and `HX_ETCD_PORT`, defaulted incorrectly, and attempted to talk to `etcd` on the wrong port.

#### Solution

We explicitly preserved the shared ETCD environment in service definitions by:

- defining a common application environment anchor
- re-merging that shared environment into services that declare additional variables
- restoring the default shared environment for services that do not override their environment block

#### Outcome

Core services such as `restapi` retained the correct runtime configuration and booted reliably.

### 3. The Configurator Seed Problem

`diworker` initially crash-looped even after infrastructure health was stable.

#### Problem

The service depended on keys in `etcd` that were normally present in the Helm/Kubernetes deployment path, but those keys were not yet included in the local seed template.

#### Solution

We updated `docker/local/config.yaml.tpl` so `configurator` seeded the required `diworker` branch into `etcd` before the worker started.

#### Outcome

`diworker` stopped crash-looping and was able to start successfully against the local stack.

### Additional Stabilization Work

Beyond the three headline issues above, we also resolved several adjacent platform problems during smoke testing:

| Issue | Resolution |
| --- | --- |
| `etcd` healthcheck incompatible with minimal image | Replaced shell-dependent checks with compatible exec-based healthchecks |
| MariaDB healthcheck command mismatch | Updated healthcheck to use the image-appropriate admin tool |
| Missing legacy API support in `etcd` | Enabled v2 API compatibility for existing config client behavior |
| Missing `stripe` seed config | Added local `stripe` branch to avoid organization setup failures |
| Missing `katara` seed config | Added local `katara` service discovery branch for report subscription setup |
| `nginx` redirecting `/api` POST traffic | Added explicit `/api` handling and validated the live gateway config |
| `ngui` calling internal services on port `80` by default | Passed explicit backend service endpoints with ports into the frontend container |

This is exactly why Phase 1 matters: it exposed and resolved the operational assumptions embedded in the platform before introducing production Kubernetes complexity.

## Phase 2 Roadmap: The Enterprise Kubernetes Evolution

With the local Compose architecture now stable, we have a clean foundation for the production-grade Kubernetes migration.

### Phase 2 Objectives

Phase 2 will focus on moving from a stable local service topology to a **resilient, scalable, enterprise Kubernetes platform**.

The roadmap is outlined below.

### 1. Container Registry Strategy

The first production step is to formalize image publication.

#### Plan

- tag local service images with versioned, traceable release identifiers
- push them to a central registry such as **Docker Hub**, **Amazon ECR**, or another enterprise-approved registry
- separate local build concerns from cluster deployment concerns

#### Why It Matters

Kubernetes should deploy immutable artifacts from a trusted registry, not build ad hoc from source inside the cluster lifecycle.

### 2. Configuration Management

The current local setup uses `.env` plus rendered `etcd` seed configuration. In Kubernetes, this will be translated into production-native configuration objects.

#### Plan

| Current Local Artifact | Kubernetes Target |
| --- | --- |
| `.env` values | `ConfigMap` and `Secret` resources |
| `docker/local/config.yaml.tpl` | templated seed config delivered via `ConfigMap` / init workflow |
| local secrets in plain env vars | encoded Kubernetes `Secret` objects |

#### Why It Matters

This gives us:

- auditable configuration boundaries
- environment-specific overrides
- secure secret distribution
- compatibility with GitOps or Helm-based deployment workflows

### 3. Workload Deployment Model

Standard Compose services will be translated into Kubernetes-native workload types.

#### Plan

- convert long-running stateless services into **Deployments**
- manage inter-service startup dependencies with **InitContainers**, readiness probes, and health probes
- preserve separation between API services, workers, schedulers, and one-shot bootstrap tasks

#### Expected Mapping

| Service Pattern | Kubernetes Resource |
| --- | --- |
| Long-running API / worker | `Deployment` |
| One-shot bootstrap step | `Job` |
| Periodic scheduler workload | `CronJob` |

#### Why It Matters

This avoids forcing Kubernetes to emulate Compose behavior and instead lets each workload type be modeled according to its true runtime purpose.

### 4. Stateful Data Strategy

Databases and brokers require a different treatment than stateless services.

#### Plan

Stateful dependencies such as MariaDB, MongoDB, RabbitMQ, Redis, ClickHouse, and Etcd will be evaluated and deployed using **StatefulSets** with **PersistentVolumeClaims (PVCs)** where appropriate.

#### Why StatefulSets and PVCs Matter

- Pod identity remains stable across rescheduling.
- Persistent data survives node replacement or pod recreation.
- Storage is managed explicitly rather than implicitly tied to a single VM.
- The platform can withstand node failures without losing critical service state.

This is a foundational requirement for enterprise reliability and disaster recovery.

### 5. Networking and Ingress

The Compose stack currently exposes the platform via a local `nginx` container and host port forwarding. In Kubernetes, ingress and service discovery must become production-grade.

#### Plan

- replace local host port exposure with internal Kubernetes **Services**
- expose the platform externally through a production **Ingress Controller**
- apply TLS termination, host-based routing, and path-based routing centrally
- support internal service discovery through cluster DNS instead of Compose networking

#### Why It Matters

This is the layer that turns a working stack into an enterprise platform:

- secure external access
- controlled routing
- cleaner traffic policy management
- compatibility with WAF, TLS automation, and cloud load balancers

## Recommended Next Actions

To move from Phase 1 completion into Phase 2 execution, the recommended sequence is:

1. Finalize and review the Compose-based service contract as the canonical local reference architecture.
2. Freeze image build inputs and establish a versioned container publishing workflow.
3. Classify workloads by Kubernetes target type: `Deployment`, `Job`, `CronJob`, `StatefulSet`.
4. Convert local configuration assets into Kubernetes `ConfigMaps`, `Secrets`, and seed-init patterns.
5. Define persistent storage requirements and cloud storage classes for each stateful service.
6. Introduce ingress, service mesh considerations if required, and production readiness probes.

## Closing Position

Phase 1 was a successful modernization milestone because it did more than “make Docker Compose work.” It extracted the OptScale platform from a legacy local orchestration model, made the runtime understandable, exposed hidden infrastructure assumptions, and created a stable platform contract for the next stage of evolution.

That positions Phase 2 to be executed as a **deliberate cloud-native migration**, not a risky lift-and-shift.

From a client perspective, that means lower delivery risk, faster engineering iteration, and a clearer path to a scalable enterprise deployment model. From an engineering perspective, it means we now have the right abstraction boundary to move into Kubernetes the right way.
