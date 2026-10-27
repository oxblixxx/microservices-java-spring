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
  # Rules are flattened into a single map so that each rule becomes an
  # individual aws_security_group_rule. Independent rule resources avoid the
  # dependency cycles that inline ingress/egress blocks can create when two
  # security groups reference each other.
  ingress_rules = merge([
    for key, sg in var.security_groups : {
      for idx, rule in sg.ingress : "${key}~ingress~${idx}" => {
        sg_key           = key
        direction        = "ingress"
        description      = rule.description
        from_port        = rule.from_port
        to_port          = rule.to_port
        protocol         = rule.protocol
        cidr_blocks      = rule.cidr_blocks
        ipv6_cidr_blocks = rule.ipv6_cidr_blocks
        prefix_list_ids  = rule.prefix_list_ids
        self             = rule.self
        ref_key          = rule.source_security_group_key
        ref_id           = rule.source_security_group_id
      }
    }
  ]...)

  egress_rules = merge([
    for key, sg in var.security_groups : {
      for idx, rule in sg.egress : "${key}~egress~${idx}" => {
        sg_key           = key
        direction        = "egress"
        description      = rule.description
        from_port        = rule.from_port
        to_port          = rule.to_port
        protocol         = rule.protocol
        cidr_blocks      = rule.cidr_blocks
        ipv6_cidr_blocks = rule.ipv6_cidr_blocks
        prefix_list_ids  = rule.prefix_list_ids
        self             = rule.self
        ref_key          = rule.destination_security_group_key
        ref_id           = rule.destination_security_group_id
      }
    }
  ]...)

  rules = merge(local.ingress_rules, local.egress_rules)

  rule_ref_sg_id = {
    for k, r in local.rules : k => (
      r.ref_key != null
      ? aws_security_group.this[r.ref_key].id
      : (r.ref_id != null ? r.ref_id : null)
    )
  }

  rule_has_sg = { for k, v in local.rule_ref_sg_id : k => v != null }
}

resource "aws_security_group" "this" {
  for_each = var.security_groups

  name        = each.value.name
  description = each.value.description != "" ? each.value.description : "Managed by Terraform (${each.key})"
  vpc_id      = each.value.vpc_id

  tags = merge(var.tags, each.value.tags, { Name = each.value.name })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "this" {
  for_each = local.rules

  type              = each.value.direction
  security_group_id = aws_security_group.this[each.value.sg_key].id
  description       = each.value.description != "" ? each.value.description : null
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  # `self` must be omitted (null) unless enabled: the provider declares it
  # ConflictsWith cidr_blocks/ipv6_cidr_blocks/source_security_group_id, and an
  # explicit `self = false` still triggers that conflict.
  self = each.value.self ? true : null

  cidr_blocks = local.rule_has_sg[each.key] || length(each.value.cidr_blocks) == 0 ? null : each.value.cidr_blocks

  ipv6_cidr_blocks = local.rule_has_sg[each.key] || length(each.value.ipv6_cidr_blocks) == 0 ? null : each.value.ipv6_cidr_blocks

  prefix_list_ids = length(each.value.prefix_list_ids) == 0 ? null : each.value.prefix_list_ids

  source_security_group_id = local.rule_ref_sg_id[each.key]
}
