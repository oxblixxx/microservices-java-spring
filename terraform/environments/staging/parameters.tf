# Non-secret configuration exposed to the deployment pipeline. Secret values
# live in Secrets Manager and are referenced by ARN only.
resource "aws_ssm_parameter" "image_repository" {
  for_each = module.ecr.repository_urls

  name        = "/${local.name_prefix}/images/${replace(each.key, "_", "-")}/repository"
  description = "ECR repository URL for the ${replace(each.key, "_", "-")} image"
  type        = "String"
  value       = each.value

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-image-repository-${each.key}" })
}

# Published only when an operator or pipeline supplies an explicit image
# reference (tag or immutable digest). Terraform never deploys these.
resource "aws_ssm_parameter" "image_reference" {
  for_each = { for k, v in local.application_images : k => v if v != "" }

  name        = "/${local.name_prefix}/images/${replace(each.key, "_", "-")}/reference"
  description = "Requested image reference (tag or digest) for ${replace(each.key, "_", "-")}"
  type        = "String"
  value       = each.value

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-image-reference-${each.key}" })
}

# resource "aws_ssm_parameter" "secret_arn" {
#   for_each = module.secrets.secret_arns

#   name        = "/${local.name_prefix}/secrets/${replace(each.key, "_", "-")}/arn"
#   description = "ARN of the ${replace(each.key, "_", "-")} secret"
#   type        = "String"
#   value       = each.value

#   tags = merge(local.common_tags, { Name = "${local.name_prefix}-secret-arn-${each.key}" })
# }

resource "aws_ssm_parameter" "platform_endpoints" {
  for_each = {
    postgresql = "5432"
    kafka      = "9092"
    otlp_grpc  = "4317"
    otlp_http  = "4318"
    signoz_ui  = "3301"
  }

  name        = "/${local.name_prefix}/platform/${replace(each.key, "_", "-")}/port"
  description = "Default port for the ${each.key} workload on the platform host"
  type        = "String"
  value       = each.value

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-platform-port-${each.key}" })
}
