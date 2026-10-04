# Unit Tests — auth-service

## Summary

Added isolated **unit tests only** for the existing `auth-service` code under
`auth-service/src/main/java/`. Tests use JUnit 5 + Mockito (and real JJWT parsing
for `JwtUtil`) and require no PostgreSQL, Kafka, other microservices, network, or
Docker.

There was no pre-existing `auth-service/src/test/` directory; all tests below are new.

## Test classes added

| Test file | Tests |
| --- | --- |
| `auth-service/src/test/java/com/pm/authservice/service/AuthServiceTest.java` | 5 |
| `auth-service/src/test/java/com/pm/authservice/service/UserServiceTest.java` | 2 |
| `auth-service/src/test/java/com/pm/authservice/util/JwtUtilTest.java` | 5 |
| `auth-service/src/test/java/com/pm/authservice/controller/AuthControllerTest.java` | 6 |
| **Total new tests** | **18** |

## Classes tested

- `AuthService`
- `UserService`
- `JwtUtil`
- `AuthController`

## Functionality covered

- **`AuthService.authenticate`** — returns the JWT when the user exists and the
  password matches (`jwtUtil.generateToken(email, role)` is called with the stored
  email/role); returns `Optional.empty()` when the password does not match (token
  generation is not called); returns `Optional.empty()` when the user is not found
  (`PasswordEncoder`/`JwtUtil` are not touched).
- **`AuthService.validateToken`** — returns `true` when `JwtUtil.validateToken`
  succeeds; returns `false` when it throws `JwtException`.
- **`UserService.findByEmail`** — returns the repository result when a user exists;
  returns `Optional.empty()` when the repository finds nothing.
- **`JwtUtil.generateToken`/`validateToken`** — generated token has the given email as
  subject, a `role` claim, issued-at and expiration timestamps with expiration after
  issue; a generated token validates successfully; validation rejects a token signed
  with a different key, an expired token, and a malformed token (all as `JwtException`).
- **`AuthController.login`** — returns `200 OK` with a `LoginResponseDTO` carrying the
  token when authentication succeeds; returns `401 Unauthorized` with no body when it
  fails.
- **`AuthController.validateToken`** — returns `200 OK` for a valid `Bearer <token>`;
  returns `401 Unauthorized` for an invalid token; returns `401 Unauthorized` and does
  not call the service when the header has no `Bearer ` prefix or is `null`.

## How the unit under test is isolated

- `AuthService`: `UserService`, `PasswordEncoder`, and `JwtUtil` are Mockito mocks
  injected via `@InjectMocks`.
- `UserService`: `UserRepository` is mocked.
- `AuthController`: `AuthService` is mocked; controller methods are called directly
  (no Spring MVC / no servlet container).
- `JwtUtil`: uses the real implementation with a real Base64-encoded 256-bit HMAC
  secret; tokens are produced/parsed in-process with JJWT. No infrastructure.
- The class under test is never mocked.

## Verification

Run from `auth-service/`:

```bash
./mvnw test
./mvnw verify
```

Results:

| Command | Result |
| --- | --- |
| `./mvnw test` | **PASS** — Tests run: 18, Failures: 0, Errors: 0, Skipped: 0; BUILD SUCCESS |
| `./mvnw verify` | **PASS** — Tests run: 18, Failures: 0, Errors: 0, Skipped: 0; BUILD SUCCESS |

## Changes to production code

None.

## Integration tests

Not modified. `integration-tests/` was untouched.

## External infrastructure required

No. Tests are standalone JUnit 5 + Mockito plus in-process JJWT; no database, Kafka,
gRPC, network, or Docker.

## Remaining unit-testable areas / limitations

- **`SecurityConfig`** — defines a `SecurityFilterChain` (permit-all, CSRF disabled)
  and a `BCryptPasswordEncoder` bean. Testing these meaningfully requires the Spring
  context/framework rather than isolated unit tests, so it was left untested per the
  "no `@SpringBootTest` for ordinary unit tests" rule.
- **`User`**, **`LoginRequestDTO`**, **`LoginResponseDTO`**, **`UserRepository`**,
  **`AuthServiceApplication`** — entity/DTO data holders, a Spring Data interface, and
  the bootstrap class with no meaningful logic; not tested.
- **`LoginRequestDTO` bean-validation constraints** — annotation-based `@NotBlank` /
  `@Email` / `@Size` rules; verifying them requires a validator, and the constraints
  are declarative rather than service logic, so they were not unit-tested.
