# CI/CD Pipeline

## 1. Overview

This document describes the CI/CD pipeline for the **aws-microservices-ci-cd-pipeline** repository. The pipeline builds two Node.js microservices (customer-service and employee-service), containerizes them with Docker, pushes images to Amazon ECR, and deploys to ECS via CodeDeploy. It was reconstructed from lab phases and repo structure to demonstrate a full DevOps flow: source → build → registry → deploy, with clear separation between build and deployment stages. The project is intended as portfolio-grade documentation of Node.js microservices, Docker, ECR, ECS, ALB, and CI/CD on AWS.

---

## 2. Pipeline Objective

The pipeline aims to:

- Build Docker images for both microservices from a single source repository.
- Tag images for traceability (short commit SHA and `latest`).
- Push images to Amazon ECR without storing long-lived credentials (IAM-based auth).
- Produce a deployment artifact (`imagedefinitions.json`) that downstream stages use to update ECS task definitions.
- Support ECS deployments (blue/green or rolling) through CodeDeploy and AppSpec files.

Every run is tied to a specific source revision so builds and deployments are reproducible.

---

## 3. Services Included

| Service            | Port | Endpoints                                      |
|--------------------|------|------------------------------------------------|
| **customer-service** | 3000 | `/`, `/health`, `/suppliers`                  |
| **employee-service** | 3001 | `/`, `/health`, `/admin/suppliers`            |

Both services expose a root, a health endpoint (JSON), and a domain route. Local and Docker Compose verification are complete before pipeline integration.

---

## 4. CI/CD Workflow

1. **Source** — CodePipeline connects to the repo (e.g. GitHub or CodeCommit), watches a branch (typically `main`), and clones the repository into the build environment on each run.
2. **Build** — CodeBuild executes `cicd/buildspec.yml`: ECR login, Docker build for both services, tag with commit SHA and `latest`, push to ECR, write `build/imagedefinitions.json`.
3. **Artifact** — The build output (including `imagedefinitions.json`) is passed to the deployment stage.
4. **Deploy** — The pipeline uses the artifact and the AppSpec files to create or update ECS task definition revisions and run CodeDeploy; traffic is shifted to the new tasks.

Flow: **Source → Build → Deploy**. No manual steps in the happy path.

---

## 5. Build Stage

The build stage runs on **AWS CodeBuild** and is defined in **`cicd/buildspec.yml`** (version 0.2). It has four phases:

- **Install** — Sets up the environment (Node.js 20, Docker availability check). CodeBuild’s standard image provides Docker.
- **Pre-build** — Derives the image tag from `CODEBUILD_RESOLVED_SOURCE_VERSION` (first 7 characters of the commit SHA), sets the ECR base URI from `AWS_ACCOUNT_ID` and `AWS_DEFAULT_REGION`, and logs in to ECR with `aws ecr get-login-password` piped into `docker login`.
- **Build** — Runs `docker build` for `./services/customer-service` and `./services/employee-service`, tagging each image with the ECR repo name plus `$IMAGE_TAG` and `latest`.
- **Post-build** — Pushes all four tags to ECR (two repos × two tags), then writes `build/imagedefinitions.json` with the two image URIs keyed by service name.

The only artifact is `build/imagedefinitions.json`; it is consumed by the deployment stage to update ECS services.

---

## 6. ECR Image Push Stage

After the build phase, both images are pushed to **Amazon ECR**:

- **Repositories** — `customer-service` and `employee-service` (names are set in the buildspec `env` section).
- **Tags per image** — Commit-based tag (e.g. 7-char SHA) for traceability and deployment; `latest` for convenience. The deployment artifact uses the commit-based tag so ECS pulls a specific digest.
- **Authentication** — IAM only. The CodeBuild role needs `ecr:GetAuthorizationToken` and push permissions on both repositories. No Docker credentials are stored in the pipeline.

The push stage is part of the buildspec’s `post_build` phase; there is no separate pipeline stage for ECR. The result is two ECR repositories each containing the expected tags for the current run.

---

## 7. Deployment Stage

The deployment stage uses the build artifact and the AppSpec files to update **Amazon ECS**:

1. A **new task definition revision** is created (or updated) with the image URIs from `imagedefinitions.json`. Each entry maps a service name (`customer-service`, `employee-service`) to an ECR image URI.
2. **CodeDeploy** runs a deployment for each ECS service. Customer-service uses `cicd/appspec.yaml`; employee-service uses `cicd/appspec-employee.yaml`. Each AppSpec has one TargetService: task definition ARN (injected by the pipeline), container name, and container port for the load balancer.
3. Traffic is shifted from the old tasks to the new ones (blue/green or rolling). The **Application Load Balancer** targets the containers on port 3000 (customer-service) and 3001 (employee-service), as specified in the AppSpecs and in the ECS task definitions.

