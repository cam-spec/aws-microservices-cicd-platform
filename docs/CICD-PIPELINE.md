# CI/CD Pipeline

## Overview

This document describes the continuous integration and deployment pipeline for the **aws-microservices-ci-cd-pipeline** project. The pipeline builds two Node.js microservices (customer-service on port 3000, employee-service on port 3001), containerizes them with Docker, pushes images to Amazon ECR, and deploys to ECS using CodeDeploy. It is designed for use with AWS CodePipeline and CodeBuild and is suitable for portfolio or lab-style deployments.

---

## Source Repository

The pipeline is triggered from a single source repository (e.g. **GitHub** or AWS CodeCommit). CodePipeline connects to the repo and watches a branch (typically `main`). On each commit (or manual run), the pipeline:

- Clones the full repository into the build environment.
- Uses the commit SHA to tag Docker images for traceability.
- Ensures every build and deployment is tied to a specific revision.

The repository layout expected by the pipeline:

- `services/customer-service/` — Dockerfile and application code for customer-service.
- `services/employee-service/` — Dockerfile and application code for employee-service.
- `cicd/buildspec.yml` — CodeBuild build specification.
- `cicd/appspec.yaml` and `cicd/appspec-employee.yaml` — CodeDeploy AppSpec files for ECS.

---

## Build Stage

The build stage runs on **AWS CodeBuild** and is fully defined by `cicd/buildspec.yml` (version 0.2). It has four phases:

1. **Install** — Configures the environment (Node.js 20, Docker). CodeBuild’s standard image provides Docker.
2. **Pre-build** — Sets the image tag (short commit SHA from `CODEBUILD_RESOLVED_SOURCE_VERSION`), authenticates to Amazon ECR, and sets the ECR base URI from account ID and region.
3. **Build** — Builds both Docker images (see below).
4. **Post-build** — Pushes images to ECR and writes the deployment artifact `build/imagedefinitions.json`.

The build stage produces a single artifact, `imagedefinitions.json`, which is passed to the deployment stage. No manual steps are required in the happy path.

---

## Docker Image Creation

During the **build** phase, CodeBuild runs `docker build` twice:

- **customer-service** — Built from `./services/customer-service` using the Dockerfile in that directory. The image is tagged with the ECR repository name, plus two tags: a commit-based tag (e.g. first 7 characters of the commit SHA) and `latest`.
- **employee-service** — Built from `./services/employee-service` with the same tagging strategy.

Each image is built from the same repo clone, so both images correspond to the same source revision. The commit-based tag is what the deployment artifact and ECS use for a specific, reproducible deploy.

---

## ECR Push

After the images are built, the **post_build** phase pushes them to **Amazon ECR**:

- Two ECR repositories are used: `customer-service` and `employee-service` (names are configurable via buildspec env vars).
- Each image is pushed with two tags: the commit-based tag and `latest`.
- Authentication to ECR uses IAM: `aws ecr get-login-password` is piped into `docker login`. The CodeBuild role must have `ecr:GetAuthorizationToken` and push permissions on both repositories.

No long-lived Docker credentials are stored; everything is IAM-based. The deployment artifact references the commit-based image URIs so that ECS pulls the exact images produced by this build.

---

## ECS Deployment

The deployment stage consumes the build artifact and the AppSpec files to update **Amazon ECS** services:

1. A **new task definition revision** is created (or updated) with the image URIs from `imagedefinitions.json`. Each entry in that file maps a service name (e.g. `customer-service`) to an ECR image URI.
2. **CodeDeploy** runs a deployment for each ECS service. Each deployment uses the corresponding AppSpec file (`appspec.yaml` for customer-service, `appspec-employee.yaml` for employee-service). The AppSpec specifies the target ECS service, the task definition to deploy, and the container name and port for the load balancer.
3. Traffic is shifted from the old tasks to the new ones according to the deployment configuration (blue/green or rolling). The **Application Load Balancer** targets the containers on the correct ports: 3000 for customer-service, 3001 for employee-service, as defined in the AppSpecs and in the ECS task definitions.

The pipeline assumes ECS services and target groups already exist; the deploy stage updates the services with the new task revision and shifts traffic.

---

## Role of buildspec.yml

**`cicd/buildspec.yml`** is the single source of truth for the CodeBuild job. It:

- Defines the build environment (Node version, optional Docker checks).
- Drives ECR login, Docker build, tagging, and push for both microservices.
- Produces the deployment artifact `build/imagedefinitions.json`, which lists the image URIs by service name for the deploy stage.

Because the buildspec lives in the repository, build behavior is versioned and consistent. Changes to how images are built or tagged go through normal code review. Required inputs (e.g. ECR repo names, or image tag override) can be set in the buildspec’s `env` section or in the CodeBuild project environment; account and region are typically provided by CodeBuild or the pipeline.

---

## Role of appspec.yaml

**AppSpec** files tell CodeDeploy how to deploy to ECS. This project uses two files, because CodeDeploy allows only **one TargetService per AppSpec**:

- **`cicd/appspec.yaml`** — Used for **customer-service**. It specifies the target ECS service, the task definition ARN (injected by the pipeline at deploy time), and `LoadBalancerInfo`: container name `customer-service`, container port **3000**.
- **`cicd/appspec-employee.yaml`** — Used for **employee-service**. Same structure, with container name `employee-service` and container port **3001**.

The task definition ARN placeholders in the AppSpecs are replaced by the pipeline when it creates or selects the new task definition revision from the build’s `imagedefinitions.json`. The container names and ports in the AppSpecs must match the ECS task definitions and the ALB target groups so that traffic is routed correctly.

---

## Summary

| Stage        | What happens |
|-------------|----------------|
| **Source**  | CodePipeline pulls code from GitHub (or CodeCommit). |
| **Build**   | CodeBuild runs buildspec.yml: ECR login, Docker build for both services, tag with commit SHA and latest, push to ECR, write imagedefinitions.json. |
| **Deploy**  | Pipeline uses imagedefinitions.json and the AppSpecs to create a new ECS task revision and run CodeDeploy; traffic shifts to the new tasks. |

The pipeline is linear: **Source → Build → Deploy**. The buildspec defines the build; the AppSpecs define how each ECS service is deployed and how the load balancer targets the containers (ports 3000 and 3001).
