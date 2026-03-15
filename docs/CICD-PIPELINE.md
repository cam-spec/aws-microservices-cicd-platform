# CI/CD Pipeline

## 1. Overview

This document describes the CI/CD pipeline for the **aws-microservices-ci-cd-pipeline** repository. The pipeline is designed to build two Node.js microservices (customer-service on port 3000, employee-service on port 3001), containerize them with Docker, push images to Amazon ECR, and support deployment to ECS via CodeDeploy. The pipeline artifacts were **reconstructed** from AWS lab phase documentation and repository traces; local services and Docker Compose have been verified. The result is portfolio-grade documentation of a full DevOps flow: source → build → registry → deploy, with clear separation between build and deployment stages.

---

## 2. Pipeline Architecture

End-to-end flow from developer commit to end users:

**Developer Commit → CodePipeline → CodeBuild → ECR → CodeDeploy/ECS → ALB → End Users.**

```
  Developer Commit
         │
         ▼
  CodePipeline (orchestrates stages)
         │
         ▼
  CodeBuild (Docker build & push)
         │
         ▼
  ECR (container registry)
         │
         ▼
  CodeDeploy / ECS (blue/green deployment)
         │
         ▼
  ALB (path-based routing)
         │
         ▼
  End Users
```

---

## 3. Pipeline Objective

The pipeline aims to:

- Build Docker images for both microservices from a single source repository.
- Tag images for traceability (short commit SHA and `latest`).
- Push images to Amazon ECR using IAM-based authentication (no long-lived credentials).
- Produce a deployment artifact (`imagedefinitions.json`) for downstream ECS task definition updates.
- Support ECS blue/green deployments via CodeDeploy using AppSpec files.

Each run is tied to a specific source revision so that builds and deployments are reproducible.

---

## 4. Services Included

| Service             | Port | Endpoints |
|---------------------|------|-----------|
| **customer-service** | 3000 | `/`, `/health`, `/suppliers` |
| **employee-service** | 3001 | `/`, `/health`, `/admin/suppliers` |

Both services expose a root, a health endpoint (JSON), and a domain route. Local and Docker Compose verification are complete; see `docs/FINAL-VERIFICATION.md`.

---

## 5. CI/CD Workflow

1. **Source** — CodePipeline connects to the repo (e.g. GitHub or CodeCommit), watches a branch (typically `main`), and clones the repository into the build environment on each run.
2. **Build** — CodeBuild runs `cicd/buildspec.yml`: ECR login, Docker build for both services, tag with commit SHA and `latest`, push to ECR, and write `build/imagedefinitions.json`.
3. **Artifact** — The build output (including `imagedefinitions.json`) is passed to the deployment stage.
4. **Deploy** — In the intended flow, the pipeline uses the artifact and the AppSpec files to create or update ECS task definition revisions and run CodeDeploy; traffic is then shifted to the new tasks.

Flow: **Source → Build → Deploy**. In the intended AWS pipeline flow, the happy path is designed to run without manual intervention.

---

## 6. Build Stage

The build stage runs on **AWS CodeBuild** and is defined in **`cicd/buildspec.yml`** (version 0.2). It has four phases:

- **Install** — Sets up the environment (Node.js 20, Docker availability check). CodeBuild’s standard image provides Docker.
- **Pre-build** — Derives the image tag from `CODEBUILD_RESOLVED_SOURCE_VERSION` (first 7 characters of the commit SHA), obtains the account ID via `aws sts get-caller-identity`, sets the ECR base URI, and logs in to ECR with `aws ecr get-login-password` piped into `docker login`.
- **Build** — Runs `docker build` for `./services/customer-service` and `./services/employee-service`, tagging each image with the ECR repo name plus `$IMAGE_TAG` and `latest`.
- **Post-build** — Pushes all four tags to ECR (two repos × two tags), then writes `build/imagedefinitions.json` with the two image URIs keyed by service name.

The only artifact is `build/imagedefinitions.json`; it is consumed by the deployment stage to update ECS services.

**Example `imagedefinitions.json`** (commit-based tag; account/region placeholders):

