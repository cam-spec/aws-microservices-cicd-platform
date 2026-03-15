# Final Verification

## 1. Verification Objective

Confirm that both Node.js microservices (customer-service and employee-service) run correctly locally and under Docker Compose, that all required endpoints respond as designed, and that the local setup is validated and ready to move into ECR, ECS, and pipeline integration work.

---

## 2. Local Service Verification

- **customer-service** — Started with `npm start` (or `node index.js`), bound to port **3000**. Root, health, and domain endpoints exercised; no failures.
- **employee-service** — Started with `npm start` (or `node index.js`), bound to port **3001**. Root, health, and domain endpoints exercised; no failures.

---

## 3. Endpoint Checklist

### customer-service (port 3000)

| Endpoint     | Method | Result |
|-------------|--------|--------|
| `/`         | GET    | Pass   |
| `/health`   | GET    | Pass   |
| `/suppliers`| GET    | Pass   |

### employee-service (port 3001)

| Endpoint           | Method | Result |
|--------------------|--------|--------|
| `/`                | GET    | Pass   |
| `/health`          | GET    | Pass   |
| `/admin/suppliers` | GET    | Pass   |

All endpoints returned the expected responses during local and container-based verification.

---

## 4. Docker Compose Verification

From the repository root, the following command was run:

```bash
docker compose up --build -d
```

**Outcome:** Both images built successfully; both containers started and remained reachable. **customer-service** was built from `services/customer-service` with container port 3000 mapped to host 3000. **employee-service** was built from `services/employee-service` with container port 3001 mapped to host 3001. The same endpoints were exercised against the running containers at `http://localhost:3000` and `http://localhost:3001`; responses matched the local (non-container) verification. Containers were stopped with `docker compose down`; no errors were reported.

---

## 5. Issue Encountered

On the first run of Docker Compose, **employee-service** did not start or bind correctly.

---

## 6. Root Cause

A local Node process was already listening on port **3001**. Docker Compose maps the employee-service container port 3001 to host port 3001; the host port must be free. The conflict prevented the container from binding.

---

## 7. Resolution

1. Identified and stopped the process using port 3001 on the host.
2. Re-ran `docker compose up --build -d`. Both images built and both containers started.
3. Re-ran endpoint tests against the containers; results matched local verification.

---

## 8. Final Status

| Component               | Status | Notes |
|-------------------------|--------|--------|
| customer-service (local)| Pass   | Port 3000; `/`, `/health`, `/suppliers` verified. |
| employee-service (local)| Pass   | Port 3001; `/`, `/health`, `/admin/suppliers` verified. |
| Docker builds           | Pass   | Both Dockerfiles build without error. |
| Docker Compose          | Pass   | Both containers run after resolving port 3001 conflict. |
| Endpoint parity         | Pass   | Container behavior matches local behavior. |

Local and container verification is complete. The project is ready to proceed to ECR publishing, ECS task definition alignment, and CI/CD integration.

---

## 9. Evidence Captured

- Endpoint responses for both services (root, health, domain routes).
- Docker Compose build and run logs (successful build and start of both containers).
- Confirmation that releasing port 3001 resolved the conflict.

Screenshots or log excerpts can be added here for portfolio or audit use.

---

## 10. Next Phase

1. **ECR** — Create repositories; push images (or run CodeBuild buildspec) to validate ECR.
2. **ECS** — Finalize task definitions (container names and ports aligned with `cicd/appspec-customer.yaml` and `cicd/appspec-employee.yaml`); run services on ECS.
3. **ALB** — Configure listener rules: `/` and `/suppliers` → customer-service:3000; `/admin/suppliers` → employee-service:3001.
4. **Pipeline** — Connect CodePipeline to the repo; run build and deploy to confirm end-to-end CI/CD.

See `docs/CICD-PIPELINE.md` and `README.md` for pipeline design and project status.
