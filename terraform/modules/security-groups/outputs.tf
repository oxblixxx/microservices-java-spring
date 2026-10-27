output "security_group_ids" {
  description = "Map of logical security group key to security group ID."
  value       = { for k, v in aws_security_group.this : k => v.id }
}

output "security_group_arns" {
  description = "Map of logical security group key to security group ARN."
  value       = { for k, v in aws_security_group.this : k => v.arn }
}

output "security_group_names" {
  description = "Map of logical security group key to security group name."
  value       = { for k, v in aws_security_group.this : k => v.name }
}

output "security_group_id_list" {
  description = "All security group IDs created by the module."
  value       = [for k, v in aws_security_group.this : v.id]
}
