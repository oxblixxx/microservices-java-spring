package com.pm.authservice.util;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Date;
import javax.crypto.SecretKey;
import org.junit.jupiter.api.Test;

class JwtUtilTest {

  // Base64 of a 32-byte value, satisfying the HMAC-SHA256 key length requirement.
  private static final String SECRET =
      "MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=";
  private static final String OTHER_SECRET =
      "YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXowMTIzNDU=";

  private final JwtUtil jwtUtil = new JwtUtil(SECRET);
  private final SecretKey secretKey = Keys.hmacShaKeyFor(
      Base64.getDecoder().decode(SECRET.getBytes(StandardCharsets.UTF_8)));

  @Test
  void generateTokenSetsSubjectRoleAndTimestamps() {
    String token = jwtUtil.generateToken("jane@example.com", "ADMIN");

    Claims claims = Jwts.parser().verifyWith(secretKey).build()
        .parseSignedClaims(token).getPayload();

    assertEquals("jane@example.com", claims.getSubject());
    assertEquals("ADMIN", claims.get("role", String.class));
    assertNotNull(claims.getIssuedAt());
    assertNotNull(claims.getExpiration());
    assertTrue(claims.getExpiration().after(claims.getIssuedAt()));
  }

  @Test
  void validateTokenAcceptsGeneratedToken() {
    String token = jwtUtil.generateToken("jane@example.com", "ADMIN");

    assertDoesNotThrow(() -> jwtUtil.validateToken(token));
  }

  @Test
  void validateTokenRejectsTokenSignedWithDifferentKey() {
    SecretKey otherKey = Keys.hmacShaKeyFor(
        Base64.getDecoder().decode(OTHER_SECRET.getBytes(StandardCharsets.UTF_8)));
    String token = Jwts.builder().subject("jane@example.com").signWith(otherKey)
        .compact();

    assertThrows(JwtException.class, () -> jwtUtil.validateToken(token));
  }

  @Test
  void validateTokenRejectsExpiredToken() {
    String token = Jwts.builder().subject("jane@example.com")
        .expiration(new Date(System.currentTimeMillis() - 1000))
        .signWith(secretKey).compact();

    assertThrows(JwtException.class, () -> jwtUtil.validateToken(token));
  }

  @Test
  void validateTokenRejectsMalformedToken() {
    assertThrows(JwtException.class,
        () -> jwtUtil.validateToken("not-a-valid-jwt"));
  }
}
