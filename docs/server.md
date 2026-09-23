create KAFKA USER

sudo useradd --system --no-create-home --shell /usr/sbin/nologin kafka

https://kafka.apache.org/community/downloads/
sudo tar -xzf kafka_2.13-4.3.1.tgz -C /opt

nHADMbm6Rwuh26NW41M4PA


sudo -u kafka /opt/kafka/bin/kafka-storage.sh format \
  --standalone \
  -t nHADMbm6Rwuh26NW41M4PA \
  -c /opt/kafka/config/server.properties



Milestone: Local bare-metal deployment completed

Java:
- Oracle JDK 21.0.12
- Maven 3.9.9

Database:
- PostgreSQL 18.6
- Port 5433

Services:
- Patient Service: 4000
- Billing Service: 4001
- Auth Service: 4005
- API Gateway: 4004
- Analytics Service: verified

Messaging:
- Apache Kafka 4.3.x
- KRaft mode
- Single broker/controller
- Kafka port: 9092
- Controller port: 9093
- Topic: patient
- Partitions: 1
- Replication factor: 1

Verified:
- Patient API responds successfully
- Auth login works and returns JWT
- JWT validation works
- Billing gRPC communication works
- Kafka topic works
- Patient events reach Analytics Service