terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.60.0"
    }
  }
}

# When no explicit AMI is supplied the most recent matching Amazon Linux 2023
# image is resolved from SSM-published AMIs. An explicit ami_id avoids the
# data-source dependency and is preferred for fully pinned deployments.
data "aws_ami" "this" {
  count = var.ami_id == null ? 1 : 0

  most_recent = true
  owners      = var.ami_owners

  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }

  filter {
    name   = "architecture"
    values = [var.ami_architecture]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

locals {
  default_ami = var.ami_id != null ? var.ami_id : try(data.aws_ami.this[0].id, null)
}

resource "aws_instance" "this" {
  for_each = var.instances

  ami                         = coalesce(each.value.ami, local.default_ami)
  instance_type               = each.value.instance_type
  subnet_id                   = each.value.subnet_id
  vpc_security_group_ids      = each.value.security_group_ids
  iam_instance_profile        = each.value.iam_instance_profile
  key_name                    = each.value.key_name
  associate_public_ip_address = each.value.associate_public_ip_address
  user_data                   = each.value.user_data
  user_data_base64            = each.value.user_data_base64
  user_data_replace_on_change = each.value.user_data_replace_on_change
  monitoring                  = each.value.monitoring
  ebs_optimized               = each.value.ebs_optimized
  disable_api_termination     = each.value.disable_api_termination

  metadata_options {
    http_endpoint               = each.value.metadata_options.http_endpoint
    http_tokens                 = each.value.metadata_options.http_tokens
    http_put_response_hop_limit = each.value.metadata_options.http_put_response_hop_limit
    instance_metadata_tags      = each.value.metadata_options.instance_metadata_tags
  }

  root_block_device {
    volume_size           = each.value.root_volume.size
    volume_type           = each.value.root_volume.type
    iops                  = each.value.root_volume.iops
    throughput            = each.value.root_volume.throughput
    encrypted             = each.value.root_volume.encrypted
    kms_key_id            = each.value.root_volume.kms_key_id
    delete_on_termination = each.value.root_volume.delete_on_termination
  }

  tags = merge(var.tags, each.value.tags, { Name = coalesce(each.value.name, each.key) })

  # lifecycle {
  #   ignore_changes = [ami]
  # }
}
