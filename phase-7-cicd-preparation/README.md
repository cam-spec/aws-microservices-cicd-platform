# Phase 7 — ECS Cluster Preparation

This phase prepared the environment required to run the containerised microservices inside **Amazon Elastic Container Service (ECS)**.

An ECS cluster acts as the compute environment that will run the Docker containers pulled from Amazon ECR.

The following steps were completed:

- Created an ECS cluster
- Defined task definitions for the customer and employee services
- Configured container settings and resource allocation
- Prepared deployment configuration files

Task definitions specify how containers should run, including the container image, CPU and memory allocation, networking configuration, and port mappings.

## Tasks Completed

- Task 7.1 — Create ECS cluster and task definitions
- Task 7.2 — Create deployment configuration files

At the end of this phase the ECS environment was ready to deploy the microservices containers from Amazon ECR.
