terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.60.0"
    }
  }
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = var.vpc_id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index % length(var.azs)]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(var.tags, {
    Name = "${var.name}-public-${count.index + 1}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = var.vpc_id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index % length(var.azs)]

  # Application/private subnets never auto-assign public addresses.
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.name}-private-${count.index + 1}"
    Tier = "private"
  })
}

resource "aws_subnet" "management" {
  count = length(var.management_subnets)

  vpc_id            = var.vpc_id
  cidr_block        = var.management_subnets[count.index]
  availability_zone = var.azs[count.index % length(var.azs)]

  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(var.tags, {
    Name = "${var.name}-management-${count.index + 1}"
    Tier = "management"
  })
}
