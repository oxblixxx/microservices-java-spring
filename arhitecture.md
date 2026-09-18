                           CLIENT
                              │
                              │ HTTP
                              ▼
                    ┌───────────────────┐
                    │   API Gateway     │
                    │      :4004        │
                    └─────────┬─────────┘
                              │
                    ┌─────────┴──────────┐
                    │                    │
                 /auth/**          /api/patients/**
                    │                    │
                    ▼                    ▼
             ┌────────────┐       ┌───────────────┐
             │ Auth       │       │ Patient       │
             │ Service    │       │ Service       │
             │ :4005      │       │ :4000         │
             └────────────┘       └───────┬───────┘
                                          │
                              ┌───────────┴───────────┐
                              │                       │
                             gRPC                   Kafka
                              │                       │
                              ▼                       ▼
                       ┌──────────────┐       ┌─────────────┐
                       │ Billing      │       │ Kafka       │
                       │ Service      │       │ topic       │
                       │ gRPC         │       │ "patient"   │
                       └──────────────┘       └──────┬──────┘
                                                     │
                                                     ▼
                                              ┌─────────────┐
                                              │ Analytics   │
                                              │ Service     │
                                              └─────────────┘






                           Internet
                              │
                              ▼
                    ┌──────────────────┐
                    │       ALB        │
                    └────────┬─────────┘
                             │
                             ▼
                    API Gateway :4004
                             │
                   ┌─────────┴─────────┐
                   │                   │
                   ▼                   ▼
             Auth Service        Patient Service
                :4005                 :4000
                   │                    │
                   ▼                    ├──── gRPC ────► Billing
            RDS PostgreSQL             │                  :9001
           auth-service-db             │
                                        │
                                        ▼
                                    Amazon MSK
                                   topic: patient
                                        │
                                        ▼
                                  Analytics Service



NETWORK
├── VPC
└── 2 AZs

COMPUTE
├── API Gateway service
├── Auth service
├── Patient service
├── Billing service
└── Analytics service

DATABASE
├── RDS PostgreSQL → Auth
└── RDS PostgreSQL → Patient

MESSAGING
└── MSK Kafka
    └── topic: patient

LOAD BALANCING
└── ALB → API Gateway

SERVICE DISCOVERY
└── Cloud Map

LOGGING
└── CloudWatch Logs