The pipeline assumes ECS services and ALB target groups already exist; the deploy stage updates the services with the new task revision and shifts traffic accordingly.

---

## 8. Role of buildspec.yml

**`cicd/buildspec.yml`** is the single source of truth for the CodeBuild job. It:

- Defines the build environment (Node.js 20, Docker check).
- Encapsulates ECR login, image naming, tagging, and push for both microservices.
- Produces the deployment artifact `build/imagedefinitions.json` that the deploy stage uses to update ECS task definitions.

Because the buildspec lives in the repo, build behavior is versioned and reviewable. ECR repo names and optional overrides (e.g. image tag) can be set in the buildspec’s `env` or in the CodeBuild project; account and region are typically provided by CodeBuild or the pipeline.

---

## 9. Role of appspec.yaml

**AppSpec** files tell CodeDeploy how to deploy to ECS. CodeDeploy allows only **one TargetService per AppSpec**, so this project uses two files:

- **`cicd/appspec.yaml`** — Customer-service. Specifies the target ECS service, task definition ARN (placeholder filled at deploy time), and `LoadBalancerInfo`: container name `customer-service`, container port **3000**.
- **`cicd/appspec-employee.yaml`** — Employee-service. Same structure: container name `employee-service`, container port **3001**.

The pipeline injects the actual task definition ARN when it creates or selects the new revision from `imagedefinitions.json`. Container names and ports in the AppSpecs must match the ECS task definitions and the ALB target groups so that health checks and routing use the correct ports.

---

## 10. AWS Services Involved

| Service        | Role |
|----------------|------|
| **CodePipeline** | Orchestrates source, build, and deploy stages. |
| **CodeBuild**    | Runs the buildspec; builds and pushes Docker images to ECR. |
| **ECR**          | Stores Docker images for customer-service and employee-service. |
| **ECS**          | Runs the tasks (Fargate or EC2) for both services. |
| **CodeDeploy**   | Performs ECS blue/green (or rolling) deployments using the AppSpecs. |
| **ALB**          | Routes traffic (e.g. `/`, `/suppliers` → customer-service:3000; `/admin/suppliers` → employee-service:3001). |
| **IAM**          | Roles for CodeBuild (ECR push) and CodePipeline/CodeDeploy (ECS, ECR pull). |

VPC, security groups, and optionally Parameter Store or Secrets Manager are used as needed for the environment.

---

## 11. Verification Status

**Local and Docker (completed):**

- customer-service runs on port 3000; endpoints `/`, `/health`, `/suppliers` verified.
- employee-service runs on port 3001; endpoints `/`, `/health`, `/admin/suppliers` verified.
- Docker Compose builds and runs both services; endpoint behavior matches local runs.

**Pipeline (when wired):**

- CodeBuild should complete without error; both images should appear in ECR with the expected tags.
- `imagedefinitions.json` should contain the correct ECR URIs and service names.
- With the deploy stage configured, ECS services should update to the new task revision and traffic should shift; ALB URLs for the above paths should behave like local and Docker.

See `docs/FINAL-VERIFICATION.md` for detailed verification notes and the port conflict (3001) resolution.

---

## 12. Reconstruction Notes and Assumptions

The pipeline was reconstructed from:

- Phase folders (e.g. phase-5 ECR, phase-6 ECS/ALB, phase-7/8 deployment and pipeline) describing the original lab.
- Repository layout (`services/`, `cicd/`, `infrastructure/`) and existing buildspec/appspec placeholders.
- Verified local and Docker Compose behavior (ports, health endpoints, routes).

Assumptions:

- Two ECR repositories (`customer-service`, `employee-service`) exist in the same account/region as the pipeline.
- CodeBuild runs in an environment where Docker is available (e.g. standard image).
- ECS task definitions use container names `customer-service` and `employee-service` and expose ports 3000 and 3001.
- The pipeline is triggered from a single branch (e.g. `main`); image tag is derived from the commit SHA unless overridden.
- One AppSpec per ECS service; task definition ARNs are supplied at deploy time (e.g. from a “Create Task Definition” or equivalent step).

---

## 13. Future Improvements

- **Parameter Store / Secrets Manager** — Move ECR repo names, account ID, or image tag overrides into parameters for multi-account or multi-environment use.
- **Tests in build** — Run unit or integration tests (e.g. `npm test`) in the build phase and fail the build on failure.
- **Deploy automation** — Add the CodePipeline deploy actions (ECS + CodeDeploy) and optional approval for production.
- **Task definition generation** — Generate or update ECS task definition JSON in the build from a template using `imagedefinitions.json`.
- **Notifications** — SNS or Slack on build/deploy success or failure.
- **Environment-specific buildspec** — Buildspec variants or env vars for dev/staging/production (e.g. different ECR repos or tags).

These keep the same design: build once, tag and push to ECR, deploy via artifact and AppSpec.
