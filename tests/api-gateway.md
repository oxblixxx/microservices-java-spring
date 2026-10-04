# Unit Tests — api-gateway

## Summary

Added isolated **unit tests only** for the existing `api-gateway` code under
`api-gateway/src/main/java/`. Tests use JUnit 5 + Mockito (+ Reactor `StepVerifier`)
and require no running gateway port, no upstream services, no database, Kafka, Redis,
network, or Docker.

There was no pre-existing `api-gateway/src/test/` directory.

## Test classes added

| Test file | Tests |
| --- | --- |
| `api-gateway/src/test/java/com/pm/apigateway/filter/JwtValidationGatewayFilterFactoryTest.java` | 3 |
| `api-gateway/src/test/java/com/pm/apigateway/exception/JwtValidationExceptionTest.java` | 1 |
| **Total new tests** | **4** |

## Classes tested

- `JwtValidationGatewayFilterFactory`
- `JwtValidationException`

## Functionality covered

- **`JwtValidationGatewayFilterFactory.apply(...)`** (`GatewayFilter`):
  - When the request has a `Bearer ` `Authorization` header, the filter calls the
    auth service's `/validate` endpoint through `WebClient`, forwarding the
    `Authorization` header, and only then continues the `GatewayFilterChain`.
  - When the `Authorization` header is missing, the response is set to
    `401 UNAUTHORIZED` and the chain is **not** invoked.
  - When the `Authorization` header does not start with `Bearer `, the response is
    set to `401 UNAUTHORIZED` and the chain is **not** invoked.
  - Constructor wiring: the `WebClient` is built from `WebClient.Builder` with the
    configured `auth.service.url` as base URL.
- **`JwtValidationException.handleUnauthorizedException(ServerWebExchange)`**: sets
  the response status to `401 UNAUTHORIZED` and completes the response
  (error-handling advice).

## How the unit under test is isolated

- The real `JwtValidationGatewayFilterFactory` and `JwtValidationException` are
  instantiated directly; neither is mocked.
- `WebClient.Builder`, `WebClient`, and `GatewayFilterChain` are Mockito mocks; the
  WebClient fluent call chain is mocked so no HTTP request is made.
- `MockServerWebExchange` (spring-test) provides a real in-memory exchange, so the
  resulting status code is asserted directly.
- Reactive results are asserted with `StepVerifier`.

## Verification

Run from `api-gateway/`:

```bash
./mvnw test
./mvnw verify
```

Results:

| Command | Result |
| --- | --- |
| `./mvnw test` | **PASS** — Tests run: 4, Failures: 0, Errors: 0, Skipped: 0; BUILD SUCCESS |
| `./mvnw verify` | **PASS** — Tests run: 4, Failures: 0, Errors: 0, Skipped: 0; BUILD SUCCESS |

## Changes to production code

None.

## Integration tests

Not modified. `integration-tests/` was untouched.

## External infrastructure required

No. Tests are standalone JUnit 5 + Mockito with `StepVerifier` and
`MockServerWebExchange`; no gateway listener, upstream service, database, or network.

## Remaining unit-testable areas / limitations

- **`ApiGatewayApplication`** — Spring Boot bootstrap class with no logic; not tested.
- **Route configuration** (`application.yml`, `application-prod.yml`) — declarative
  Spring Cloud Gateway routes (`Path`, `StripPrefix`, `RewritePath`, `JwtValidation`);
  pure configuration values, not custom logic, so not unit-tested per the task
  guidance.
- The `JwtValidationGatewayFilterFactory` success path is tested with a mocked
  `WebClient`; a genuine end-to-end 401 response from the auth service is out of
  scope for isolated unit tests.
