# Phase 2 — Monolith Analysis

This phase analyzes the existing monolithic Coffee Suppliers application before decomposing it into microservices.

The purpose of this phase is to understand:

* How the application is accessed
* How users interact with it
* Which URL routes map to application functionality

These findings directly inform microservice boundaries in later phases.



\# Phase 2 – Monolithic Application Analysis



This phase analyzes the runtime behavior, infrastructure, and data flow of a monolithic Node.js application deployed on AWS.  

The goal is to fully understand the monolith before decomposing it into microservices in later phases.



---



\## Architecture Overview



\- \*\*Compute\*\*: Amazon EC2 (Ubuntu 20.04)

\- \*\*Application\*\*: Node.js (Express-style monolith)

\- \*\*Port\*\*: HTTP on port 80

\- \*\*Database\*\*: Amazon RDS (MySQL)

\- \*\*Data Store\*\*: `COFFEE.suppliers` table



---



\## Task 2.1 – Verify Monolithic Application Availability



The application was accessed using the EC2 public IPv4 address over HTTP.



\- The coffee suppliers web UI loaded successfully

\- Browser warning about HTTPS was expected and ignored (no TLS configured)



📸 Evidence stored in:







---



\## Task 2.2 – Test Monolithic Web Application



The application UI was tested to understand routing and data persistence.



Observed URL paths:

\- `/suppliers` – list suppliers

\- `/supplier-add` – add supplier

\- `/supplier-update/{id}` – edit supplier



Actions performed:

\- Added a supplier via the UI

\- Edited an existing supplier

\- Verified changes persisted



📸 Evidence stored in:







---



\## Task 2.3 – Analyze How the Monolithic Application Runs



\### Runtime Analysis



Commands executed on EC2:

```bash

sudo lsof -i :80

ps aux | grep node





Evidence: task-2.3-analyze-runtime/phase-2.3-proof-1.png



