                           CLIENT
                              │
                              │ HTTP
                              ▼
                    ┌───────────────────┐
                    │   API Gateway     │
                    │      :4004        │
                    └─────────┬─────────┘
                              │
                    ┌─────────┴──────────┐
                    │                    │
                 /auth/**          /api/patients/**
                    │                    │
                    ▼                    ▼
             ┌────────────┐       ┌───────────────┐
             │ Auth       │       │ Patient       │
             │ Service    │       │ Service       │
             │ :4005      │       │ :4000         │
             └────────────┘       └───────┬───────┘
                                          │
                              ┌───────────┴───────────┐
                              │                       │
                             gRPC                   Kafka
                              │                       │
                              ▼                       ▼
                       ┌──────────────┐       ┌─────────────┐
                       │ Billing      │       │ Kafka       │
                       │ Service      │       │ topic       │
                       │ gRPC         │       │ "patient"   │
                       └──────────────┘       └──────┬──────┘
                                                     │
                                                     ▼
                                              ┌─────────────┐
                                              │ Analytics   │
                                              │ Service     │
                                              └─────────────┘






                           Internet
                              │
                              ▼
                    ┌──────────────────┐
                    │       ALB        │
                    └────────┬─────────┘
                             │
                             ▼
                    API Gateway :4004
                             │
                   ┌─────────┴─────────┐
                   │                   │
                   ▼                   ▼
             Auth Service        Patient Service
                :4005                 :4000
                   │                    │
                   ▼                    ├──── gRPC ────► Billing
            RDS PostgreSQL             │                  :9001
           auth-service-db             │
                                        │
                                        ▼
                                    Amazon MSK
                                   topic: patient
                                        │
                                        ▼
                                  Analytics Service



NETWORK
├── VPC
└── 2 AZs

COMPUTE
├── API Gateway service
├── Auth service
├── Patient service
├── Billing service
└── Analytics service

DATABASE
├── RDS PostgreSQL → Auth
└── RDS PostgreSQL → Patient

MESSAGING
└── MSK Kafka
    └── topic: patient

LOAD BALANCING
└── ALB → API Gateway

SERVICE DISCOVERY
└── Cloud Map

LOGGING
└── CloudWatch Logs




 OpenTelemetry instrumentation for all 5 Spring services
 OpenTelemetry Collector
 SigNoz
 Distributed tracing: HTTP, gRPC, Kafka, PostgreSQL
 Centralized application logs/errors
 Service health monitoring
 Kafka metrics + consumer lag
 PostgreSQL metrics
 Host CPU/RAM/disk/network/process metrics
 Project-specific SigNoz dashboards
 Failure/latency testing
 Document the observability setup and verification




 1. Application telemetry

For every Spring Boot service:

API Gateway
Patient Service
Billing Service
Auth Service
Analytics Service

we'll collect:

Metrics

HTTP request count
HTTP response status
request latency
JVM CPU
JVM memory
heap/non-heap
GC activity
thread count
loaded classes
connection pools
database connection usage
Kafka producer/consumer metrics
gRPC metrics where available

Logs

application logs
exceptions
warnings
authentication events
Kafka events
database errors
gRPC errors
startup/shutdown
request correlation

Traces

Gateway → Patient Service
Patient Service → PostgreSQL
Patient Service → Billing via gRPC
Patient Service → Kafka
Kafka → Analytics
Auth validation

This is where OpenTelemetry becomes especially useful.

2. Infrastructure telemetry

I wouldn't stop at Java.

We should also monitor the actual server:

Host
├── CPU
├── RAM
├── Swap
├── Disk usage
├── Disk I/O
├── Network traffic
├── Network errors
├── Load average
├── Processes
├── File descriptors
└── TCP connections

And the infrastructure components:

PostgreSQL
├── connections
├── transactions
├── queries
├── locks
├── database size
├── cache
├── errors
└── replication-related metrics

Kafka:

Kafka
├── broker health
├── messages in/out
├── bytes in/out
├── request latency
├── partitions
├── offsets
├── consumer groups
├── consumer lag
├── under-replicated partitions
└── JVM/broker metrics

For your current single-node Kafka, we'll still monitor those metrics even though replication-related metrics won't be meaningful yet.

3. Health and availability

We'll also have explicit health checks.

For example:

API Gateway       UP
Patient Service   UP
Billing Service   UP
Auth Service      UP
Analytics         UP
PostgreSQL        UP
Kafka             UP

And eventually:

Gateway → Patient       ✓
Patient → PostgreSQL    ✓
Patient → Billing gRPC  ✓
Patient → Kafka         ✓
Kafka → Analytics       ✓
Gateway → Auth          ✓



curl / API Gateway
        │
        │ HTTP :4000
        ▼
┌─────────────────────────┐
│ Patient Service JVM     │
│                         │
│ Spring Boot             │
│   └── Spring MVC        │
│        └── Tomcat       │
│             │           │
│             ▼           │
│        Controller       │
│             │           │
│          Service        │
│             │           │
│        Repository       │
│             │           │
│          PostgreSQL     │
└─────────────────────────┘







# Java Spring Microservices

A Spring Boot microservices application demonstrating service-to-service communication, authentication, PostgreSQL persistence, gRPC, Kafka event streaming, and containerized local deployment with Docker Compose.

The project contains five application services behind a Spring Cloud Gateway:

* API Gateway
* Patient Service
* Billing Service
* Auth Service
* Analytics Service

PostgreSQL and Kafka currently run on the host machine rather than inside Docker.

---

## Architecture

```text
                              ┌──────────────────────┐
                              │      Client          │
                              │ curl / REST client   │
                              └──────────┬───────────┘
                                         │
                                         │ HTTP :4004
                                         ▼
                              ┌──────────────────────┐
                              │    API Gateway       │
                              │ Spring Cloud Gateway │
                              │        :4004         │
                              └───────┬───────┬──────┘
                                      │       │
                         /auth/**     │       │ /api/patients/**
                                      │       │
                                      ▼       ▼
                            ┌────────────┐  ┌─────────────────┐
                            │    Auth    │  │ Patient Service │
                            │  Service   │  │      :4000      │
                            │   :4005    │  └───────┬─────────┘
                            └─────┬──────┘          │
                                  │                 │
                                  │                 │ gRPC :9001
                                  │                 ▼
                                  │        ┌─────────────────┐
                                  │        │ Billing Service │
                                  │        │      :4001      │
                                  │        │ gRPC :9001      │
                                  │        └─────────────────┘
                                  │
                                  │
                                  │          Kafka :9092
                                  │                 │
                                  │                 ▼
                                  │        ┌─────────────────┐
                                  │        │ Analytics       │
                                  │        │ Service :8080   │
                                  │        └─────────────────┘
                                  │
                                  ▼
                         ┌─────────────────┐
                         │ PostgreSQL :5433│
                         │                 │
                         │ auth_service_db │
                         │ patient_service_db
                         └─────────────────┘
```

### Request and event flow

A patient creation request follows this path:

```text
Client
  ↓
API Gateway
  ↓ JWT validation
Patient Service
  ↓
PostgreSQL
  ↓
Billing Service via gRPC
  ↓
Kafka topic: patient
  ↓
Analytics Service
```

---

## Services

| Service           |   Port | Responsibility                                                |
| ----------------- | -----: | ------------------------------------------------------------- |
| API Gateway       | `4004` | Entry point, routing and JWT validation                       |
| Patient Service   | `4000` | Patient CRUD, PostgreSQL, Billing gRPC client, Kafka producer |
| Billing Service   | `4001` | Billing HTTP endpoint and gRPC server                         |
| Billing gRPC      | `9001` | Patient-to-Billing service communication                      |
| Auth Service      | `4005` | Login, JWT generation and validation                          |
| Analytics Service | `8080` | Kafka consumer and patient event processing                   |
| PostgreSQL        | `5433` | Persistent application data                                   |
| Kafka             | `9092` | Event streaming                                               |

---

# Technology Stack

## Application

* Java 21
* Spring Boot
* Spring Cloud Gateway
* Spring Data JPA
* Spring Security
* JWT
* BCrypt
* PostgreSQL
* Apache Kafka
* gRPC
* Protocol Buffers
* Maven

## Infrastructure

* Docker
* Docker Compose
* Linux host
* PostgreSQL running on host
* Kafka running on host

---

# Repository Structure

The project contains the following application services:

```text
microservices-java-spring/
├── api-gateway/
├── patient-service/
├── billing-service/
├── auth-service/
├── analytics-service/
├── home-energy-tracker/
└── docker-compose.yml
```

`home-energy-tracker/` is unrelated to the current microservices workflow.

---

# Service Details

## API Gateway

The API Gateway is a Spring Cloud Gateway application running on port `4004`.

Routes currently include:

```text
/auth/**              → auth-service:4005
/api/patients/**      → patient-service:4000
/api-docs/patients    → patient-service:/v3/api-docs
/api-docs/auth        → auth-service:/v3/api-docs
```

### Authentication

Patient endpoints are protected by a custom JWT validation filter.

Requests must contain:

```http
Authorization: Bearer <JWT>
```

The gateway forwards the token to:

```text
/auth-service:4005/validate
```

If validation succeeds, the request continues to Patient Service.

---

# Auth Service

Auth Service runs on port `4005`.

Current responsibilities:

* User lookup
* BCrypt password verification
* JWT generation
* JWT validation
* PostgreSQL persistence

## Login

```http
POST /auth/login
```

Example:

```bash
curl -X POST http://localhost:4004/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@test.com",
    "password": "password123"
  }'
```

Example response:

```json
{
  "token": "<JWT>"
}
```

## Token validation

```http
GET /auth/validate
```

Example:

```bash
curl -i http://localhost:4004/auth/validate \
  -H "Authorization: Bearer $TOKEN"
```

Expected:

```text
HTTP/1.1 200 OK
```

---

# Patient Service

Patient Service runs on port `4000`.

Responsibilities:

* Patient CRUD
* PostgreSQL persistence
* Billing gRPC client
* Kafka event producer

## API

### Get all patients

```http
GET /api/patients
```

Example:

```bash
curl http://localhost:4004/api/patients \
  -H "Authorization: Bearer $TOKEN"
```

### Create patient

```http
POST /api/patients
```

Example:

```bash
curl -X POST http://localhost:4004/api/patients \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Full E2E Test",
    "email": "full-e2e@example.com",
    "address": "123 Test Street",
    "dateOfBirth": "1995-05-20",
    "registeredDate": "2026-09-28"
  }'
```

### Update patient

```http
PUT /api/patients/{id}
```

Example:

```bash
curl -X PUT http://localhost:4004/api/patients/<PATIENT_ID> \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Full E2E Test Updated",
    "email": "full-e2e@example.com",
    "address": "456 Updated Street",
    "dateOfBirth": "1995-05-20",
    "registeredDate": "2026-09-28"
  }'
```

### Delete patient

```http
DELETE /api/patients/{id}
```

Example:

```bash
curl -i -X DELETE http://localhost:4004/api/patients/<PATIENT_ID> \
  -H "Authorization: Bearer $TOKEN"
```

Expected:

```text
HTTP/1.1 204 No Content
```

---

# Billing Service

Billing Service runs on:

```text
HTTP: 4001
gRPC: 9001
```

The Patient Service communicates with Billing through gRPC.

The current test implementation returns a billing account similar to:

```text
accountId: "12345"
status: "ACTIVE"
```

A successful integration test produced:

```text
Billing Service:
createBillingAccount request received

Patient Service:
Received response from billing service via GRPC:
accountId: "12345"
status: "ACTIVE"
```

---

# Kafka

Kafka runs on the host at:

```text
localhost:9092
```

The application services access the host broker through:

```text
host.docker.internal:9092
```

Linux Docker networking requires:

```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

The primary Kafka topic is:

```text
patient
```

Current topic configuration:

```text
PartitionCount: 1
ReplicationFactor: 1
Leader: 1
Isr: 1
```

Inspect the topic:

```bash
/opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --describe \
  --topic patient
```

---

# Patient Event Flow

When a patient is created:

1. Patient Service stores the patient.
2. Patient Service calls Billing Service using gRPC.
3. Billing returns the billing account information.
4. Patient Service publishes a patient event to Kafka.
5. Analytics Service consumes the event.

Example Analytics log:

```text
Received Patient Event:
[PatientId=<UUID>,
 PatientName=End to End Test,
 PatientEmail=<EMAIL>]
```

This confirms that the asynchronous Kafka path is working.

---

# PostgreSQL

PostgreSQL is currently installed on the host and listens on port:

```text
5433
```

The project uses separate databases:

```text
patient_service_db
auth_service_db
```

PostgreSQL must be reachable from the Docker containers.

The Docker network currently uses:

```text
172.26.0.0/16
```

and the PostgreSQL access configuration allows the Docker subnet.

Check PostgreSQL listening state:

```bash
sudo ss -lntp | grep 5433
```

List databases:

```bash
sudo -u postgres psql -p 5433 -c "\l"
```

---

# Docker Network

The application containers use an external Docker network:

```yaml
networks:
  backend-api:
    external: true
```

Current network:

```text
Name: backend-api
Driver: bridge
Subnet: 172.26.0.0/16
Gateway: 172.26.0.1
```

Inspect it:

```bash
docker network inspect backend-api
```

This allows service-to-service communication using Docker DNS names such as:

```text
patient-service
billing-service
auth-service
analytics-service
api-gateway
```

---

# Environment Configuration

Environment variables are stored in `.env`.

Typical configuration:

```env
JWT_SECRET=<secret>

DB_PORT=5433
DB_HOST=<host>

PATIENT_SPRING_DATASOURCE_URL=jdbc:postgresql://<host>:5433/patient_service_db
PATIENT_SPRING_DATASOURCE_USERNAME=patient_service
PATIENT_SPRING_DATASOURCE_PASSWORD=<password>
PATIENT_SPRING_JPA_HIBERNATE_DDL_AUTO=update
PATIENT_SPRING_SQL_INIT_MODE=always

AUTH_SPRING_DATASOURCE_URL=jdbc:postgresql://<host>:5433/auth_service_db
AUTH_SPRING_DATASOURCE_USERNAME=auth_service
AUTH_SPRING_DATASOURCE_PASSWORD=<password>
AUTH_SPRING_JPA_HIBERNATE_DDL_AUTO=update
AUTH_SPRING_SQL_INIT_MODE=always

SPRING_KAFKA_BOOTSTRAP_SERVERS=host.docker.internal:9092
```

Do not commit real passwords, JWT secrets, database credentials, or other secrets.

---

# Docker Compose

The application services are containerized with Docker Compose.

Build the images:

```bash
docker compose build
```

Start the stack:

```bash
docker compose up -d
```

Check status:

```bash
docker compose ps
```

Follow logs:

```bash
docker compose logs -f
```

Follow a specific service:

```bash
docker compose logs -f patient-service
```

Multiple services:

```bash
docker compose logs -f patient-service billing-service analytics-service
```

Stop the application:

```bash
docker compose down
```

---

# Health Checks

The application services expose Spring Boot Actuator health endpoints.

Examples:

```text
Patient Service   → :4000/actuator/health
Billing Service   → :4001/actuator/health
Auth Service      → :4005/actuator/health
Analytics Service → :8080/actuator/health
API Gateway       → :4004/actuator/health
```

Example:

```bash
docker exec patient-service \
  curl -s http://localhost:4000/actuator/health
```

Expected:

```json
{
  "status": "UP"
}
```

---

# End-to-End Testing

The complete application workflow has been tested successfully.

## 1. Login

```bash
TOKEN=$(curl -s -X POST http://localhost:4004/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@test.com",
    "password": "password123"
  }' | jq -r '.token')
```

Verify:

```bash
test -n "$TOKEN" \
  && echo "AUTH LOGIN: PASS" \
  || echo "AUTH LOGIN: FAIL"
```

## 2. Validate JWT

```bash
curl -i http://localhost:4004/auth/validate \
  -H "Authorization: Bearer $TOKEN"
```

Result:

```text
200 OK
```

## 3. Verify authentication protection

Without a token:

```bash
curl -i http://localhost:4004/api/patients
```

Result:

```text
401 Unauthorized
```

With a valid token:

```bash
curl -i http://localhost:4004/api/patients \
  -H "Authorization: Bearer $TOKEN"
```

Result:

```text
200 OK
```

## 4. Create patient

A full E2E patient was successfully created.

Example:

```text
Patient ID:
601c1d9d-bf04-44a1-8e54-7186e6b64c82
```

The response was:

```json
{
  "id": "601c1d9d-bf04-44a1-8e54-7186e6b64c82",
  "name": "Full E2E Test",
  "email": "full-e2e-1790626268@example.com",
  "address": "123 Test Street",
  "dateOfBirth": "1995-05-20"
}
```

## 5. Verify Billing gRPC

The Billing Service received the patient creation request and returned:

```text
accountId: "12345"
status: "ACTIVE"
```

## 6. Verify Kafka

The patient event was published to the `patient` Kafka topic.

## 7. Verify Analytics

Analytics consumed the event successfully.

Example:

```text
Received Patient Event:
[PatientId=<UUID>,
 PatientName=End to End Test,
 PatientEmail=<EMAIL>]
```

## 8. Update patient

The patient was successfully updated:

```text
200 OK
```

The updated record contained:

```text
name: Full E2E Test Updated
address: 456 Updated Street
```

## 9. Delete patient

Delete request:

```text
204 No Content
```

A subsequent lookup returned no matching patient.

---

# Current Test Matrix

| Component / Flow             | Status                |
| ---------------------------- | --------------------- |
| API Gateway startup          | ✅                     |
| Auth Service startup         | ✅                     |
| Patient Service startup      | ✅                     |
| Billing Service startup      | ✅                     |
| Analytics Service startup    | ✅                     |
| JWT login                    | ✅                     |
| JWT validation               | ✅                     |
| Unauthorized request blocked | ✅                     |
| Authenticated patient GET    | ✅                     |
| Patient CREATE               | ✅                     |
| Patient READ                 | ✅                     |
| Patient UPDATE               | ✅                     |
| Patient DELETE               | ✅                     |
| PostgreSQL connectivity      | ✅                     |
| Patient → Billing gRPC       | ✅                     |
| Patient → Kafka              | ✅                     |
| Kafka → Analytics            | ✅                     |
| Kafka `patient` topic        | ✅                     |
| API documentation route      | ✅ Previously verified |
| Actuator health endpoints    | ✅ Configured          |

---

# Troubleshooting Notes

## Patient Service initially used localhost for Kafka

Inside a container:

```text
localhost:9092
```

refers to the container itself, not the host Kafka broker.

The application was changed to use:

```text
host.docker.internal:9092
```

with:

```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

---

## Patient Service → Billing gRPC

The Patient Service originally defaulted to:

```text
localhost:9001
```

This was changed for Docker to:

```text
billing-service:9001
```

The relevant configuration is:

```yaml
BILLING_SERVICE_ADDRESS: billing-service
BILLING_SERVICE_GRPC_PORT: "9001"
```

---

## Spring datasource environment variables

Spring Boot expects standard property names.

The Compose configuration therefore maps environment variables such as:

```yaml
SPRING_DATASOURCE_URL
SPRING_DATASOURCE_USERNAME
SPRING_DATASOURCE_PASSWORD
```

to project-specific `.env` variables.

For example:

```yaml
SPRING_DATASOURCE_URL: "${PATIENT_SPRING_DATASOURCE_URL}"
```

This prevents Spring from silently falling back to an unintended database configuration.

---

## Billing health check

Billing exposes:

```text
HTTP :4001
gRPC :9001
```

The health check must target the HTTP port:

```text
http://localhost:4001/actuator/health
```

It must not send an HTTP health request to the gRPC port.

---

# Useful Commands

### View all services

```bash
docker compose ps
```

### Follow all logs

```bash
docker compose logs -f
```

### Follow patient flow

```bash
docker compose logs -f patient-service billing-service analytics-service
```

### Inspect Docker network

```bash
docker network inspect backend-api
```

### Restart a single service

```bash
docker compose restart patient-service
```

### Rebuild a service

```bash
docker compose build patient-service
```

### Recreate a service

```bash
docker compose up -d --force-recreate patient-service
```

### Inspect recent errors

```bash
docker compose logs --since 10m | grep -iE "error|exception|failed"
```

---

# Current Deployment Model

This project currently uses a hybrid local deployment model:

```text
Docker
├── API Gateway
├── Patient Service
├── Billing Service
├── Auth Service
└── Analytics Service

Host
├── PostgreSQL :5433
└── Kafka :9092
```

This setup intentionally keeps PostgreSQL and Kafka outside Docker while the application microservices run as containers.

---

# Current Project Status

The core microservice integration is operational.

The following workflow has been demonstrated successfully:

```text
JWT Authentication
       ↓
API Gateway
       ↓
Patient Service
       ↓
PostgreSQL
       ↓
Billing Service via gRPC
       ↓
Kafka
       ↓
Analytics Service
```

CRUD operations have also been exercised successfully through the gateway.

The current implementation is a functional containerized microservices environment suitable for continuing work on observability, reliability, security hardening, CI/CD, and eventual orchestration.

---

# Next Areas of Development

Potential next stages include:

* OpenTelemetry instrumentation across all services
* SigNoz integration
* Distributed tracing across HTTP, gRPC, Kafka, and PostgreSQL
* Centralized application logging
* Metrics collection and dashboards
* Kafka resilience and multi-broker configuration
* PostgreSQL resilience and backup strategy
* Container image hardening
* Secrets management
* CI/CD pipelines
* Automated integration tests
* Kubernetes deployment
* Service scaling and high availability


1. Docker Compose ✅
2. OpenTelemetry
3. SigNoz
4. Distributed tracing
5. Logs + trace correlation
6. Metrics
7. Kafka/PostgreSQL observability
8. Security hardening
9. CI/CD
10. Failure testing
11. Kubernetes
12. Production-style deployment


Layer	What you observe
Application	JVM, requests, threads, GC
Container	CPU, RAM, I/O, throttling
Host	Overall server CPU, RAM, disk, network