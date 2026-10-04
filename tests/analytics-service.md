# Unit Tests — analytics-service

## Summary

Added isolated **unit tests only** for the existing `analytics-service` code under
`analytics-service/src/main/java/`. Tests use JUnit 5 and require no PostgreSQL,
Kafka broker, other microservices, network, or Docker.

`analytics-service` contains one production class with meaningful logic
(`KafkaConsumer`). The pre-existing `AnalyticsServiceApplicationTests`
(`@SpringBootTest` context-loads) was left in place.

## Test classes added

| Test file | Tests |
| --- | --- |
| `analytics-service/src/test/java/com/pm/analyticsservice/kafka/KafkaConsumerTest.java` | 2 |
| **Total new tests** | **2** |

## Classes tested

- `KafkaConsumer`

## Functionality covered

- **`KafkaConsumer.consumeEvent(byte[])`** — for a valid serialized `PatientEvent`
  the payload is parsed and an `INFO` log line containing the patient's id, name,
  and email is emitted; for an invalid protobuf payload the
  `InvalidProtocolBufferException` is caught (not propagated) and an `ERROR`
  "Error deserializing event …" log line is emitted.

The method has no further logic (the source contains only a comment placeholding
future analytics work), so no other behavior is tested.

## How the unit under test is isolated

- The real `KafkaConsumer` is instantiated directly (`new KafkaConsumer()`) and is
  never mocked.
- No Kafka broker or listener: `consumeEvent` is invoked directly with a
  `byte[]`; a Logback `ListAppender` attached to the class logger captures the
  actual log output used for assertions.
- No application context is started for this test.

## Note on the pre-existing `contextLoads` test

Plain `./mvnw test` was initially failing **before** this change: this shell exports
`SPRING_KAFKA_BOOTSTRAP_SERVERS=host.docker.internal:9092` (from the repo `.env`), and
`host.docker.internal` does not resolve on this host, so Spring's Kafka consumer
construction failed with `No resolvable bootstrap urls given in bootstrap.servers` and
the `@SpringBootTest` context could not start.

To keep the module's tests infrastructure-free (a requirement of this task), a
**test-only** resource was added:
`analytics-service/src/test/resources/application.properties` with
`spring.kafka.listener.auto-startup=false`, so `@KafkaListener` containers are not
started during tests. The existing `contextLoads` test is unchanged and still asserts
that the Spring context loads; no production code was touched.

## Verification

Run from `analytics-service/` (with the inherited environment unchanged):

```bash
./mvnw test
./mvnw verify
```

Results:

| Command | Result |
| --- | --- |
| `./mvnw test` | **PASS** — Tests run: 3, Failures: 0, Errors: 0, Skipped: 0 (2 new + 1 pre-existing); BUILD SUCCESS |
| `./mvnw verify` | **PASS** — Tests run: 3, Failures: 0, Errors: 0, Skipped: 0; BUILD SUCCESS |

## Changes to production code

None. (One test-only resource file was added under `src/test/resources/`.)

## Integration tests

Not modified. `integration-tests/` was untouched.

## External infrastructure required

No. New tests are standalone JUnit 5 with in-JVM logging capture; no database,
broker, network, or Docker. The Spring `contextLoads` test no longer requires a
reachable Kafka broker.

## Remaining unit-testable areas / limitations

- **`AnalyticsServiceApplication`** — Spring Boot bootstrap class with no logic; not
  tested.
- **Generated protobuf class `patient.events.PatientEvent`** — framework-generated
  code, not hand-written logic; not tested (used to build/parse fixtures).
- The `@KafkaListener` annotation wiring itself is framework configuration; the
  processing logic is covered by `KafkaConsumerTest`.
- There are no repositories, entities, DTOs, mappers, validators, or utility classes
  in `analytics-service`, so there is nothing further to unit-test.
