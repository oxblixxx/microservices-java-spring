output "repository_urls" {
  description = "Map of logical repository key to its ECR repository URL."
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}

output "repository_arns" {
  description = "Map of logical repository key to its ECR repository ARN."
  value       = { for k, v in aws_ecr_repository.this : k => v.arn }
}

output "repository_names" {
  description = "Map of logical repository key to its ECR repository name."
  value       = { for k, v in aws_ecr_repository.this : k => v.name }
}

output "repository_registry_ids" {
  description = "Map of logical repository key to its registry ID (AWS account ID)."
  value       = { for k, v in aws_ecr_repository.this : k => v.registry_id }
}
