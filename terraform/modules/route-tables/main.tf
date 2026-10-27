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
  create_public = var.create_public_route_table && length(var.public_subnet_ids) > 0
  # Whether an IGW exists is a resource attribute (unknown until apply), so it
  # must not gate cardinality. Only this planning-known decision controls
  # `count`; the route target below stays a resource reference.
  public_default_igw = var.public_default_route == "igw"
  private_nat_egress = var.private_default_route == "nat" && length(var.nat_gateway_ids) > 0
  create_management  = length(var.management_subnet_ids) > 0
  management_igw     = var.management_default_route == "igw"
  management_nat     = var.management_default_route == "nat" && length(var.nat_gateway_ids) > 0
}

# ---------------------------------------------------------------------------
# Public route table
# ---------------------------------------------------------------------------

resource "aws_route_table" "public" {
  count = local.create_public ? 1 : 0

  vpc_id = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-public" })
}

resource "aws_route" "public_default" {
  count = local.create_public && local.public_default_igw ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.internet_gateway_id
}

resource "aws_route_table_association" "public" {
  count = local.create_public ? length(var.public_subnet_ids) : 0

  subnet_id      = var.public_subnet_ids[count.index]
  route_table_id = aws_route_table.public[0].id
}

# ---------------------------------------------------------------------------
# Private route tables (one per private subnet so each subnet can egress via
# its own NAT gateway when NAT is enabled).
# ---------------------------------------------------------------------------

resource "aws_route_table" "private" {
  count = length(var.private_subnet_ids)

  vpc_id = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-private-${count.index + 1}" })
}

resource "aws_route" "private_default" {
  count = local.private_nat_egress ? length(var.private_subnet_ids) : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.nat_gateway_ids[count.index % length(var.nat_gateway_ids)]
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_ids)

  subnet_id      = var.private_subnet_ids[count.index]
  route_table_id = aws_route_table.private[count.index].id
}

# ---------------------------------------------------------------------------
# Optional management route table
# ---------------------------------------------------------------------------

resource "aws_route_table" "management" {
  count = local.create_management ? 1 : 0

  vpc_id = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-management" })
}

resource "aws_route" "management_default" {
  count = (local.management_igw || local.management_nat) ? 1 : 0

  route_table_id         = aws_route_table.management[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = local.management_igw ? var.internet_gateway_id : null
  nat_gateway_id         = local.management_nat ? var.nat_gateway_ids[0] : null
}

resource "aws_route_table_association" "management" {
  count = local.create_management ? length(var.management_subnet_ids) : 0

  subnet_id      = var.management_subnet_ids[count.index]
  route_table_id = aws_route_table.management[0].id
}
