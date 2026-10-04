package com.pm.billingservice.grpc;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import billing.BillingRequest;
import billing.BillingResponse;
import io.grpc.stub.StreamObserver;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class BillingGrpcServiceTest {

  @Mock
  private StreamObserver<BillingResponse> responseObserver;

  private final BillingGrpcService billingGrpcService = new BillingGrpcService();

  @Test
  void createBillingAccountReturnsActiveAccount() {
    BillingRequest request = request();

    billingGrpcService.createBillingAccount(request, responseObserver);

    ArgumentCaptor<BillingResponse> responseCaptor = ArgumentCaptor.forClass(
        BillingResponse.class);
    verify(responseObserver).onNext(responseCaptor.capture());
    assertEquals("12345", responseCaptor.getValue().getAccountId());
    assertEquals("ACTIVE", responseCaptor.getValue().getStatus());
  }

  @Test
  void createBillingAccountCompletesStreamWithoutError() {
    billingGrpcService.createBillingAccount(request(), responseObserver);

    verify(responseObserver).onCompleted();
    verify(responseObserver, never()).onError(any());
  }

  private static BillingRequest request() {
    return BillingRequest.newBuilder()
        .setPatientId("patient-1")
        .setName("Jane Doe")
        .setEmail("jane@example.com")
        .build();
  }
}
