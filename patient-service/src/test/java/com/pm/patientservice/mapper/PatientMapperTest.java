package com.pm.patientservice.mapper;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

import com.pm.patientservice.dto.PatientRequestDTO;
import com.pm.patientservice.dto.PatientResponseDTO;
import com.pm.patientservice.model.Patient;
import java.time.LocalDate;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class PatientMapperTest {

  @Test
  void toDTOMapsAllPatientFields() {
    UUID id = UUID.randomUUID();
    Patient patient = new Patient();
    patient.setId(id);
    patient.setName("Jane Doe");
    patient.setAddress("123 Main St");
    patient.setEmail("jane@example.com");
    patient.setDateOfBirth(LocalDate.of(1990, 5, 20));

    PatientResponseDTO dto = PatientMapper.toDTO(patient);

    assertEquals(id.toString(), dto.getId());
    assertEquals("Jane Doe", dto.getName());
    assertEquals("123 Main St", dto.getAddress());
    assertEquals("jane@example.com", dto.getEmail());
    assertEquals("1990-05-20", dto.getDateOfBirth());
  }

  @Test
  void toModelMapsFieldsAndParsesDates() {
    PatientRequestDTO request = new PatientRequestDTO();
    request.setName("John Smith");
    request.setAddress("456 New St");
    request.setEmail("john@example.com");
    request.setDateOfBirth("1985-03-10");
    request.setRegisteredDate("2024-01-15");

    Patient patient = PatientMapper.toModel(request);

    assertNull(patient.getId());
    assertEquals("John Smith", patient.getName());
    assertEquals("456 New St", patient.getAddress());
    assertEquals("john@example.com", patient.getEmail());
    assertEquals(LocalDate.of(1985, 3, 10), patient.getDateOfBirth());
    assertEquals(LocalDate.of(2024, 1, 15), patient.getRegisteredDate());
  }
}
