# Unit Tests — patient-service

## Summary

Added isolated **unit tests only** for the existing `patient-service` code under
`patient-service/src/main/java/`. Tests use JUnit 5 + Mockito and require no
PostgreSQL, Kafka, other microservices, network, or Docker.

## Test classes added

| Test file | Tests |
| --- | --- |
| `patient-service/src/test/java/com/pm/patientservice/service/PatientServiceTest.java` | 8 |
| `patient-service/src/test/java/com/pm/patientservice/mapper/PatientMapperTest.java` | 2 |
| `patient-service/src/test/java/com/pm/patientservice/exception/GlobalExceptionHandlerTest.java` | 3 |
| `patient-service/src/test/java/com/pm/patientservice/kafka/KafkaProducerTest.java` | 2 |
| **Total new tests** | **15** |

The pre-existing `PatientServiceApplicationTests` (`@SpringBootTest` context-loads) was left unchanged.

## Classes tested

- `PatientService`
- `PatientMapper`
- `GlobalExceptionHandler`
- `KafkaProducer`

## Functionality covered

- **`PatientService.getPatients`** — `findAll()` results are mapped via
  `PatientMapper.toDTO`; empty-list path.
- **`PatientService.createPatient`** — throws `EmailAlreadyExistsException` when
  `existsByEmail` is true (no `save`, no billing/Kafka calls); success path saves
  the mapped `Patient`, calls `BillingServiceGrpcClient.createBillingAccount` with
  id/name/email, calls `KafkaProducer.sendEvent`, and returns the mapped DTO.
- **`PatientService.updatePatient`** — throws `PatientNotFoundException` when
  `findById` is empty; throws `EmailAlreadyExistsException` when
  `existsByEmailAndIdNot` is true (entity left unmodified); success path applies
  name/address/email/dateOfBirth, saves, and returns the DTO.
- **`PatientService.deletePatient`** — delegates to `deleteById`.
- **`PatientMapper.toDTO`** — id/name/address/email/dateOfBirth string mapping.
- **`PatientMapper.toModel`** — field mapping and `LocalDate` parsing of
  `dateOfBirth` and `registeredDate`.
- **`GlobalExceptionHandler`** — `400` responses for `EmailAlreadyExistsException`
  ("Email address already exists"), `PatientNotFoundException` ("Patient not found"),
  and `MethodArgumentNotValidException` field-error mapping.
- **`KafkaProducer.sendEvent`** — publishes a `PatientEvent` with event type
  `PATIENT_CREATED` to the `patient` topic with patientId/name/email, and swallows
  broker exceptions.

## How the unit under test is isolated

- `PatientRepository`, `BillingServiceGrpcClient`, and `KafkaProducer` are Mockito
  mocks injected into the real `PatientService` via `@InjectMocks`.
- `KafkaTemplate` is mocked; the produced protobuf payload is captured and parsed.
- The class under test is never mocked.

## Verification

Run from `patient-service/`:

```bash
./mvnw test
./mvnw verify
```

Results:

| Command | Result |
| --- | --- |
| `./mvnw test` | **PASS** — Tests run: 16, Failures: 0, Errors: 0, Skipped: 0 (15 new + 1 pre-existing) |
| `./mvnw verify` | **PASS** — Tests run: 16, Failures: 0, Errors: 0, Skipped: 0; BUILD SUCCESS |

## Changes to production code

None.

## Integration tests

Not modified. `integration-tests/` was untouched.

## External infrastructure required

No. New tests are standalone JUnit 5 + Mockito and need no database, Kafka, gRPC,
network, or Docker.

## Remaining unit-testable areas / limitations

- **`BillingServiceGrpcClient.createBillingAccount`** — builds a `BillingRequest` and
  calls a `BillingServiceBlockingStub` created inside the constructor from a live
  gRPC `ManagedChannel`. The stub is not injectable, so it cannot be unit-tested in
  isolation without reflection or a production refactor. Left untested.
- **`PatientController`** — thin delegation to `PatientService` wrapped in
  `ResponseEntity`; excluded as framework wiring.
- **Trivial types** (`Patient`, `PatientRequestDTO`, `PatientResponseDTO`,
  `CreatePatientValidationGroup`, `PatientRepository`, the two exception classes,
  `PatientServiceApplication`) — data holders, interfaces, or empty types with no
  meaningful behavior; not tested.
