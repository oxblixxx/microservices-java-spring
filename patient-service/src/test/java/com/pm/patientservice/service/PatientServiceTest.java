package com.pm.patientservice.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.pm.patientservice.dto.PatientRequestDTO;
import com.pm.patientservice.dto.PatientResponseDTO;
import com.pm.patientservice.exception.EmailAlreadyExistsException;
import com.pm.patientservice.exception.PatientNotFoundException;
import com.pm.patientservice.grpc.BillingServiceGrpcClient;
import com.pm.patientservice.kafka.KafkaProducer;
import com.pm.patientservice.model.Patient;
import com.pm.patientservice.repository.PatientRepository;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class PatientServiceTest {

  @Mock
  private PatientRepository patientRepository;

  @Mock
  private BillingServiceGrpcClient billingServiceGrpcClient;

  @Mock
  private KafkaProducer kafkaProducer;

  @InjectMocks
  private PatientService patientService;

  @Test
  void getPatientsReturnsMappedPatients() {
    UUID id = UUID.randomUUID();
    Patient patient = patient(id, "Jane Doe", "jane@example.com",
        LocalDate.of(1990, 5, 20));

    when(patientRepository.findAll()).thenReturn(List.of(patient));

    List<PatientResponseDTO> result = patientService.getPatients();

    assertEquals(1, result.size());
    assertEquals(id.toString(), result.get(0).getId());
    assertEquals("Jane Doe", result.get(0).getName());
    assertEquals("jane@example.com", result.get(0).getEmail());
    assertEquals("1990-05-20", result.get(0).getDateOfBirth());
    verify(patientRepository).findAll();
  }

  @Test
  void getPatientsReturnsEmptyListWhenNoPatientsExist() {
    when(patientRepository.findAll()).thenReturn(List.of());

    List<PatientResponseDTO> result = patientService.getPatients();

    assertTrue(result.isEmpty());
    verify(patientRepository).findAll();
  }

  @Test
  void createPatientSavesAndNotifiesBillingAndKafka() {
    UUID id = UUID.randomUUID();
    PatientRequestDTO request = request("John Smith", "john@example.com",
        "123 Main St", "1985-03-10", "2024-01-15");
    Patient saved = patient(id, "John Smith", "john@example.com",
        LocalDate.of(1985, 3, 10));

    when(patientRepository.existsByEmail("john@example.com")).thenReturn(false);
    when(patientRepository.save(any(Patient.class))).thenReturn(saved);

    PatientResponseDTO result = patientService.createPatient(request);

    assertEquals(id.toString(), result.getId());
    assertEquals("John Smith", result.getName());
    assertEquals("john@example.com", result.getEmail());
    assertEquals("1985-03-10", result.getDateOfBirth());

    ArgumentCaptor<Patient> savedPatient = ArgumentCaptor.forClass(
        Patient.class);
    verify(patientRepository).save(savedPatient.capture());
    assertEquals("John Smith", savedPatient.getValue().getName());
    assertEquals("john@example.com", savedPatient.getValue().getEmail());
    assertEquals("123 Main St", savedPatient.getValue().getAddress());
    assertEquals(LocalDate.of(1985, 3, 10),
        savedPatient.getValue().getDateOfBirth());
    assertEquals(LocalDate.of(2024, 1, 15),
        savedPatient.getValue().getRegisteredDate());
    verify(billingServiceGrpcClient).createBillingAccount(id.toString(),
        "John Smith", "john@example.com");
    verify(kafkaProducer).sendEvent(saved);
  }

  @Test
  void createPatientThrowsWhenEmailAlreadyExists() {
    PatientRequestDTO request = request("John Smith", "john@example.com",
        "123 Main St", "1985-03-10", "2024-01-15");

    when(patientRepository.existsByEmail("john@example.com")).thenReturn(true);

    assertThrows(EmailAlreadyExistsException.class,
        () -> patientService.createPatient(request));

    verify(patientRepository, never()).save(any(Patient.class));
    verifyNoInteractions(billingServiceGrpcClient, kafkaProducer);
  }

  @Test
  void updatePatientAppliesChangesAndSaves() {
    UUID id = UUID.randomUUID();
    Patient existing = patient(id, "Old Name", "old@example.com",
        LocalDate.of(1980, 1, 1));
    PatientRequestDTO request = request("New Name", "new@example.com",
        "456 New St", "1985-03-10", "2024-01-15");

    when(patientRepository.findById(id)).thenReturn(Optional.of(existing));
    when(patientRepository.existsByEmailAndIdNot("new@example.com", id))
        .thenReturn(false);
    when(patientRepository.save(existing)).thenReturn(existing);

    PatientResponseDTO result = patientService.updatePatient(id, request);

    assertEquals(id.toString(), result.getId());
    assertEquals("New Name", result.getName());
    assertEquals("new@example.com", result.getEmail());
    assertEquals("456 New St", result.getAddress());
    assertEquals("1985-03-10", result.getDateOfBirth());
    assertEquals("New Name", existing.getName());
    assertEquals(LocalDate.of(1985, 3, 10), existing.getDateOfBirth());
    verify(patientRepository).save(existing);
  }

  @Test
  void updatePatientThrowsWhenPatientDoesNotExist() {
    UUID id = UUID.randomUUID();
    PatientRequestDTO request = request("New Name", "new@example.com",
        "456 New St", "1985-03-10", "2024-01-15");

    when(patientRepository.findById(id)).thenReturn(Optional.empty());

    assertThrows(PatientNotFoundException.class,
        () -> patientService.updatePatient(id, request));

    verify(patientRepository, never()).save(any(Patient.class));
    verifyNoInteractions(billingServiceGrpcClient, kafkaProducer);
  }

  @Test
  void updatePatientThrowsWhenEmailBelongsToAnotherPatient() {
    UUID id = UUID.randomUUID();
    Patient existing = patient(id, "Old Name", "old@example.com",
        LocalDate.of(1980, 1, 1));
    PatientRequestDTO request = request("New Name", "taken@example.com",
        "456 New St", "1985-03-10", "2024-01-15");

    when(patientRepository.findById(id)).thenReturn(Optional.of(existing));
    when(patientRepository.existsByEmailAndIdNot("taken@example.com", id))
        .thenReturn(true);

    assertThrows(EmailAlreadyExistsException.class,
        () -> patientService.updatePatient(id, request));

    assertEquals("Old Name", existing.getName());
    verify(patientRepository, never()).save(any(Patient.class));
  }

  @Test
  void deletePatientDeletesById() {
    UUID id = UUID.randomUUID();

    patientService.deletePatient(id);

    verify(patientRepository).deleteById(eq(id));
  }

  private static Patient patient(UUID id, String name, String email,
      LocalDate dateOfBirth) {
    Patient patient = new Patient();
    patient.setId(id);
    patient.setName(name);
    patient.setEmail(email);
    patient.setAddress("Some address");
    patient.setDateOfBirth(dateOfBirth);
    patient.setRegisteredDate(LocalDate.of(2024, 1, 15));
    return patient;
  }

  private static PatientRequestDTO request(String name, String email,
      String address, String dateOfBirth, String registeredDate) {
    PatientRequestDTO request = new PatientRequestDTO();
    request.setName(name);
    request.setEmail(email);
    request.setAddress(address);
    request.setDateOfBirth(dateOfBirth);
    request.setRegisteredDate(registeredDate);
    return request;
  }
}
