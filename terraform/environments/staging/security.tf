locals {
  twingate_connector_sg_ids = var.twingate.enabled ? [module.twingate[0].connector_security_group_id] : []

  # The Twingate connector is the trusted private-access layer. Resources accept
  # traffic only from the connector security group (never 0.0.0.0/0).
  twingate_ingress_microservices = [
    for sg_id in local.twingate_connector_sg_ids : {
      description              = "Private access from the Twingate connector"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = sg_id
    }
  ]

  twingate_ingress_platform = [
    for sg_id in local.twingate_connector_sg_ids : {
      description              = "Private access from the Twingate connector"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      source_security_group_id = sg_id
    }
  ]
}

module "security_groups" {
  source = "../../modules/security-groups"

  security_groups = {
    vpc_endpoints = {
      name        = "${local.name_prefix}-vpce"
      description = "Interface/Gateway VPC endpoint access"
      vpc_id      = module.vpc.vpc_id
      ingress = [
        {
          description               = "HTTPS from the microservices host"
          from_port                 = 443
          to_port                   = 443
          protocol                  = "tcp"
          source_security_group_key = "microservices"
        },
        {
          description               = "HTTPS from the platform host"
          from_port                 = 443
          to_port                   = 443
          protocol                  = "tcp"
          source_security_group_key = "platform"
        },
      ]
      egress = [
        {
          description = "Endpoint response traffic"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        },
      ]
    }

    microservices = {
      name        = "${local.name_prefix}-microservices"
      description = "Staging microservices runtime host"
      vpc_id      = module.vpc.vpc_id
      ingress = concat(
        [
          {
            description = "Intra-host service traffic"
            from_port   = 0
            to_port     = 0
            protocol    = "-1"
            self        = true
          },
          {
            description               = "Allow ping from platform host"
            from_port                 = 8
            to_port                   = 0
            protocol                  = "icmp"
            source_security_group_key = "platform"
          },
        ],
        local.twingate_ingress_microservices,
      )
      egress = [
        {
          description = "Outbound to platform host, AWS endpoints and (optionally) the Internet"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        },
      ]
    }

    platform = {
      name        = "${local.name_prefix}-platform"
      description = "Staging observability and messaging host"
      vpc_id      = module.vpc.vpc_id
      ingress = concat(
        [
          {
            description = "Intra-host platform traffic"
            from_port   = 0
            to_port     = 0
            protocol    = "-1"
            self        = true
          },
          {
            description               = "OpenTelemetry OTLP from microservices"
            from_port                 = 4317
            to_port                   = 4318
            protocol                  = "tcp"
            source_security_group_key = "microservices"
          },
          {
            description               = "Kafka from microservices"
            from_port                 = 9092
            to_port                   = 9092
            protocol                  = "tcp"
            source_security_group_key = "microservices"
          },
          {
            description               = "PostgreSQL from microservices"
            from_port                 = 5432
            to_port                   = 5432
            protocol                  = "tcp"
            source_security_group_key = "microservices"
          },
          {
            description               = "Allow ping from microservices host"
            from_port                 = 8
            to_port                   = 0
            protocol                  = "icmp"
            source_security_group_key = "microservices"
          },
        ],
        local.twingate_ingress_platform,
      )
      egress = [
        {
          description = "Outbound to microservices, AWS endpoints and (optionally) the Internet"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        },
      ]
    }
    management = {
      name        = "${local.name_prefix}-management"
      description = "Staging management host"
      vpc_id      = module.vpc.vpc_id
      ingress = concat(
        [
          {
            description = "Intra-host platform traffic"
            from_port   = 0
            to_port     = 0
            protocol    = "-1"
            self        = true
          },
          {
            description               = "OpenTelemetry OTLP from microservices"
            from_port                 = 4317
            to_port                   = 4318
            protocol                  = "tcp"
            source_security_group_key = "microservices"
          },
          {
            description               = "Kafka from microservices"
            from_port                 = 9092
            to_port                   = 9092
            protocol                  = "tcp"
            source_security_group_key = "microservices"
          },
          {
            description               = "PostgreSQL from microservices"
            from_port                 = 5432
            to_port                   = 5432
            protocol                  = "tcp"
            source_security_group_key = "microservices"
          },
          {
            description               = "Allow ping from microservices host"
            from_port                 = 8
            to_port                   = 0
            protocol                  = "icmp"
            source_security_group_key = "microservices"
          },
        ],
        local.twingate_ingress_platform,
      )
      egress = [
        {
          description = "Outbound to microservices, AWS endpoints and (optionally) the Internet"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        },
      ]
    }

  }

  tags = local.common_tags
}
