# AWS Deployment Guide

## 1. Overview

This document describes how the **aws-microservices-ci-cd-pipeline** project is designed to deploy to AWS. The project demonstrates deployment concepts using ECR (container registry), ECS (container runtime), ALB (routing), and CI/CD (CodeBuild, CodePipeline, CodeDeploy). The repository was reconstructed from lab traces and a verified local implementation; this guide reflects the intended deployment flow and the handoffs between services, without overclaiming what has been run in a live AWS account.

---

## 2. AWS Services Used

| Service | Role in this project |
|---------|------------------------|
| **ECR** | Stores Docker images for customer-service and employee-service. |
| **ECS** | Runs the two containerized services (Fargate or EC2). |
| **ALB** | Single entry point; path-based routing to the correct ECS service. |
| **CodeBuild** | Builds both images from source and pushes to ECR; produces deployment artifact. |
| **CodePipeline** | Orchestrates source, build, and deploy stages. |
| **CodeDeploy** | Performs ECS deployments (blue/green or rolling) using AppSpec files. |
| **IAM** | Roles for CodeBuild (ECR push), CodePipeline, and CodeDeploy (ECS, ECR). |
| **VPC / Security groups** | Network and access control for ECS tasks and ALB. |

Other services (e.g. Parameter Store, CloudWatch) may be used for configuration or observability but are not required for the core deployment flow described here.

---

## 3. Deployment Flow

1. **Source** — CodePipeline pulls the application code from the connected repository (e.g. GitHub or CodeCommit).
2. **Build** — CodeBuild runs `cicd/buildspec.yml`: logs in to ECR, builds customer-service and employee-service Docker images, tags them (commit SHA and `latest`), pushes to ECR, and writes `build/imagedefinitions.json`.
3. **Artifact** — The build output (including `imagedefinitions.json`) is passed to the deployment stage.
4. **Deploy** — The pipeline creates or updates ECS task definition revisions using the image URIs from the artifact, then CodeDeploy runs per ECS service using the AppSpecs. Traffic is shifted to the new tasks according to the deployment configuration.

End-to-end: **Source → Build → Deploy**. Each run is tied to a specific source revision.

---

## 4. Container Image Flow

- **Build** — CodeBuild builds two images from `services/customer-service` and `services/employee-service` using the Dockerfiles in those directories. Each image is tagged with the ECR repository name plus a commit-based tag (e.g. 7-char SHA) and `latest`.
- **Push** — Both tags per image are pushed to the corresponding ECR repository (`customer-service`, `employee-service`). Authentication uses IAM (`aws ecr get-login-password` + `docker login`); no long-lived credentials are stored.
- **Consumption** — The deployment artifact (`imagedefinitions.json`) lists the commit-based image URIs by service name. The deploy stage uses these URIs when creating or updating ECS task definitions so that ECS pulls the exact images produced by that build.

Images are built once per pipeline run and stored in ECR; the same image URIs are used for the ECS task definition update and subsequent deployment.

---

## 5. ECS Deployment Model

- **Two ECS services** — One for customer-service, one for employee-service. Each service runs tasks from a task definition that specifies the container image (from ECR), container name (`customer-service` or `employee-service`), and container port (3000 or 3001).
- **Task definitions** — Container names and ports must match the AppSpecs and ALB target groups: customer-service on 3000, employee-service on 3001. The pipeline injects the new image URI (from `imagedefinitions.json`) when creating a new task definition revision.
- **CodeDeploy** — Each ECS service is deployed via CodeDeploy using a separate AppSpec (`appspec.yaml` for customer-service, `appspec-employee.yaml` for employee-service). Each AppSpec has one TargetService: task definition and LoadBalancerInfo (container name and port). CodeDeploy shifts traffic from the old task set to the new one (blue/green or rolling).

The pipeline assumes ECS cluster, services, and task definitions (or a mechanism to create them) exist; the deploy stage updates the services with the new revision and performs the traffic shift.

---

## 6. Load Balancer Routing Concept

