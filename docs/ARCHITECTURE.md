# Architecture

## 1. Overview

This document describes the architecture of the **aws-microservices-ci-cd-pipeline** project: two Node.js microservices (customer-service and employee-service), their local and containerized run model, and the intended AWS deployment (ECR, ECS, ALB) with CI/CD (CodeBuild, CodePipeline, CodeDeploy). The project was reconstructed from AWS lab phases and a verified local implementation to serve as portfolio-grade documentation of a microservices and DevOps stack on AWS.

---

## 2. System Components

| Component | Role |
|-----------|------|
| **customer-service** | Node.js/Express service; public supplier views and APIs; port 3000. |
| **employee-service** | Node.js/Express service; admin supplier management; port 3001. |
| **Docker** | Containerization for both services; used locally (Compose) and in AWS (ECS). |
| **ECR** | Registry for Docker images of both services. |
| **ECS** | Runs the containerized services (Fargate or EC2). |
| **ALB** | Single entry point; routes by path to the appropriate service. |
| **CodeBuild** | Builds images and pushes to ECR; produces deployment artifact. |
| **CodePipeline** | Orchestrates source, build, and deploy. |
| **CodeDeploy** | ECS blue/green (or rolling) deployments using AppSpecs. |

---

## 3. Service Responsibilities

### customer-service (port 3000)

- **Purpose** — Public-facing supplier information and APIs.
- **Endpoints** — `/` (root), `/health` (health check), `/suppliers` (supplier list or placeholder).
- **Scope** — Read-oriented, customer-facing; no admin operations.

### employee-service (port 3001)

- **Purpose** — Administrative supplier management.
- **Endpoints** — `/` (root), `/health` (health check), `/admin/suppliers` (admin supplier management).
- **Scope** — Admin-only; separated from customer traffic for security and scaling.

Separation allows independent scaling, clearer security boundaries, and separate deployment lifecycles.

---

## 4. Local Architecture

- **Runtime** — Node.js (e.g. 20); each service runs via `npm start` or `node index.js`.
- **Ports** — customer-service on 3000, employee-service on 3001. Ports are configurable via `process.env.PORT` with these defaults.
- **Docker Compose** — Two services defined in `docker-compose.yml`; each builds from its own Dockerfile under `services/`. Host ports 3000 and 3001 map to container ports 3000 and 3001.
- **No shared database in scope** — Services are stateless at the application layer for this project; data persistence is out of scope for the current architecture doc.
- **Verification** — Local and Docker Compose runs have been verified; see `docs/FINAL-VERIFICATION.md`.

---

## 5. Intended AWS Deployment Architecture

```
                    ┌─────────────────┐
                    │   CodePipeline  │
                    │  (Source → Build → Deploy)
                    └────────┬────────┘
                             │
         ┌──────────────────┼──────────────────┐
         │                  │                  │
         ▼                  ▼                  ▼
   ┌──────────┐      ┌──────────┐      ┌─────────────┐
   │ CodeBuild│      │   ECR    │      │ CodeDeploy  │
   │ (buildspec)      │ (images) │      │ (appspecs)  │
   └────┬─────┘      └────┬─────┘      └──────┬──────┘
        │                 │                    │
        └─────────────────┴────────────────────┘
                          │
                          ▼
                   ┌─────────────┐
                   │    ECS      │
                   │ (2 services)│
                   └──────┬──────┘
                          │
                          ▼
                   ┌─────────────┐
                   │    ALB      │
                   │ (path-based│
                   │  routing)  │
                   └──────┬──────┘
                          │
                    [ External traffic ]
```

- **ECR** — Two repositories (`customer-service`, `employee-service`). CodeBuild pushes tagged images; ECS pulls by image URI from the deployment artifact.
- **ECS** — Two ECS services (one per microservice). Each service runs tasks from a task definition that specifies the container image, container name, and container port (3000 or 3001). Target groups register tasks for the ALB.
- **ALB** — One Application Load Balancer. Listener rules route by path to the appropriate target group (and thus to the correct ECS service and port).
- **VPC** — ECS tasks and ALB run inside a VPC; security groups restrict traffic appropriately (e.g. ALB receives internet traffic; tasks receive traffic only from the ALB and within the VPC as needed).

