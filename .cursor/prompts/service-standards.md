All Node.js microservices in this repository must follow these standards:

Structure:
- index.js
- package.json
- Dockerfile

Endpoints:
GET /
GET /health
GET /resource

Ports:
customer-service → 3000
employee-service → 3001

Health endpoint example:

GET /health
returns:
{
  status: "ok",
  service: "service-name"
}

Logging:
Each service must log startup messages.

Environment ports must use:

const PORT = process.env.PORT || DEFAULT_PORT

Docker containers must expose the correct port.

Services should use Express and clean JSON responses.

Maintain consistency across both services.