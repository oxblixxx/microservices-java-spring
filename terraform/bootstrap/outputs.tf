output "state_bucket_names" {
  description = "Map of environment key to Terraform state bucket name."
  value       = { for k, v in aws_s3_bucket.state : k => v.bucket }
}

output "state_bucket_arns" {
  description = "Map of environment key to Terraform state bucket ARN."
  value       = { for k, v in aws_s3_bucket.state : k => v.arn }
}

output "state_kms_key_arn" {
  description = "ARN of the state encryption KMS key, if created."
  value       = try(aws_kms_key.state[0].arn, null)
}

output "state_kms_alias" {
  description = "Alias of the state encryption KMS key, if created."
  value       = try(aws_kms_alias.state[0].name, null)
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider, if created."
  value       = try(aws_iam_openid_connect_provider.github[0].arn, null)
}

output "account_id" {
  description = "AWS account ID where bootstrap resources were created."
  value       = data.aws_caller_identity.current.account_id
}

output "region" {
  description = "AWS region used for bootstrap resources."
  value       = var.region
}
