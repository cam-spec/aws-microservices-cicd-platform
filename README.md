# AWS Microservices CI/CD Pipeline

## Overview
This project rebuilds an AWS microservices and CI/CD lab using a cleaner production-style structure. The repository also documents the project built in phases; each phase folder contains notes, decisions, and artefacts (diagrams, configuration, scripts) produced during implementation.

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
- employee-service on port 4000

## Docker Compose
Start both services with:

```
docker compose up --build -d
```

## Routes
- http://localhost:3000
- http://localhost:3000/suppliers
- http://localhost:4000
- http://localhost:4000/admin/suppliers

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
