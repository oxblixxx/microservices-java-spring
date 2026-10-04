package com.pm.apigateway.filter;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.mock.http.server.reactive.MockServerHttpRequest;
import org.springframework.mock.web.server.MockServerWebExchange;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

@ExtendWith(MockitoExtension.class)
class JwtValidationGatewayFilterFactoryTest {

  private static final String AUTH_SERVICE_URL = "http://auth-service:4005";

  @Mock
  private WebClient.Builder webClientBuilder;

  @Mock
  private WebClient webClient;

  @Mock
  private GatewayFilterChain chain;

  private JwtValidationGatewayFilterFactory factory;

  @BeforeEach
  void setUp() {
    when(webClientBuilder.baseUrl(AUTH_SERVICE_URL)).thenReturn(
        webClientBuilder);
    when(webClientBuilder.build()).thenReturn(webClient);
    factory = new JwtValidationGatewayFilterFactory(webClientBuilder,
        AUTH_SERVICE_URL);
  }

  @Test
  @SuppressWarnings({"unchecked", "rawtypes"})
  void applyValidatesTokenAndContinuesChainForBearerToken() {
    WebClient.RequestHeadersUriSpec uriSpec = mock(
        WebClient.RequestHeadersUriSpec.class);
    WebClient.RequestHeadersSpec headerSpec = mock(
        WebClient.RequestHeadersSpec.class);
    WebClient.ResponseSpec responseSpec = mock(WebClient.ResponseSpec.class);

    when(webClient.get()).thenReturn(uriSpec);
    when(uriSpec.uri("/validate")).thenReturn(headerSpec);
    when(headerSpec.header(HttpHeaders.AUTHORIZATION, "Bearer abc"))
        .thenReturn(headerSpec);
    when(headerSpec.retrieve()).thenReturn(responseSpec);
    when(responseSpec.toBodilessEntity()).thenReturn(Mono.empty());
    when(chain.filter(any(ServerWebExchange.class))).thenReturn(Mono.empty());

    MockServerWebExchange exchange = MockServerWebExchange.from(
        MockServerHttpRequest.get("/api/patients")
            .header(HttpHeaders.AUTHORIZATION, "Bearer abc").build());

    GatewayFilter filter = factory.apply(new Object());

    StepVerifier.create(filter.filter(exchange, chain)).verifyComplete();

    verify(webClient).get();
    verify(uriSpec).uri("/validate");
    verify(headerSpec).header(HttpHeaders.AUTHORIZATION, "Bearer abc");
    verify(chain).filter(exchange);
  }

  @Test
  void applyRejectsRequestWithoutAuthorizationHeader() {
    MockServerWebExchange exchange = MockServerWebExchange.from(
        MockServerHttpRequest.get("/api/patients").build());

    GatewayFilter filter = factory.apply(new Object());

    StepVerifier.create(filter.filter(exchange, chain)).verifyComplete();

    assertEquals(HttpStatus.UNAUTHORIZED,
        exchange.getResponse().getStatusCode());
    verifyNoInteractions(chain);
    verifyNoInteractions(webClient);
  }

  @Test
  void applyRejectsRequestWithoutBearerPrefix() {
    MockServerWebExchange exchange = MockServerWebExchange.from(
        MockServerHttpRequest.get("/api/patients")
            .header(HttpHeaders.AUTHORIZATION, "token abc").build());

    GatewayFilter filter = factory.apply(new Object());

    StepVerifier.create(filter.filter(exchange, chain)).verifyComplete();

    assertEquals(HttpStatus.UNAUTHORIZED,
        exchange.getResponse().getStatusCode());
    verify(chain, never()).filter(any());
    verifyNoInteractions(webClient);
  }
}
