# Unit Tests — billing-service

## Summary

Added isolated **unit tests only** for the existing `billing-service` code under
`billing-service/src/main/java/`. Tests use JUnit 5 + Mockito and require no
PostgreSQL, Kafka, gRPC network connection, other microservices, or Docker.

`billing-service` contains only one production class with meaningful logic
(`BillingGrpcService`); the pre-existing `BillingServiceApplicationTests`
(`@SpringBootTest` context-loads) was left unchanged.

## Test classes added

| Test file | Tests |
| --- | --- |
| `billing-service/src/test/java/com/pm/billingservice/grpc/BillingGrpcServiceTest.java` | 2 |
| **Total new tests** | **2** |

## Classes tested

- `BillingGrpcService`

## Functionality covered

- **`BillingGrpcService.createBillingAccount`** — builds a fixed
  `BillingResponse` with `accountId = "12345"` and `status = "ACTIVE"` (the only
  response the implementation produces), sends it via `responseObserver.onNext(...)`,
  and calls `responseObserver.onCompleted()` without calling `onError(...)`.

No other behavior exists in the source to test: the method contains no validation,
repository interaction, or branching.

## How the unit under test is isolated

- The real `BillingGrpcService` is instantiated directly (`new BillingGrpcService()`);
  it is never mocked.
- `StreamObserver<BillingResponse>` is a Mockito mock, and the emitted response is
  captured with `ArgumentCaptor`.
- No gRPC server is started and no port/network is used.

## Verification

Run from `billing-service/`:

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

None.

## Integration tests

Not modified. `integration-tests/` was untouched.

## External infrastructure required

No. New tests are standalone JUnit 5 + Mockito; no database, Kafka, gRPC server,
network, or Docker.

## Remaining unit-testable areas / limitations

- **Generated protobuf/gRPC classes** (`billing.BillingRequest`,
  `billing.BillingResponse`, `billing.BillingServiceGrpc`, and the service base
  class) — framework-generated code, not hand-written logic; not tested.
- **`BillingServiceApplication`** — Spring Boot bootstrap class with no logic; not
  tested.
- There are no repositories, mappers, entities, DTOs, validators, or utility classes
  in `billing-service`, so there is nothing further to unit-test.
