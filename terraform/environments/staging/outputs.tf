# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------

output "vpc_id" {
  description = "Staging VPC ID."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "Staging VPC CIDR block."
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.subnets.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private (application) subnet IDs."
  value       = module.subnets.private_subnet_ids
}

output "management_subnet_ids" {
  description = "Management subnet IDs (may be empty)."
  value       = module.subnets.management_subnet_ids
}

# output "nat_gateway_ids" {
#   description = "NAT gateway IDs (empty when NAT is disabled)."
#   value       = module.nat.nat_gateway_ids
# }

output "vpc_endpoint_ids" {
  description = "Map of logical endpoint name to VPC endpoint ID."
  value       = module.vpc_endpoints.endpoint_ids
}

# ---------------------------------------------------------------------------
# Security groups
# ---------------------------------------------------------------------------

output "security_group_ids" {
  description = "Map of logical security group key to security group ID."
  value       = module.security_groups.security_group_ids
}

# ---------------------------------------------------------------------------
# EC2
# ---------------------------------------------------------------------------

output "ec2_instance_ids" {
  description = "Map of logical host key to EC2 instance ID."
  value       = module.ec2.instance_ids
}

output "ec2_private_ips" {
  description = "Map of logical host key to private IP address."
  value       = module.ec2.private_ips
}

output "ec2_availability_zones" {
  description = "Map of logical host key to availability zone."
  value       = module.ec2.availability_zones
}

# ---------------------------------------------------------------------------
# ECR
# ---------------------------------------------------------------------------

output "ecr_repository_urls" {
  description = "Map of logical service key to ECR repository URL."
  value       = module.ecr.repository_urls
}

output "ecr_repository_arns" {
  description = "Map of logical service key to ECR repository ARN."
  value       = module.ecr.repository_arns
}

output "application_images" {
  description = "Resolved image references supplied via var.application_images (empty when not provided). These are surfaced for the deployment layer and are never deployed by Terraform."
  value       = local.application_images
}

# ---------------------------------------------------------------------------
# IAM
# ---------------------------------------------------------------------------

output "ec2_ssm_role_arn" {
  description = "ARN of the shared EC2 SSM role."
  value       = module.iam.role_arns["ec2_ssm"]
}

output "ec2_ssm_instance_profile_name" {
  description = "Name of the EC2 instance profile."
  value       = module.iam.instance_profile_names["ec2_ssm"]
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions OIDC role, or null when disabled."
  value       = try(module.iam.role_arns["github_actions"], null)
}

# ---------------------------------------------------------------------------
# Secrets
# ---------------------------------------------------------------------------

# output "secret_arns" {
#   description = "Map of logical secret key to Secrets Manager ARN (no secret values are ever output)."
#   value       = module.secrets.secret_arns
# }

# ---------------------------------------------------------------------------
# Observability
# ---------------------------------------------------------------------------

# output "log_group_names" {
#   description = "Map of logical log group key to CloudWatch log group name."
#   value       = module.observability.log_group_names
# }

# output "vpc_flow_log_group_name" {
#   description = "CloudWatch log group name for VPC Flow Logs."
#   value       = module.vpc.flow_logs_log_group_name
# }

# output "otlp_endpoint" {
#   description = "Configured OTLP endpoint for the external SigNoz/OpenTelemetry collector."
#   value       = module.observability.otlp_endpoint
# }

# ---------------------------------------------------------------------------
# Twingate
# ---------------------------------------------------------------------------

output "twingate_enabled" {
  description = "Whether the Twingate private access layer is enabled."
  value       = var.twingate.enabled
}

output "twingate_connector_instance_ids" {
  description = "Twingate connector instance IDs (empty when disabled)."
  value       = var.twingate.enabled ? module.twingate[0].connector_instance_ids : []
}

output "twingate_connector_private_ips" {
  description = "Twingate connector private IP addresses (empty when disabled)."
  value       = var.twingate.enabled ? module.twingate[0].connector_private_ips : []
}

output "twingate_connector_security_group_id" {
  description = "Twingate connector security group ID (null when disabled)."
  value       = var.twingate.enabled ? module.twingate[0].connector_security_group_id : null
}
