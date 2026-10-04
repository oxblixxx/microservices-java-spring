package com.pm.patientservice.exception;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;

class GlobalExceptionHandlerTest {

  private final GlobalExceptionHandler handler = new GlobalExceptionHandler();

  @Test
  void handleEmailAlreadyExistsExceptionReturnsBadRequestMessage() {
    ResponseEntity<Map<String, String>> response =
        handler.handleEmailAlreadyExistsException(
            new EmailAlreadyExistsException("duplicate"));

    assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
    assertEquals(Map.of("message", "Email address already exists"),
        response.getBody());
  }

  @Test
  void handlePatientNotFoundExceptionReturnsBadRequestMessage() {
    ResponseEntity<Map<String, String>> response =
        handler.handlePatientNotFoundException(
            new PatientNotFoundException("missing"));

    assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
    assertEquals(Map.of("message", "Patient not found"), response.getBody());
  }

  @Test
  void handleValidationExceptionReturnsFieldErrors() {
    BindingResult bindingResult = mock(BindingResult.class);
    FieldError fieldError = mock(FieldError.class);
    when(bindingResult.getObjectName()).thenReturn("patientRequestDTO");
    when(bindingResult.getFieldErrors()).thenReturn(List.of(fieldError));
    when(fieldError.getField()).thenReturn("email");
    when(fieldError.getDefaultMessage()).thenReturn("Email is required");
    MethodArgumentNotValidException ex =
        new MethodArgumentNotValidException(null, bindingResult);

    ResponseEntity<Map<String, String>> response =
        handler.handleValidationException(ex);

    assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
    assertEquals(Map.of("email", "Email is required"), response.getBody());
  }
}
