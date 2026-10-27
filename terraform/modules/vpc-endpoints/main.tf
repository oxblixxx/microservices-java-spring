terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.60.0"
    }
  }
}

locals {
  # Short logical names mapped to their AWS service DNS suffix. Custom
  # endpoints can be supplied with a fully qualified service name.
  service_map = {
    ecr_api              = "ecr.api"
    ecr_dkr              = "ecr.dkr"
    s3                   = "s3"
    dynamodb             = "dynamodb"
    ssm                  = "ssm"
    ssmmessages          = "ssmmessages"
    ec2messages          = "ec2messages"
    logs                 = "logs"
    secretsmanager       = "secretsmanager"
    kms                  = "kms"
    sts                  = "sts"
    ecs                  = "ecs"
    ecs_agent            = "ecs-agent"
    ecs_telemetry        = "ecs-telemetry"
    monitoring           = "monitoring"
    kinesis_firehose     = "kinesis-firehose"
    elasticloadbalancing = "elasticloadbalancing"
    autoscaling          = "autoscaling"
  }

  interface_endpoints = {
    for k in toset(var.interface_services) : k => {
      service_name        = "com.amazonaws.${var.region}.${lookup(local.service_map, k, k)}"
      vpc_endpoint_type   = "Interface"
      private_dns_enabled = true
      subnet_ids          = var.subnet_ids
      security_group_ids  = var.security_group_ids
      route_table_ids     = null
      policy              = null
    }
  }

  gateway_endpoints = {
    for k in toset(var.gateway_services) : k => {
      service_name        = "com.amazonaws.${var.region}.${lookup(local.service_map, k, k)}"
      vpc_endpoint_type   = "Gateway"
      private_dns_enabled = null
      subnet_ids          = null
      security_group_ids  = null
      route_table_ids     = var.route_table_ids
      policy              = null
    }
  }

  custom = {
    for k, v in var.custom_endpoints : k => {
      service_name        = v.service_name
      vpc_endpoint_type   = v.vpc_endpoint_type
      private_dns_enabled = v.vpc_endpoint_type == "Interface" ? v.private_dns_enabled : null
      subnet_ids          = v.vpc_endpoint_type == "Interface" ? var.subnet_ids : null
      security_group_ids  = v.vpc_endpoint_type == "Interface" ? var.security_group_ids : null
      route_table_ids     = v.vpc_endpoint_type == "Gateway" ? var.route_table_ids : null
      policy              = v.policy
    }
  }

  endpoints = merge(local.interface_endpoints, local.gateway_endpoints, local.custom)
}

resource "aws_vpc_endpoint" "this" {
  for_each = local.endpoints

  vpc_id              = var.vpc_id
  service_name        = each.value.service_name
  vpc_endpoint_type   = each.value.vpc_endpoint_type
  private_dns_enabled = each.value.private_dns_enabled
  subnet_ids          = each.value.subnet_ids
  security_group_ids  = each.value.security_group_ids
  route_table_ids     = each.value.route_table_ids
  policy              = each.value.policy
  auto_accept         = true

  tags = merge(var.tags, {
    Name = "${var.name}-${each.key}"
  })
}
