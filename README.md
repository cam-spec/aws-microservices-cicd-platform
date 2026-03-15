# AWS Microservices CI/CD Pipeline

## Overview

This is a **Node.js microservices** project with two services:

- **customer-service** runs on port **3000** (public supplier views and APIs).
- **employee-service** runs on port **3001** (admin supplier management).

The stack includes **Docker**, **Docker Compose**, and AWS: **ECS**, **ECR**, **CodeBuild**, **CodeDeploy**, and **CodePipeline** for container build and deployment.

Local helper scripts (PowerShell) are provided:

- `scripts/run-local.ps1` — build and start both services with Docker Compose
- `scripts/smoke-test.ps1` — hit all six endpoints and report PASS/FAIL
- `scripts/stop-local.ps1` — stop containers (`docker compose down`)

## Quick Start

From the repository root (Windows/PowerShell):

```powershell
# Start both services (build and run in background)
docker compose up --build -d

# Or use the helper script (same as above, then prints URLs)
.\scripts\run-local.ps1

# Verify all endpoints
.\scripts\smoke-test.ps1

# Stop services
.\scripts\stop-local.ps1
```

## Architecture Summary

The system follows a container-based microservices deployment model:

```
Client
   │
   ▼
Application Load Balancer
   │
   ├── customer-service (ECS task, port 3000)
   │
   └── employee-service (ECS task, port 3001)
```

CodePipeline orchestrates the CI/CD workflow:
**Source → CodeBuild → ECR → ECS deployment via CodeDeploy.**

Images are built from the services directories and stored in Amazon ECR.
ECS services pull images from ECR during deployments and register with the ALB target groups.

See `docs/ARCHITECTURE.md` for the full system diagram.

## Structure
- phase-1-architecture/ — Architecture diagrams and design decisions (Phase 1.1, 1.2, etc.)
- phase-2-monolith-analysis/ — Analysis + testing notes for the monolithic application
- phase-3-cloud9-setup/ — Cloud9 setup + source control actions (e.g., CodeCommit)
- phase-4-microservices/ — Microservices build-out and supporting infrastructure
- phase-5-ecr-deployment/ — ECR repositories and image push
- phase-6-ecs-cluster/ / phase-6-load-balancer/ — ECS and ALB
- phase-7-cicd-preparation/ / phase-7-ecs-deployment/ — ECS and deployment setup
- phase-8-cicd-pipeline/ — CI/CD pipeline
- phase-9-final-verification/ — Final verification

## Services
- customer-service
- employee-service

## Local Architecture
The application is split into two Node.js microservices:
- customer-service on port 3000
- employee-service on port 3001

## Docker Compose
Start both services with:

```
docker compose up --build -d
```

## Routes
- http://localhost:3000 — customer-service root
- http://localhost:3000/health — customer-service health
- http://localhost:3000/suppliers — customer-service suppliers
- http://localhost:3001 — employee-service root
- http://localhost:3001/health — employee-service health
- http://localhost:3001/admin/suppliers — employee-service admin suppliers

## Current Progress
- Microservices rebuilt locally
- Dockerfiles created
- Docker Compose configured
- Both services running successfully in containers

## Planned AWS Next Steps
- Add ECS task definitions
- Add ECR notes
- Add ALB routing notes
- Add CI/CD deployment structure
