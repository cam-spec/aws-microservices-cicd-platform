# Phase 6 — Load Balancer and Target Group Configuration

In this phase the infrastructure required to route traffic to the microservices was created.

An **Application Load Balancer (ALB)** was configured to act as the main entry point for users accessing the application.

Target groups were created to manage how traffic is distributed to the running containers.

The following actions were performed:

- Created target groups for the customer and employee services
- Configured health checks to monitor container availability
- Created an Application Load Balancer within the VPC
- Configured listeners and routing rules

The load balancer ensures that incoming requests are routed to the correct microservice and allows the system to scale in the future.

## Tasks Completed

- Task 6.1 — Create target groups
- Task 6.2 — Create Application Load Balancer

By the end of this phase the AWS networking layer required to expose the microservices had been successfully configured.
