# Phase 5 — Amazon ECR Image Deployment

In this phase the container images for the microservices were prepared and uploaded to **Amazon Elastic Container Registry (ECR)**.

After splitting the application into two services in Phase 4, each service needed its own container image so that it could later be deployed inside AWS infrastructure.

The following steps were completed:

- Created ECR repositories for each microservice
- Tagged the local Docker images with the ECR repository URI
- Authenticated Docker with AWS ECR
- Pushed the container images from the local environment to the AWS registry

Uploading the images to ECR allowed AWS services such as ECS to pull the containers directly from the registry during deployment.

## Tasks Completed

- Task 5.1 — Create ECR repositories
- Task 5.2 — Tag container images
- Task 5.3 — Push images to ECR

At the end of this phase the customer and employee microservice container images were successfully stored in Amazon ECR and ready for deployment.
