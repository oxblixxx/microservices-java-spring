package com.pm.apigateway.exception;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.mock.http.server.reactive.MockServerHttpRequest;
import org.springframework.mock.web.server.MockServerWebExchange;
import reactor.test.StepVerifier;

class JwtValidationExceptionTest {

  private final JwtValidationException handler = new JwtValidationException();

  @Test
  void handleUnauthorizedExceptionSetsUnauthorizedAndCompletes() {
    MockServerWebExchange exchange = MockServerWebExchange.from(
        MockServerHttpRequest.get("/api/patients").build());

    StepVerifier.create(handler.handleUnauthorizedException(exchange))
        .verifyComplete();

    assertEquals(HttpStatus.UNAUTHORIZED,
        exchange.getResponse().getStatusCode());
  }
}
