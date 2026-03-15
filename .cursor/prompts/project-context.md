You are assisting with the reconstruction of a flagship DevOps and cloud engineering portfolio project.

The project is an AWS microservices CI/CD pipeline implementation.

The repository contains phase folders that describe the full architecture and deployment workflow:

phase-1-architecture
phase-2-monolith-analysis
phase-3-cloud9-setup
phase-4-microservices
phase-5-ecr-deployment
phase-6-ecs-cluster
phase-6-load-balancer
phase-7-cicd-preparation
phase-7-ecs-deployment
phase-8-cicd-pipeline
phase-9-final-verification

The goal is to reconstruct the entire project locally and convert it into a professional DevOps portfolio project.

The project must demonstrate:

- Node.js microservices
- Docker containerization
- AWS ECS architecture
- AWS ECR container registry
- Application Load Balancer routing
- CI/CD pipeline automation

Two services exist:

customer-service
employee-service

Both services must:

- expose a root endpoint
- expose a health endpoint
- expose a domain endpoint
- support environment ports
- run locally
- run inside Docker

The repository must also include:

- buildspec.yml
- appspec.yaml
- Dockerfiles
- docker-compose.yml

Documentation must be senior-level and production quality.

Always follow clean engineering practices and maintain consistent structure across both services.