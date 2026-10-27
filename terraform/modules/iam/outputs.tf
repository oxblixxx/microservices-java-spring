output "role_names" {
  description = "Map of logical role key to IAM role name."
  value       = { for k, v in aws_iam_role.this : k => v.name }
}

output "role_arns" {
  description = "Map of logical role key to IAM role ARN."
  value       = { for k, v in aws_iam_role.this : k => v.arn }
}

output "role_ids" {
  description = "Map of logical role key to IAM role ID."
  value       = { for k, v in aws_iam_role.this : k => v.unique_id }
}

output "instance_profile_names" {
  description = "Map of logical instance profile key to instance profile name."
  value       = { for k, v in aws_iam_instance_profile.this : k => v.name }
}

output "instance_profile_arns" {
  description = "Map of logical instance profile key to instance profile ARN."
  value       = { for k, v in aws_iam_instance_profile.this : k => v.arn }
}
