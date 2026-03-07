# Phase 4 — Microservices Refactoring

This phase focused on splitting the Coffee Suppliers monolithic application into two independent services.

The monolith originally handled both public supplier pages and admin management features in the same codebase. To prepare for container deployment and CI/CD, the application was separated based on responsibility.

The application was divided into:

- **Customer microservice** – handles public supplier viewing pages
- **Employee microservice** – handles supplier management and admin features

This separation allowed each service to run independently and prepared the application for containerisation in the next phase.

## Tasks Completed

- Task 4.1 — Identify service boundaries
- Task 4.2 — Create the customer microservice
- Task 4.3 — Create the employee microservice
- Task 4.4 — Update routing and navigation

By the end of this phase the application had been successfully separated into two services ready for Docker containerisation and AWS deployment.
