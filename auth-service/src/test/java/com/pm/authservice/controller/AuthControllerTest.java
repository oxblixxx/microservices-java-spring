package com.pm.authservice.controller;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.pm.authservice.dto.LoginRequestDTO;
import com.pm.authservice.dto.LoginResponseDTO;
import com.pm.authservice.service.AuthService;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

@ExtendWith(MockitoExtension.class)
class AuthControllerTest {

  @Mock
  private AuthService authService;

  @InjectMocks
  private AuthController authController;

  @Test
  void loginReturnsOkWithTokenWhenAuthenticationSucceeds() {
    LoginRequestDTO request = request("jane@example.com", "password123");
    when(authService.authenticate(request)).thenReturn(Optional.of("token"));

    ResponseEntity<LoginResponseDTO> response = authController.login(request);

    assertEquals(HttpStatus.OK, response.getStatusCode());
    assertNotNull(response.getBody());
    assertEquals("token", response.getBody().getToken());
  }

  @Test
  void loginReturnsUnauthorizedWhenAuthenticationFails() {
    LoginRequestDTO request = request("jane@example.com", "wrong-password");
    when(authService.authenticate(request)).thenReturn(Optional.empty());

    ResponseEntity<LoginResponseDTO> response = authController.login(request);

    assertEquals(HttpStatus.UNAUTHORIZED, response.getStatusCode());
    assertNull(response.getBody());
  }

  @Test
  void validateTokenReturnsOkForValidBearerToken() {
    when(authService.validateToken("token")).thenReturn(true);

    ResponseEntity<Void> response = authController.validateToken(
        "Bearer token");

    assertEquals(HttpStatus.OK, response.getStatusCode());
    verify(authService).validateToken("token");
  }

  @Test
  void validateTokenReturnsUnauthorizedForInvalidBearerToken() {
    when(authService.validateToken("token")).thenReturn(false);

    ResponseEntity<Void> response = authController.validateToken(
        "Bearer token");

    assertEquals(HttpStatus.UNAUTHORIZED, response.getStatusCode());
    verify(authService).validateToken("token");
  }

  @Test
  void validateTokenReturnsUnauthorizedWhenHeaderHasNoBearerPrefix() {
    ResponseEntity<Void> response = authController.validateToken("token");

    assertEquals(HttpStatus.UNAUTHORIZED, response.getStatusCode());
    verifyNoInteractions(authService);
  }

  @Test
  void validateTokenReturnsUnauthorizedWhenHeaderIsNull() {
    ResponseEntity<Void> response = authController.validateToken(null);

    assertEquals(HttpStatus.UNAUTHORIZED, response.getStatusCode());
    verifyNoInteractions(authService);
  }

  private static LoginRequestDTO request(String email, String password) {
    LoginRequestDTO request = new LoginRequestDTO();
    request.setEmail(email);
    request.setPassword(password);
    return request;
  }
}
