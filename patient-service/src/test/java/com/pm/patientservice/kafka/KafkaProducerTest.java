package com.pm.patientservice.kafka;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.pm.patientservice.model.Patient;
import java.time.LocalDate;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.kafka.core.KafkaTemplate;
import patient.events.PatientEvent;

@ExtendWith(MockitoExtension.class)
class KafkaProducerTest {

  @Mock
  private KafkaTemplate<String, byte[]> kafkaTemplate;

  @InjectMocks
  private KafkaProducer kafkaProducer;

  @Test
  void sendEventPublishesPatientCreatedEventOnPatientTopic() throws Exception {
    UUID id = UUID.randomUUID();
    Patient patient = patient(id, "Jane Doe", "jane@example.com");

    kafkaProducer.sendEvent(patient);

    ArgumentCaptor<byte[]> payload = ArgumentCaptor.forClass(byte[].class);
    verify(kafkaTemplate).send(eq("patient"), payload.capture());

    PatientEvent event = PatientEvent.parseFrom(payload.getValue());
    assertEquals(id.toString(), event.getPatientId());
    assertEquals("Jane Doe", event.getName());
    assertEquals("jane@example.com", event.getEmail());
    assertEquals("PATIENT_CREATED", event.getEventType());
  }

  @Test
  void sendEventDoesNotPropagateKafkaFailures() {
    Patient patient = patient(UUID.randomUUID(), "Jane Doe",
        "jane@example.com");
    when(kafkaTemplate.send(eq("patient"), any(byte[].class)))
        .thenThrow(new RuntimeException("broker unavailable"));

    assertDoesNotThrow(() -> kafkaProducer.sendEvent(patient));
  }

  private static Patient patient(UUID id, String name, String email) {
    Patient patient = new Patient();
    patient.setId(id);
    patient.setName(name);
    patient.setEmail(email);
    patient.setAddress("Some address");
    patient.setDateOfBirth(LocalDate.of(1990, 5, 20));
    patient.setRegisteredDate(LocalDate.of(2024, 1, 15));
    return patient;
  }
}
