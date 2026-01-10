# Phase 1 — Architecture

## Phase 1.1 — AWS Microservices Architecture (High-Level)

**Objective:** Produce a high-level architecture diagram showing the core AWS services, deployment flow, and network placement for a containerised microservices solution.

### Summary of the design
Resources are placed within an **Amazon VPC (CIDR: 10.0.0.0/16)** to provide network isolation and controlled connectivity. The application is deployed across **two Availability Zones** (AZ-1 and AZ-2) to improve availability.

An **Application Load Balancer (ALB)** routes inbound traffic to containerised microservices running on **Amazon ECS** in both AZs. Persistent data is stored in **Amazon RDS (MySQL)**.

A CI/CD path is represented using:
- **CodeCommit** (source repository)
- **CodePipeline** (pipeline orchestration)
- **CodeDeploy** (deployment automation)
- **ECR** (container image repository used by ECS)

### Diagram
diagrams/phase-1.1-high-level-architecture.png

