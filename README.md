# AWS Microservices CI/CD Pipeline

## Overview
This project rebuilds an AWS microservices and CI/CD lab using a cleaner production-style structure.

## Services
- customer-service
- employee-service

## Local Architecture
The application is split into two Node.js microservices:
- customer-service on port 3000
- employee-service on port 4000

## Docker Compose
Start both services with:

docker compose up --build -d

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
