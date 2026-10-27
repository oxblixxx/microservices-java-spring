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
  # NAT gateways are only created when explicitly enabled and at least one
  # public subnet is available to host them. `per_az` controls whether every
  # public subnet receives a NAT gateway (AZ-resilient) or just the first one.
  gateway_count = (
    var.enabled && length(var.public_subnet_ids) > 0
    ? (var.per_az ? length(var.public_subnet_ids) : 1)
    : 0
  )
}

resource "aws_eip" "this" {
  count = local.gateway_count

  domain = "vpc"

  tags = merge(var.tags, { Name = "${var.name}-nat-eip-${count.index + 1}" })
}

resource "aws_nat_gateway" "this" {
  count = local.gateway_count

  allocation_id     = aws_eip.this[count.index].id
  subnet_id         = var.public_subnet_ids[count.index]
  connectivity_type = var.connectivity_type

  tags = merge(var.tags, { Name = "${var.name}-nat-${count.index + 1}" })

  depends_on = [aws_eip.this]
}