```json
[
  {
    "name": "customer-service",
    "imageUri": "123456789012.dkr.ecr.us-east-1.amazonaws.com/customer-service:abc1234"
  },
  {
    "name": "employee-service",
    "imageUri": "123456789012.dkr.ecr.us-east-1.amazonaws.com/employee-service:abc1234"
  }
]
```

---

## 7. ECR Image Push Stage

After the build phase, both images are pushed to **Amazon ECR**:

- **Repositories** — `customer-service` and `employee-service` (names are set in the buildspec `env` section).
- **Tags per image** — Commit-based tag (e.g. 7-char SHA) for traceability and deployment; `latest` for convenience. The deployment artifact uses the commit-based tag so ECS pulls a specific digest.
- **Authentication** — IAM only. The CodeBuild role needs `ecr:GetAuthorizationToken` and push permissions on both repositories. No Docker credentials are stored in the pipeline.

The push is part of the buildspec’s `post_build` phase. The result is two ECR repositories, each with the expected tags for the current run.

---

## 8. Deployment Stage

In the intended design, the deployment stage uses the build artifact and the AppSpec files to update **Amazon ECS**:

1. A **new task definition revision** is created (or updated) with the image URIs from `imagedefinitions.json`. Each entry maps a service name (`customer-service`, `employee-service`) to an ECR image URI.
2. **CodeDeploy** runs an ECS blue/green deployment for each ECS service. Customer-service uses **`cicd/appspec-customer.yaml`**; employee-service uses **`cicd/appspec-employee.yaml`**. Each AppSpec has one TargetService: task definition ARN (injected by the pipeline at deploy time), container name, and container port for the load balancer. For ECS, AppSpec files use **version 0.0** (required by CodeDeploy).
3. Traffic is shifted from the old tasks to the new ones. The **Application Load Balancer** targets the containers on port 3000 (customer-service) and 3001 (employee-service), as specified in the AppSpecs and in the ECS task definitions.

The design assumes ECS services and ALB target groups already exist; the deploy stage would update the services with the new task revision and shift traffic accordingly.

---

## 9. Role of buildspec.yml

**`cicd/buildspec.yml`** is the single source of truth for the CodeBuild job. It:

- Defines the build environment (Node.js 20, Docker check).
- Encapsulates ECR login, image naming, tagging, and push for both microservices.
- Produces the deployment artifact `build/imagedefinitions.json` that the deploy stage uses to update ECS task definitions.

Because the buildspec lives in the repo, build behavior is versioned and reviewable. ECR repo names and optional overrides (e.g. image tag) can be set in the buildspec’s `env` or in the CodeBuild project; account ID is obtained at build time via `aws sts get-caller-identity`; region is typically provided by CodeBuild or the pipeline.

---

## 10. Role of AppSpec Files

**AppSpec** files tell CodeDeploy how to deploy to ECS. CodeDeploy allows only **one TargetService per AppSpec**, so this project uses two files (both with **version 0.0**, as required for ECS):

- **`cicd/appspec-customer.yaml`** — Customer-service. Specifies the target ECS service, task definition ARN (placeholder filled at deploy time), and `LoadBalancerInfo`: container name `customer-service`, container port **3000**.
- **`cicd/appspec-employee.yaml`** — Employee-service. Same structure: container name `employee-service`, container port **3001**.

The pipeline injects the actual task definition ARN when it creates or selects the new revision from `imagedefinitions.json`. Container names and ports in the AppSpecs must match the ECS task definitions and the ALB target groups so that health checks and routing use the correct ports.

---

## 11. AWS Services Involved

| Service        | Role |
|----------------|------|
| **CodePipeline** | Orchestrates source, build, and deploy stages. |
| **CodeBuild**    | Runs the buildspec; builds and pushes Docker images to ECR. |
| **ECR**          | Stores Docker images for customer-service and employee-service. |
| **ECS**          | Runs the tasks (Fargate or EC2) for both services. |
| **CodeDeploy**   | Performs ECS blue/green deployments using the AppSpecs. |
| **ALB**          | Routes traffic (e.g. `/`, `/suppliers` → customer-service:3000; `/admin/suppliers` → employee-service:3001). |
| **IAM**          | Roles for CodeBuild (ECR push) and CodePipeline/CodeDeploy (ECS, ECR pull). |