---

## 6. Request Routing

| Path | Target service | Port | Purpose |
|------|----------------|------|---------|
| `/` | customer-service | 3000 | Root / landing |
| `/suppliers` | customer-service | 3000 | Public supplier list |
| `/admin/suppliers` | employee-service | 3001 | Admin supplier management |

Health checks use `/health` on each service (3000 and 3001). The ALB listener rules forward requests by path to the correct target group; each target group forwards to tasks listening on the corresponding container port. Container names and ports in ECS task definitions and AppSpecs match: `customer-service` on 3000, `employee-service` on 3001.

---

## 7. CI/CD Relationship to Architecture

- **Source** — Pipeline pulls from the repo (e.g. GitHub). The same codebase produces both service images.
- **Build** — CodeBuild runs `cicd/buildspec.yml`: builds both Docker images, tags with commit SHA and `latest`, pushes to ECR, writes `build/imagedefinitions.json` with image URIs by service name. The artifact is the only handoff to deploy.
- **Deploy** — Pipeline uses `imagedefinitions.json` to create or update ECS task definition revisions, then CodeDeploy runs per ECS service using `cicd/appspec.yaml` (customer-service) and `cicd/appspec-employee.yaml` (employee-service). AppSpecs define the target ECS service, task definition, and load balancer mapping (container name and port). Traffic shifts to the new tasks.

CI/CD does not change the runtime architecture (two services, two ports, path-based routing); it automates building, registry push, and ECS deployment so that each pipeline run produces a consistent, traceable deploy.

---

## 8. Design Decisions

- **Two services, two ports** — Clear boundary between customer-facing and admin; simplifies routing and future scaling.
- **Single repo, two images** — One codebase and one pipeline; both images built and tagged together from the same commit.
- **Path-based routing at ALB** — No API gateway in scope; ALB listener rules are sufficient for `/`, `/suppliers`, and `/admin/suppliers`.
- **One AppSpec per ECS service** — CodeDeploy allows one TargetService per AppSpec; the pipeline runs two deploy actions (or equivalent) for the two services.
- **Commit-based image tags** — Traceability from deployment back to source; `latest` is optional for convenience.
- **No shared state in app layer** — Services are stateless for this design; persistence and cross-service calls are out of scope for this document.

---

## 9. Assumptions

- ECR repositories exist for both services in the same account/region as the pipeline.
- ECS cluster, service definitions, task definitions (with container names `customer-service` and `employee-service` and ports 3000 and 3001), and ALB with target groups and listener rules are created outside the pipeline or by separate automation.
- CodeBuild has access to Docker and to ECR (IAM); CodePipeline/CodeDeploy have permissions to update ECS and read ECR as needed.
- Source is a single branch (e.g. `main`); image tag is derived from commit SHA unless overridden.
- Network and security (VPC, subnets, security groups) are configured so that ALB can reach ECS tasks on the correct ports.

---

## 10. Future Architectural Improvements

- **API Gateway** — Optional front door for versioning, throttling, or request validation before the ALB.
- **Service-to-service** — If employee-service or customer-service need to call each other, introduce service discovery (e.g. Cloud Map) or internal ALB/route patterns and document the new flows.
- **Secrets and config** — Use Secrets Manager or Parameter Store for environment-specific config; inject at task definition or runtime.
- **Observability** — Centralized logging (e.g. CloudWatch Logs), metrics, and tracing (e.g. X-Ray) for both services.
- **Multi-environment** — Separate ECR repos, ECS clusters, or accounts for dev/staging/production with the same architecture and pipeline pattern.
- **Database** — Add RDS or similar when persistence is required; keep each service’s data boundary clear.

These extensions keep the current two-service, path-routed, container-on-ECS design and add capabilities without changing the core architecture.
