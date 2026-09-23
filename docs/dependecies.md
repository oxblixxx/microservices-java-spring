# Java Spring Microservices — Deployment Journal

## Project

This project is based on the Java/Spring Microservices project by Chris Blakely.

Original repository:
https://github.com/chrisblakely01/java-spring-microservices

This repository is an independent learning and implementation project focused on understanding and deploying the microservices application from a DevOps perspective.

---

# Environment

## Server

* OS:
* Hostname:
* CPU:
* RAM:
* Storage:
* Public IP:
* Domain:

## Development/Deployment Approach

Initial target:

```text
Server
├── PostgreSQL
├── Kafka
├── Patient Service
├── Auth Service
├── Billing Service
├── Analytics Service
└── API Gateway
```

The application will initially be deployed directly on the server to understand the application and its dependencies before introducing Docker, Kubernetes, and AWS.

---

# 1. Initial Server Preparation

## 1.1 Update system

```bash
sudo apt update
sudo apt upgrade -y
```

## 1.2 Check operating system

```bash
cat /etc/os-release
```

Result:

```text
<!-- Record result here -->
```

## 1.3 Check resources

```bash
lscpu
free -h
df -h
```

Result:

```text
<!-- Record result here -->
```

---

# 2. Required Dependencies

Dependencies will be documented as they are installed.

| Dependency | Version | Purpose                  | Status |
| ---------- | ------- | ------------------------ | ------ |
| Java       |         | Run Spring Boot services | ⬜      |
| Maven      |         | Build Java applications  | ⬜      |
| PostgreSQL |         | Application databases    | ⬜      |
| Kafka      |         | Event streaming          | ⬜      |
| Git        |         | Source control           | ⬜      |
| curl       |         | API testing              | ⬜      |

---

# 3. Java

## Why it is required

The microservices are Spring Boot applications running on Java.

## Installation

Commands:

```bash
<!-- Add commands used -->
```

## Verification

```bash
java -version
```

Result:

```text
<!-- Record result -->
```

---

# 4. Maven

## Why it is required

Each microservice is an independent Maven project.

Examples:

```text
patient-service/pom.xml
auth-service/pom.xml
billing-service/pom.xml
analytics-service/pom.xml
api-gateway/pom.xml
```

The repository also contains Maven Wrapper files:

```text
mvnw
mvnw.cmd
.mvn/
```

## Installation

Commands:

```bash
<!-- Add commands used -->
```

## Verification

```bash
mvn -version
```

Result:

```text
<!-- Record result -->
```

---

# 5. PostgreSQL

## Why it is required

Two services require persistent relational databases:

```text
Patient Service → Patient PostgreSQL database

Auth Service → Auth PostgreSQL database
```

## Installation

Commands:

```bash
<!-- Add commands used -->
```

## Verification

```bash
psql --version
sudo systemctl status postgresql
```

Result:

```text
<!-- Record result -->
```

## Databases

Planned databases:

```text
patient-service-db
auth-service-db
```

Credentials/configuration:

```text
<!-- Document local development configuration here.
Do NOT commit real passwords or secrets. -->
```

---

# 6. Kafka

## Why it is required

Patient Service publishes patient events:

```text
Patient Service
      │
      │ PatientEvent
      ▼
    Kafka
      │
      ▼
Analytics Service
```

Kafka topic:

```text
patient
```

Consumer group:

```text
analytics-service
```

## Installation

Commands:

```bash
<!-- Add commands used -->
```

## Verification

```bash
<!-- Add verification commands -->
```

Result:

```text
<!-- Record result -->
```

---

# 7. Application Configuration

## Patient Service

Port:

```text
4000
```

Database:

```text
PostgreSQL
```

Kafka:

```text
patient
```

Billing communication:

```text
gRPC :9001
```

Configuration:

```text
<!-- Record configuration -->
```

---

## Auth Service

Port:

```text
4005
```

Database:

```text
PostgreSQL
```

Configuration:

```text
<!-- Record configuration -->
```

---

## Billing Service

HTTP:

```text
4001
```

gRPC:

```text
9001
```

Configuration:

```text
<!-- Record configuration -->
```

---

## Analytics Service

Kafka consumer:

```text
Topic: patient
Group: analytics-service
```

Configuration:

```text
<!-- Record configuration -->
```

---

## API Gateway

Port:

```text
4004
```

Routes:

```text
/auth/**              → Auth Service

/api/patients/**      → Patient Service
```

---

# 8. Service Startup Order

Initial startup order:

```text
1. PostgreSQL
2. Kafka
3. Billing Service
4. Auth Service
5. Patient Service
6. Analytics Service
7. API Gateway
```

This order may change as the application is tested.

---

# 9. Testing

## Patient Service

Test:

```bash
curl ...
```

Expected result:

```text
<!-- Record result -->
```

## Auth Service

Test login:

```bash
curl ...
```

Expected result:

```text
<!-- Record result -->
```

## Billing gRPC

Test:

```bash
grpcurl ...
```

Expected result:

```text
<!-- Record result -->
```

## Kafka

Create a patient and verify that Analytics receives:

```text
PatientEvent
```

Expected log:

```text
<!-- Record result -->
```

---

# 10. Problems Encountered

## Problem 1

Date:

```text
YYYY-MM-DD
```

Problem:

```text
<!-- Describe the problem -->
```

Cause:

```text
<!-- Describe the cause -->
```

Solution:

```text
<!-- Describe the solution -->
```

Verification:

```text
<!-- Explain how it was verified -->
```

---

# 11. Architecture Changes

Document changes made to the original project here.

| Date | Change | Reason |
| ---- | ------ | ------ |
|      |        |        |

---

# 12. DevOps Implementation

Future work:

* [ ] Run all services successfully on server
* [ ] Configure PostgreSQL
* [ ] Configure Kafka
* [ ] Test gRPC communication
* [ ] Test Kafka event flow
* [ ] Test API Gateway
* [ ] Add environment-based configuration
* [ ] Dockerize services
* [ ] Create Docker Compose environment
* [ ] Add health checks
* [ ] Add logging/monitoring
* [ ] Create Kubernetes manifests
* [ ] Create Helm chart
* [ ] Create Terraform infrastructure
* [ ] Deploy to AWS
* [ ] Configure ECS/Fargate
* [ ] Configure RDS
* [ ] Configure MSK
* [ ] Add CI/CD

---

# 13. Lessons Learned

### Entry 1

Date:

```text
YYYY-MM-DD
```

What I learned:

```text
<!-- Write what you actually learned -->
```

What confused me:

```text
<!-- Record confusing concepts -->
```

How I resolved it:

```text
<!-- Record explanation or solution -->
```