VPC, security groups, and optionally Parameter Store or Secrets Manager are used as needed for the environment.

---

## 12. Verification Status

**Local and Docker (completed):**

- customer-service runs on port 3000; endpoints `/`, `/health`, `/suppliers` verified.
- employee-service runs on port 3001; endpoints `/`, `/health`, `/admin/suppliers` verified.
- Docker Compose builds and runs both services; endpoint behavior matches local runs.

**Pipeline (when wired in AWS):**

- CodeBuild is expected to complete without error; both images should appear in ECR with the expected tags.
- `imagedefinitions.json` should contain the correct ECR URIs and service names.
- With the deploy stage configured, ECS services would update to the new task revision and traffic would shift; ALB URLs for the above paths would then behave like local and Docker.

See `docs/FINAL-VERIFICATION.md` for detailed verification notes, including the port conflict (3001) and resolution.

---

## 13. Reconstruction Notes and Assumptions

The pipeline artifacts were **reconstructed** from:

- Phase folders (e.g. phase-5 ECR, phase-6 ECS/ALB, phase-7/8 deployment and pipeline) describing the original lab.
- Repository layout (`services/`, `cicd/`, `infrastructure/`) and existing buildspec/AppSpec placeholders.
- Verified local and Docker Compose behavior (ports 3000 and 3001, health endpoints, routes).

Assumptions:

- Two ECR repositories (`customer-service`, `employee-service`) exist in the same account and region as the pipeline.
- CodeBuild runs in an environment where Docker is available (e.g. standard image).
- ECS task definitions use container names `customer-service` and `employee-service` and expose ports 3000 and 3001.
- The pipeline is triggered from a single branch (e.g. `main`); image tag is derived from the commit SHA unless overridden.
- One AppSpec per ECS service; task definition ARNs are supplied at deploy time (e.g. from a “Create Task Definition” or equivalent step).

---

## 14. Pipeline Failure Behavior

When a build or deployment fails, the pipeline stops at that stage and does not proceed. Understanding this behavior helps with debugging and ensures users are not served broken changes.

- **Build failure** — If CodeBuild fails (e.g. Docker build error, ECR push failure, or a failing test added to the build), the pipeline marks the build stage as failed. No new images are pushed for that run, and the deploy stage does not execute. Existing ECS tasks are unchanged; end users continue to be served by the last successfully deployed revision.

- **Deploy failure** — If CodeDeploy fails (e.g. new tasks fail health checks, or a deployment is stopped), CodeDeploy does not shift traffic to the new tasks. The previous ECS task set continues to receive traffic from the ALB, so end users keep using the last known-good version. The pipeline run is marked failed, and the failed deployment can be investigated or rolled back via the CodeDeploy console.

- **Traffic retention** — CodeDeploy's ECS blue/green behavior keeps the original (blue) tasks in service until the new (green) tasks are healthy and traffic is shifted. If the green deployment fails or is stopped, the blue tasks remain the active target of the ALB. This avoids serving broken or partially updated containers to end users.

---

## 15. Future Improvements

- **Parameter Store / Secrets Manager** — Move ECR repo names or image tag overrides into parameters for multi-account or multi-environment use.
- **Tests in build** — Run unit or integration tests (e.g. `npm test`) in the build phase and fail the build on failure.
- **Deploy automation** — Add the CodePipeline deploy actions (ECS + CodeDeploy) and optional approval for production.
- **Task definition generation** — Generate or update ECS task definition JSON in the build from a template using `imagedefinitions.json`.
- **Notifications** — SNS or Slack on build/deploy success or failure.
- **Environment-specific buildspec** — Buildspec variants or env vars for dev/staging/production (e.g. different ECR repos or tags).

These keep the same design: build once, tag and push to ECR, deploy via artifact and AppSpec.
