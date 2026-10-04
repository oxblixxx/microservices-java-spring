package com.pm.analyticsservice.kafka;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import java.util.List;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;
import patient.events.PatientEvent;

class KafkaConsumerTest {

  private final KafkaConsumer kafkaConsumer = new KafkaConsumer();

  private Logger logger;
  private ListAppender<ILoggingEvent> appender;

  @BeforeEach
  void attachAppender() {
    logger = (Logger) LoggerFactory.getLogger(KafkaConsumer.class);
    appender = new ListAppender<>();
    appender.start();
    logger.addAppender(appender);
  }

  @AfterEach
  void detachAppender() {
    logger.detachAppender(appender);
    appender.stop();
  }

  @Test
  void consumeEventLogsParsedPatientEvent() {
    PatientEvent event = PatientEvent.newBuilder()
        .setPatientId("patient-1")
        .setName("Jane Doe")
        .setEmail("jane@example.com")
        .setEventType("PATIENT_CREATED")
        .build();

    assertDoesNotThrow(() -> kafkaConsumer.consumeEvent(event.toByteArray()));

    List<ILoggingEvent> events = appender.list;
    assertEquals(1, events.size());
    assertEquals(Level.INFO, events.get(0).getLevel());
    String message = events.get(0).getFormattedMessage();
    assertTrue(message.contains("patient-1"));
    assertTrue(message.contains("Jane Doe"));
    assertTrue(message.contains("jane@example.com"));
  }

  @Test
  void consumeEventSwallowsInvalidProtobufPayload() {
    // 0x0F is a tag with invalid protobuf wire type 7, so parsing fails.
    byte[] invalidPayload = new byte[] {0x0F};

    assertDoesNotThrow(() -> kafkaConsumer.consumeEvent(invalidPayload));

    List<ILoggingEvent> events = appender.list;
    assertEquals(1, events.size());
    assertEquals(Level.ERROR, events.get(0).getLevel());
    assertTrue(events.get(0).getFormattedMessage()
        .startsWith("Error deserializing event"));
  }
}
