package com.pm.authservice.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.pm.authservice.dto.LoginRequestDTO;
import com.pm.authservice.model.User;
import com.pm.authservice.util.JwtUtil;
import io.jsonwebtoken.JwtException;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

  @Mock
  private UserService userService;

  @Mock
  private PasswordEncoder passwordEncoder;

  @Mock
  private JwtUtil jwtUtil;

  @InjectMocks
  private AuthService authService;

  @Test
  void authenticateReturnsTokenWhenCredentialsAreValid() {
    LoginRequestDTO request = request("jane@example.com", "password123");
    User user = user("jane@example.com", "hashed-password", "ADMIN");

    when(userService.findByEmail("jane@example.com"))
        .thenReturn(Optional.of(user));
    when(passwordEncoder.matches("password123", "hashed-password"))
        .thenReturn(true);
    when(jwtUtil.generateToken("jane@example.com", "ADMIN"))
        .thenReturn("signed-token");

    Optional<String> result = authService.authenticate(request);

    assertEquals(Optional.of("signed-token"), result);
    verify(jwtUtil).generateToken("jane@example.com", "ADMIN");
  }

  @Test
  void authenticateReturnsEmptyWhenPasswordDoesNotMatch() {
    LoginRequestDTO request = request("jane@example.com", "wrong-password");
    User user = user("jane@example.com", "hashed-password", "ADMIN");

    when(userService.findByEmail("jane@example.com"))
        .thenReturn(Optional.of(user));
    when(passwordEncoder.matches("wrong-password", "hashed-password"))
        .thenReturn(false);

    Optional<String> result = authService.authenticate(request);

    assertTrue(result.isEmpty());
    verify(jwtUtil, never()).generateToken(any(), any());
  }

  @Test
  void authenticateReturnsEmptyWhenUserDoesNotExist() {
    LoginRequestDTO request = request("missing@example.com", "password123");

    when(userService.findByEmail("missing@example.com"))
        .thenReturn(Optional.empty());

    Optional<String> result = authService.authenticate(request);

    assertTrue(result.isEmpty());
    verifyNoInteractions(passwordEncoder, jwtUtil);
  }

  @Test
  void validateTokenReturnsTrueWhenJwtIsValid() {
    assertTrue(authService.validateToken("valid-token"));
    verify(jwtUtil).validateToken("valid-token");
  }

  @Test
  void validateTokenReturnsFalseWhenJwtExceptionIsThrown() {
    doThrow(new JwtException("Invalid JWT")).when(jwtUtil)
        .validateToken("bad-token");

    assertFalse(authService.validateToken("bad-token"));
    verify(jwtUtil).validateToken("bad-token");
  }

  private static LoginRequestDTO request(String email, String password) {
    LoginRequestDTO request = new LoginRequestDTO();
    request.setEmail(email);
    request.setPassword(password);
    return request;
  }

  private static User user(String email, String password, String role) {
    User user = new User();
    user.setEmail(email);
    user.setPassword(password);
    user.setRole(role);
    return user;
  }
}
