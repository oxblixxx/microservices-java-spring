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
  policy_attachments = merge([
    for role_key, role in var.roles : {
      for arn in role.managed_policy_arns : "${role_key}~${arn}" => {
        role_key = role_key
        arn      = arn
      }
    }
  ]...)

  inline_policies = merge([
    for role_key, role in var.roles : {
      for policy_key, policy in role.inline_policies : "${role_key}~${policy_key}" => {
        role_key    = role_key
        policy_key  = policy_key
        description = policy.description
        policy      = policy.policy
      }
    }
  ]...)
}

resource "aws_iam_role" "this" {
  for_each = var.roles

  name                 = each.value.name
  description          = each.value.description != "" ? each.value.description : "Managed by Terraform (${each.key})"
  path                 = each.value.path
  assume_role_policy   = each.value.assume_role_policy
  permissions_boundary = each.value.permissions_boundary
  max_session_duration = each.value.max_session_duration

  tags = merge(var.tags, each.value.tags, { Name = each.value.name })
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = local.policy_attachments

  role       = aws_iam_role.this[each.value.role_key].name
  policy_arn = each.value.arn
}

resource "aws_iam_role_policy" "this" {
  for_each = local.inline_policies

  name   = each.value.policy_key
  role   = aws_iam_role.this[each.value.role_key].id
  policy = each.value.policy
}

resource "aws_iam_instance_profile" "this" {
  for_each = var.instance_profiles

  name = each.value.name
  path = each.value.path
  role = aws_iam_role.this[each.value.role_key].name

  tags = merge(var.tags, each.value.tags, { Name = each.value.name })
}
