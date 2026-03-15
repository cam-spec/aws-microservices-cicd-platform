# Local Development Guide

## 1. Overview

This guide covers running the **aws-microservices-ci-cd-pipeline** services on a local development machine. The project has two Node.js microservices: **customer-service** (port 3000) and **employee-service** (port 3001). You can run them with Node.js directly or with Docker Compose. The documented environment is Windows with PowerShell, Node.js, Docker, and Docker Compose; the same steps apply on other platforms with minor command adjustments.

---

## 2. Prerequisites

- **Node.js** — Version 18 or 20 recommended (LTS). Used when running services without Docker.
- **npm** — Ships with Node.js. Used to install dependencies and run `npm start`.
- **Docker** — Required for Docker Compose. Ensure the Docker daemon is running.
- **Docker Compose** — v2 (e.g. `docker compose`) or compatible. Used to run both services in containers.
- **Git** — To clone the repository.

On Windows, install Node.js from [nodejs.org](https://nodejs.org) and Docker Desktop (or equivalent) so that `docker` and `docker compose` are available in PowerShell.

---

## 3. Repo Structure

```
aws-microservices-ci-cd-pipeline/
├── services/
│   ├── customer-service/    # Port 3000
│   │   ├── index.js
│   │   ├── package.json
│   │   └── Dockerfile
│   └── employee-service/    # Port 3001
│       ├── index.js
│       ├── package.json
│       └── Dockerfile
├── docker-compose.yml
├── cicd/
└── docs/
```

Each service has its own `package.json`, `index.js`, and `Dockerfile`. The repo root contains `docker-compose.yml` for running both services with Docker.

---

## 4. Running Services Locally with Node

Run each service in a separate terminal so both can listen on their ports.

**Terminal 1 — customer-service (port 3000):**

```powershell
cd services/customer-service
npm install
npm start
```

**Terminal 2 — employee-service (port 3001):**

```powershell
cd services/employee-service
npm install
npm start
```

Each service binds to its default port (3000 or 3001). Port can be overridden with the `PORT` environment variable (e.g. `$env:PORT=3002; npm start` in PowerShell). Leave both terminals running while you verify endpoints.

---

## 5. Running Services with Docker Compose

From the **repository root**:

```powershell
docker compose up --build -d
```

- **`--build`** — Builds images from the Dockerfiles in `services/customer-service` and `services/employee-service`.
- **`-d`** — Runs containers in the background.

Containers:

- **customer-container** — customer-service, host port 3000 → container port 3000.
- **employee-container** — employee-service, host port 3001 → container port 3001.

To view logs:

```powershell
docker compose logs -f
```

To stop and remove containers:

```powershell
docker compose down
```

---

## 6. Endpoint Verification

Once either local Node or Docker Compose is running, use a browser or `Invoke-WebRequest` (PowerShell) to verify.

### customer-service (port 3000)

| Endpoint     | URL                        | Expected |
|-------------|----------------------------|----------|
| Root        | http://localhost:3000/     | Service identification message |
| Health      | http://localhost:3000/health | JSON: `{ "status": "ok", "service": "customer-service" }` |
| Suppliers   | http://localhost:3000/suppliers | Supplier list or placeholder |

### employee-service (port 3001)

| Endpoint           | URL                              | Expected |
|--------------------|----------------------------------|----------|
| Root               | http://localhost:3001/           | Service identification message |
| Health             | http://localhost:3001/health     | JSON: `{ "status": "ok", "service": "employee-service" }` |
| Admin suppliers    | http://localhost:3001/admin/suppliers | Admin supplier management response |

**PowerShell examples:**

```powershell
Invoke-WebRequest -Uri http://localhost:3000/health -UseBasicParsing | Select-Object -ExpandProperty Content
Invoke-WebRequest -Uri http://localhost:3001/health -UseBasicParsing | Select-Object -ExpandProperty Content
```

---

## 7. Troubleshooting

- **Port already in use** — Another process is bound to 3000 or 3001. Stop that process or change the service port (e.g. `PORT` env var for Node; for Docker Compose, change the host port in `docker-compose.yml` or free the port). See **Known issue** below for the 3001 conflict encountered during verification.
- **Docker build fails** — Ensure Docker is running and you have enough disk space. Run from the repo root so that `./services/customer-service` and `./services/employee-service` resolve correctly.
- **npm install fails** — Use a supported Node version (18 or 20 LTS). Delete `node_modules` and run `npm install` again in the service directory.
- **Connection refused** — Confirm the service is running and listening on the expected port (3000 or 3001). On Windows, check with `netstat -an | findstr "3000 3001"` or use Task Manager / Resource Monitor to see what is using the port.

---

## 8. Known Issue Encountered (Port Conflict on 3001)

During verification, **employee-service** failed to start under Docker Compose on the first run.

**Cause:** A local Node process (e.g. a previously started employee-service) was already listening on port **3001**. Docker Compose maps container port 3001 to host port 3001, so the host port must be free.

**Fix:** Stop the process using port 3001 (e.g. close the terminal running `npm start` for employee-service, or stop the process via Task Manager). Then run `docker compose up --build -d` again. Both containers should start and endpoints should respond as expected.

See `docs/FINAL-VERIFICATION.md` for full verification notes and resolution.

---

## 9. Development Notes

- **Ports** — Services use `process.env.PORT || 3000` (customer) and `process.env.PORT || 3001` (employee) so defaults match the documented ports; override with `PORT` when needed.
- **Single repo** — Both services live in one repository; CI/CD builds both images from the same clone. Keep `package.json` and Dockerfiles in each service directory so local and Docker behavior stay aligned.
- **No shared database** — The current setup does not include a database; services are stateless for local dev. Add connection config and run a DB separately if required.
- **Hot reload** — Running with `node index.js` or `npm start` does not auto-reload on file changes. Restart the process after code changes, or use a tool like `nodemon` in the service directory for development if desired.