- **Single ALB** — One Application Load Balancer receives external traffic. Listener rules route by path to the appropriate target group.
- **Routing** — `/` and `/suppliers` → target group for customer-service (port 3000). `/admin/suppliers` → target group for employee-service (port 3001). Health checks use `/health` on each service.
- **Target groups** — Each target group is associated with an ECS service. Tasks register with the target group on the container port specified in the task definition and AppSpec (3000 or 3001). The ALB forwards requests to healthy targets in the chosen group.

Path-based routing is done at the ALB; no API Gateway is required for this design.

---

## 7. CI/CD Handoff

- **Build → Deploy** — The only artifact passed from build to deploy is `build/imagedefinitions.json`, which contains the ECR image URI for each service name. No separate “deploy package” is produced; the deploy stage uses these URIs to create or select the new ECS task definition revision(s) and then invokes CodeDeploy with the appropriate AppSpec.
- **AppSpecs** — Task definition ARNs in the AppSpecs are placeholders; the pipeline (or a preceding step) injects the actual ARN when running the deployment. Container names and ports in the AppSpecs (customer-service:3000, employee-service:3001) must match the task definitions and target groups so that health checks and routing work correctly.

The pipeline does not provision ECR repos, ECS cluster, ALB, or target groups; it assumes they exist and updates ECS services with new task revisions and image URIs.

---

## 8. Assumptions and Notes

- ECR repositories `customer-service` and `employee-service` exist in the same account and region as the pipeline.
- ECS cluster, two ECS services, task definitions (with correct container names and ports), ALB, and target groups are created outside the pipeline or by separate automation.
- CodeBuild runs in an environment where Docker is available (e.g. CodeBuild standard image) and has IAM permissions to push to ECR.
- CodePipeline and CodeDeploy have the permissions needed to update ECS services and to read from ECR as required.
- Source is a single branch (e.g. `main`); image tag is derived from the commit SHA unless overridden via environment or Parameter Store.
- VPC and security groups are configured so that the ALB can reach ECS tasks on the expected ports and that tasks can pull images from ECR.

---

## 9. Limitations of Reconstructed Environment

- **No live AWS run guarantee** — The buildspec, AppSpecs, and docs were reconstructed from lab phases and repo layout; they have not necessarily been executed end-to-end in an AWS account in this exact form. Wiring CodePipeline to a repo and running a full build and deploy may require environment-specific adjustments (e.g. account ID, region, resource names, IAM).
- **Infrastructure not in repo** — ECR repos, ECS cluster, services, task definitions, ALB, target groups, and listener rules are not defined in this repository. They must be created separately (console, CloudFormation, Terraform, or similar) before the pipeline can deploy successfully.
- **Single-region, single-account** — The design assumes one region and one account. Multi-region or multi-account deployment would require additional configuration and possibly different artifact or parameter handling.
- **Minimal task definition content** — The repo’s `infrastructure/ecs/` task definition files are placeholders (e.g. empty or minimal containerDefinitions). A full deployment requires complete task definitions (image, CPU/memory, logging, etc.) aligned with the AppSpecs and target groups.

These limitations are noted so that the document remains credible and useful for understanding the intended flow without implying a turnkey production deployment.

---

## 10. Future Improvements

- **Infrastructure as Code** — Add CloudFormation or Terraform (or similar) to define ECR repos, ECS cluster, services, task definitions, ALB, and target groups so that the full stack is reproducible.
- **Pipeline creation as Code** — Define CodePipeline, CodeBuild project, and CodeDeploy application in code so that the CI/CD pipeline itself is versioned and repeatable.
- **Environment parity** — Use Parameter Store or similar for environment-specific values (account, region, repo names) to support dev/staging/production with the same pipeline logic.
- **Deploy validation** — Add a post-deploy step (e.g. hit ALB health or smoke-test URLs) to verify that the new tasks are serving traffic correctly.
- **Rollback** — Document or automate rollback (e.g. previous task definition revision) if a deployment fails or is found to be faulty.

These improvements would build on the current design (build → ECR → ECS + CodeDeploy, path-based ALB routing) without changing the core deployment flow.
